/// Represents member names.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-names-member
public struct MemberName: RawRepresentable, Hashable, Equatable, Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension MemberName: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.rawValue = value
  }
}

extension MemberName: CustomStringConvertible {
  public var description: String { rawValue }
}
