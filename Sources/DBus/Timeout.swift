import CDBus

public struct TimeoutInterval: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  @available(macOS 13.0, *)
  public init(_ duration: Duration) {
    let (seconds, attoseconds) = duration.components
    rawValue = Int32(seconds * 1000 + attoseconds / 1_000_000_000_000_000)
  }
}

extension TimeoutInterval {
  public static let useDefault = Self(rawValue: DBUS_TIMEOUT_USE_DEFAULT)
  public static let infinite = Self(rawValue: DBUS_TIMEOUT_INFINITE)

  public static func milliseconds(_ milliseconds: Int32) -> Self {
    .init(rawValue: milliseconds)
  }

  public static func seconds(_ seconds: Int32) -> Self {
    .init(rawValue: seconds * 1000)
  }

  public static func minutes(_ minutes: Int32) -> Self {
    .init(rawValue: minutes * 60 * 1000)
  }
}

public struct Timeout {
  let raw: OpaquePointer

  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  public var interval: TimeoutInterval {
    .init(rawValue: dbus_timeout_get_interval(raw))
  }

  public var isEnabled: Bool {
    dbus_timeout_get_enabled(raw) != 0
  }

  public func handle() {
    dbus_timeout_handle(raw)
  }
}

public protocol TimeoutDelegate {
  func add(timeout: Timeout) -> Bool
  func remove(timeout: Timeout)
  func onToggled(timeout: Timeout)
}
