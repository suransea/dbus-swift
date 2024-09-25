import CDBus

public struct Watch {
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

  public func handle(_ flags: WatchFlags) {
    dbus_watch_handle(raw, flags.rawValue)
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

public protocol WatchDelegate {
  func add(watch: Watch) -> Bool
  func remove(watch: Watch)
  func onToggled(watch: Watch)
}
