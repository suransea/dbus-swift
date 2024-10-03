import Foundation

/// Represents interface names.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-names
public struct InterfaceName: RawRepresentable, Hashable, Equatable, Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension InterfaceName: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.rawValue = value
  }
}

extension InterfaceName: CustomStringConvertible {
  public var description: String { rawValue }
}

extension InterfaceName: Argument {
  public static var type: ArgumentType { .string }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    self.rawValue = try String(from: &iter)
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

extension InterfaceName {
  /// Interface name of `Peer`.
  public static let peer: InterfaceName = "org.freedesktop.DBus.Peer"
}

/// Represents the peer interface.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces-peer
public protocol PeerInterface {
  /// Pings the connection.
  func ping()

  /// Gets the machine ID.
  /// - Returns: The machine ID.
  func getMachineId() -> String
}

extension InterfaceName {
  /// Interface name of `Introspectable`.
  public static let introspectable: InterfaceName = "org.freedesktop.DBus.Introspectable"
}

/// Represents the introspectable interface.
/// Objects instances may implement Introspect which returns an XML description of the object,
/// including its interfaces (with signals and methods),
/// objects below it in the object path tree, and its properties.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces-introspectable
public protocol IntrospectableInterface {
  /// Introspects the object.
  /// - Returns: The introspection data.
  func introspect() -> String
}

extension InterfaceName {
  /// Interface name of `Properties`.
  public static let properties: InterfaceName = "org.freedesktop.DBus.Properties"
}

/// Represents the properties interface.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces-properties
public protocol PropertiesInterface {
  /// Gets all properties of the object.
  ///
  /// - Throws: `DBus.Error` if cannot get the properties.
  /// - Returns: The properties.
  func getAll(_ interface: InterfaceName) throws(DBus.Error) -> [String: Variant<AnyArgument>]

  /// Gets a property of the object.
  ///
  /// - Parameters:
  ///   - interface: The interface of the property.
  ///   - name: The name of the property.
  /// - Throws: `DBus.Error` if cannot get the property.
  /// - Returns: The property.
  func get(
    _ interface: InterfaceName, _ name: String
  ) throws(DBus.Error) -> Variant<AnyArgument>

  /// Sets a property of the object.
  ///
  /// - Parameters:
  ///   - interface: The interface of the property.
  ///   - name: The name of the property.
  ///   - value: The value of the property.
  /// - Throws: `DBus.Error` if cannot set the property.
  func set(
    _ interface: InterfaceName, _ name: String, _ value: Variant<AnyArgument>
  ) throws(DBus.Error)
}
