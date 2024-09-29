import CDBus
import Dispatch
import Foundation

public struct Watch: Hashable {
  let raw: OpaquePointer

  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  public var fileDescriptor: Int32 {
    dbus_watch_get_unix_fd(raw)
  }

  public var socket: Int32 {
    dbus_watch_get_socket(raw)
  }

  public var flags: WatchFlags {
    WatchFlags(rawValue: dbus_watch_get_flags(raw))
  }

  public var isEnabled: Bool {
    dbus_watch_get_enabled(raw) != 0
  }

  public func handle(_ flags: WatchFlags) throws(DBus.Error) {
    guard dbus_watch_handle(raw, flags.rawValue) != 0 else {
      throw .init(name: .noMemory, message: "Failed to handle watch")
    }
  }
}

public struct WatchFlags: OptionSet, Sendable {
  public let rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }

  static let readable = WatchFlags(rawValue: 1 << 0)
  static let writable = WatchFlags(rawValue: 1 << 1)
  static let error = WatchFlags(rawValue: 1 << 2)
  static let hangup = WatchFlags(rawValue: 1 << 3)
}

public protocol WatchDelegate: AnyObject {
  func add(watch: Watch) -> Bool
  func remove(watch: Watch)
  func onToggled(watch: Watch)
}

private typealias Dispose = () -> Void

public class RunLoopWatcher: WatchDelegate {
  private let runLoop: CFRunLoop
  private let dispatcher: () -> Void
  private var watches: [Watch: Dispose] = [:]

  public init(runLoop: RunLoop, dispatcher: @escaping () -> Void) {
    self.runLoop = runLoop.getCFRunLoop()
    self.dispatcher = dispatcher
  }

  public func add(watch: Watch) -> Bool {
    let handleWatch = { (flags: WatchFlags) in
      do {
        try watch.handle(flags)
      } catch {
        perror("[dbus] RunLoopWatcher: \(error)")
      }
      self.dispatcher()  // call the dispatcher even if the watch failed
    }
    let userInfo = Unmanaged.passRetained(handleWatch as AnyObject).toOpaque()
    var context = CFFileDescriptorContext(
      version: 0, info: userInfo,
      retain: { info in
        Unmanaged<AnyObject>.fromOpaque(info!).retain().toOpaque()
      },
      release: { info in
        Unmanaged<AnyObject>.fromOpaque(info!).release()
      },
      copyDescription: nil)
    let callback: CFFileDescriptorCallBack = { fd, flags, info in
      let handleWatch = Unmanaged<AnyObject>.fromOpaque(info!).takeUnretainedValue()
      var watchFlags = WatchFlags()
      if flags & kCFFileDescriptorReadCallBack != 0 {
        watchFlags.insert(.readable)
      }
      if flags & kCFFileDescriptorWriteCallBack != 0 {
        watchFlags.insert(.writable)
      }
      (handleWatch as! (WatchFlags) -> Void)(watchFlags)
    }
    let fd = CFFileDescriptorCreate(
      kCFAllocatorDefault, watch.fileDescriptor, false, callback, &context)
    var cfFlags = CFOptionFlags()
    if watch.flags.contains(.readable) {
      cfFlags |= kCFFileDescriptorReadCallBack
    }
    if watch.flags.contains(.writable) {
      cfFlags |= kCFFileDescriptorWriteCallBack
    }
    CFFileDescriptorEnableCallBacks(fd, cfFlags)
    let source = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, fd, 0)
    CFRunLoopAddSource(runLoop, source, .defaultMode)
    watches[watch] = {
      CFRunLoopRemoveSource(self.runLoop, source, .defaultMode)
      CFFileDescriptorInvalidate(fd)
    }
    return true
  }

  public func remove(watch: Watch) {
    watches.removeValue(forKey: watch)?()
  }

  public func onToggled(watch: Watch) {
    if watch.isEnabled {
      _ = add(watch: watch)
    } else {
      remove(watch: watch)
    }
  }
}

public class DispatchQueueWatcher: WatchDelegate {
  private let queue: DispatchQueue
  private let dispatcher: () -> Void
  private var watches: [Watch: Dispose] = [:]

  public init(queue: DispatchQueue, dispatcher: @escaping () -> Void) {
    self.queue = queue
    self.dispatcher = dispatcher
  }

  public func add(watch: Watch) -> Bool {
    var source: (read: DispatchSourceRead?, write: DispatchSourceWrite?) = (nil, nil)
    if watch.flags.contains(.readable) {
      let read = DispatchSource.makeReadSource(
        fileDescriptor: watch.fileDescriptor, queue: queue)
      read.setEventHandler {
        do {
          try watch.handle(.readable)
        } catch {
          perror("[dbus] DispatchQueueWatcher: \(error)")
        }
        self.dispatcher()
      }
      read.activate()
      source.read = read
    }
    if watch.flags.contains(.writable) {
      let write = DispatchSource.makeWriteSource(
        fileDescriptor: watch.fileDescriptor, queue: queue)
      write.setEventHandler {
        do {
          try watch.handle(.writable)
        } catch {
          perror("[dbus] DispatchQueueWatcher: \(error)")
        }
        self.dispatcher()
      }
      write.activate()
      source.write = write
    }
    watches[watch] = {
      source.read?.cancel()
      source.write?.cancel()
    }
    return true
  }

  public func remove(watch: Watch) {
    watches.removeValue(forKey: watch)?()
  }

  public func onToggled(watch: Watch) {
    if watch.isEnabled {
      _ = add(watch: watch)
    } else {
      remove(watch: watch)
    }
  }
}
