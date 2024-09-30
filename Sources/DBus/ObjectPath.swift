import CDBus

/// Object path, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling-object-path
public struct ObjectPath: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension ObjectPath: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.rawValue = value
  }
}

extension ObjectPath: CustomStringConvertible {
  public var description: String { rawValue }
}

extension ObjectPath: Argument {
  public static var type: ArgumentType { .objectPath }

  public init(from iter: inout MessageIter) {
    self.rawValue = String(cString: iter.getBasic().str)
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try rawValue.withCStringTypedThrows { cString throws(DBus.Error) in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      try iter.append(basic: &basicValue, type: .objectPath)
    }
  }
}

extension ObjectPath {
  /// The D-Bus root object path.
  public static let bus: ObjectPath = "/org/freedesktop/DBus"
}
