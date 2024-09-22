import CDBus

public enum BusType: UInt32 {
  case session
  case system
  case starter
}

extension DBusBusType {
  init(_ type: BusType) {
    self.init(rawValue: type.rawValue)
  }
}

public typealias BusName = String

public typealias Interface = String

public typealias Member = String

public struct Timeout: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }
}

extension Timeout {
  public static let useDefault = Timeout(rawValue: DBUS_TIMEOUT_USE_DEFAULT)
  public static let infinite = Timeout(rawValue: DBUS_TIMEOUT_INFINITE)

  public static func milliseconds(_ milliseconds: Int32) -> Timeout {
    Timeout(rawValue: milliseconds)
  }
}
