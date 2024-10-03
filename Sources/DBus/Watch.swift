import CDBus
import Dispatch
import Foundation

/// A wrapper for `DBusWatch`.
public struct Watch: Hashable {
  /// The raw pointer to `DBusWatch`.
  let raw: OpaquePointer

  /// Initializes a new `Watch` with the given raw pointer.
  ///
  /// - Parameter raw: The raw pointer to `DBusWatch`.
  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  /// The file descriptor associated with the watch.
  public var fileDescriptor: Int32 {
    dbus_watch_get_unix_fd(raw)
  }

  /// The socket associated with the watch.
  public var socket: Int32 {
    dbus_watch_get_socket(raw)
  }

  /// The flags indicating
  /// what conditions should be monitored on the
  /// file descriptor.
  public var flags: WatchFlags {
    WatchFlags(rawValue: dbus_watch_get_flags(raw))
  }

  /// Indicates whether the watch is enabled.
  public var isEnabled: Bool {
    dbus_watch_get_enabled(raw) != 0
  }

  /// Handles the watch with the given flags.
  ///
  /// - Parameter flags: The flags to handle.
  /// - Throws: `DBus.Error` if handling the watch fails.
  public func handle(_ flags: WatchFlags) throws(DBus.Error) {
    guard dbus_watch_handle(raw, flags.rawValue) != 0 else {
      throw .init(name: .noMemory, message: "Failed to handle watch")
    }
  }
}

/// Indicates the status of a `Watch`.
public struct WatchFlags: OptionSet, Sendable {
  public let rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }

  /// As in POLLIN.
  public static let readable = Self(rawValue: 1 << 0)
  /// As in POLLOUT.
  public static let writable = Self(rawValue: 1 << 1)
  /// As in POLLERR.
  public static let error = Self(rawValue: 1 << 2)
  /// As in POLLHUP.
  public static let hangup = Self(rawValue: 1 << 3)
}

extension WatchFlags {
  /// Initializes a new `WatchFlags` from `CFOptionFlags`.
  ///
  /// - Parameter cfFlags: The `CFOptionFlags` to convert.
  init(cfFlags: CFOptionFlags) {
    self.init()
    if cfFlags & kCFFileDescriptorReadCallBack != 0 {
      insert(.readable)
    }
    if cfFlags & kCFFileDescriptorWriteCallBack != 0 {
      insert(.writable)
    }
  }
}

extension CFOptionFlags {
  /// Initializes a new `CFOptionFlags` from `WatchFlags`.
  ///
  /// - Parameter watchFlags: The `WatchFlags` to convert.
  init(watchFlags: WatchFlags) {
    self = 0
    if watchFlags.contains(.readable) {
      self |= kCFFileDescriptorReadCallBack
    }
    if watchFlags.contains(.writable) {
      self |= kCFFileDescriptorWriteCallBack
    }
  }
}

/// A protocol for handling watches.
public protocol WatchDelegate: AnyObject {
  /// Adds a watch.
  ///
  /// - Parameter watch: The watch to add.
  /// - Returns: `true` if the watch was added successfully, `false` otherwise.
  func add(watch: Watch) -> Bool

  /// Removes a watch.
  ///
  /// - Parameter watch: The watch to remove.
  func remove(watch: Watch)

  /// Called when a watch is toggled.
  ///
  /// - Parameter watch: The toggled watch.
  func onToggled(watch: Watch)
}

private typealias Dispose = () -> Void

/// A class that handles watches using `RunLoop`.
public class RunLoopWatcher: WatchDelegate {
  /// The run loop used to handle watches.
  private let runLoop: CFRunLoop
  /// The dispatcher function to call when a watch is handled.
  private let dispatcher: () -> Void
  /// A dictionary mapping watches to dispose functions.
  private var watches: [Watch: Dispose] = [:]

  /// Initializes a new `RunLoopWatcher` with the given run loop and dispatcher.
  ///
  /// - Parameters:
  ///   - runLoop: The run loop to use for handling watches.
  ///   - dispatcher: The dispatcher function to call when a watch is handled.
  public init(runLoop: RunLoop, dispatcher: @escaping () -> Void) {
    self.runLoop = runLoop.getCFRunLoop()
    self.dispatcher = dispatcher
  }

  /// Adds a watch to the run loop.
  ///
  /// - Parameter watch: The watch to add.
  /// - Returns: `true` if the watch was added successfully, `false` otherwise.
  public func add(watch: Watch) -> Bool {
    let handleWatch = { (flags: WatchFlags) in
      do {
        try watch.handle(flags)
      } catch {
        perror("[dbus] RunLoopWatcher: \(error)")
      }
      self.dispatcher()  // call the dispatcher even if the watch handle failed
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
      (handleWatch as! (WatchFlags) -> Void)(WatchFlags(cfFlags: flags))
      CFFileDescriptorEnableCallBacks(fd, flags)  // callback is one-shot, re-enable
    }
    let fd = CFFileDescriptorCreate(
      kCFAllocatorDefault, watch.fileDescriptor, false, callback, &context)
    CFFileDescriptorEnableCallBacks(fd, CFOptionFlags(watchFlags: watch.flags))
    let source = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, fd, 0)
    CFRunLoopAddSource(runLoop, source, .defaultMode)
    watches[watch] = {
      CFRunLoopRemoveSource(self.runLoop, source, .defaultMode)
      CFFileDescriptorInvalidate(fd)
    }
    return true
  }

  /// Removes a watch from the run loop.
  ///
  /// - Parameter watch: The watch to remove.
  public func remove(watch: Watch) {
    watches.removeValue(forKey: watch)?()
  }

  /// Called when a watch is toggled.
  ///
  /// - Parameter watch: The toggled watch.
  public func onToggled(watch: Watch) {
    if watch.isEnabled {
      _ = add(watch: watch)
    } else {
      remove(watch: watch)
    }
  }
}

/// A class that handles watches using `DispatchQueue`.
public class DispatchQueueWatcher: WatchDelegate {
  /// The dispatch queue used to handle watches.
  private let queue: DispatchQueue
  /// The dispatcher function to call when a watch is handled.
  private let dispatcher: () -> Void
  /// A dictionary mapping watches to dispose functions.
  private var watches: [Watch: Dispose] = [:]

  /// Initializes a new `DispatchQueueWatcher` with the given dispatch queue and dispatcher.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue to use for handling watches.
  ///   - dispatcher: The dispatcher function to call when a watch is handled.
  public init(queue: DispatchQueue, dispatcher: @escaping () -> Void) {
    self.queue = queue
    self.dispatcher = dispatcher
  }

  /// Adds a watch to the dispatch queue.
  ///
  /// - Parameter watch: The watch to add.
  /// - Returns: `true` if the watch was added successfully, `false` otherwise.
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

  /// Removes a watch from the dispatch queue.
  ///
  /// - Parameter watch: The watch to remove.
  public func remove(watch: Watch) {
    watches.removeValue(forKey: watch)?()
  }

  /// Called when a watch is toggled.
  ///
  /// - Parameter watch: The toggled watch.
  public func onToggled(watch: Watch) {
    if watch.isEnabled {
      _ = add(watch: watch)
    } else {
      remove(watch: watch)
    }
  }
}
