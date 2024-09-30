import Foundation

/// Interface names, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-names
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

/// Bus interface, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-messages
public protocol BusInterface {
  /// Before an application is able to send messages to other applications it must send the
  /// org.freedesktop.DBus.Hello message to the message bus to obtain a unique name.
  /// If an application without a unique name tries to send a message to another application,
  /// or a message to the message bus itself that isn't the org.freedesktop.DBus.Hello message,
  /// it will be disconnected from the bus.
  /// There is no corresponding "disconnect" request;
  /// if a client wishes to disconnect from the bus, it simply closes the socket (or other communication channel).
  ///
  /// - Returns: Unique name assigned to the connection.
  func hello() throws -> String

  /// Async version of `hello()`.
  func hello() async throws -> String

  /// Ask the message bus to assign the given name to the method caller.
  ///
  /// - Parameters:
  ///   - name: The name to request.
  ///   - flags: Flags to modify the behavior of the request.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  func requestName(_ name: BusName, _ flags: RequestNameFlags) throws -> RequestNameReply

  /// Async version of `requestName(_:flags:)`.
  func requestName(_ name: BusName, _ flags: RequestNameFlags) async throws -> RequestNameReply

  /// Release a previously requested name.
  /// This will release the name from the caller's ownership, allowing other clients to request it.
  ///
  /// - Parameter name: The name to release.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  func releaseName(_ name: BusName) throws -> ReleaseNameReply

  /// Async version of `releaseName(_:)`.
  func releaseName(_ name: BusName) async throws -> ReleaseNameReply

  /// List all currently-owned names on the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of names.
  func listNames() throws -> [BusName]

  /// Async version of `listNames()`.
  func listNames() async throws -> [BusName]

  /// List all names that can be activated on the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of names.
  func listActivatableNames() throws -> [BusName]

  /// Async version of `listActivatableNames()`.
  func listActivatableNames() async throws -> [BusName]

  /// Add a match rule to the connection.
  /// Match rules are used to select messages from the message bus, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-routing-match-rules
  ///
  /// - Parameter rule: The match rule to add.
  /// - Throws: `DBus.Error` if the request failed.
  func addMatch(_ rule: String) throws

  /// Async version of `addMatch(_:)`.
  func addMatch(_ rule: String) async throws

  /// Remove a match rule from the connection.
  /// Match rules are used to select messages from the message bus, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-routing-match-rules
  ///
  /// - Parameter rule: The match rule to remove.
  /// - Throws: `DBus.Error` if the request failed.
  func removeMatch(_ rule: String) throws

  /// Async version of `removeMatch(_:)`.
  func removeMatch(_ rule: String) async throws

  /// Check if a name has an owner.
  ///
  /// - Parameter name: The name to check.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: `true` if the name has an owner, `false` otherwise.
  func nameHasOwner(_ name: BusName) throws -> Bool

  /// Async version of `nameHasOwner(_:)`.
  func nameHasOwner(_ name: BusName) async throws -> Bool

  /// Get the unique name of the owner of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: org.freedesktop.DBus.Error.NameHasNoOwner if the requested name doesn't have an owner
  /// - Returns: The unique name of the owner.
  func getNameOwner(_ name: BusName) throws -> BusName

  /// Async version of `getNameOwner(_:)`.
  func getNameOwner(_ name: BusName) async throws -> BusName

  /// Tries to launch the executable associated with a name (service activation), as an explicit request.
  ///
  /// - Parameters:
  ///   - name: The name of the service to start.
  ///   - flags: Flags to modify the behavior of the request, currently not used
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  func startServiceByName(_ name: BusName, _ flags: StartServiceFlags) throws -> StartServiceReply

  /// Async version of `startServiceByName(_:flags:)`.
  func startServiceByName(_ name: BusName, _ flags: StartServiceFlags) async throws
    -> StartServiceReply

  /// Update the activation environment of the connection.
  ///
  /// - Parameter environment: The new activation environment.
  /// - Throws: `DBus.Error` if the request failed.
  func updateActivationEnvironment(_ environment: [String: String]) throws

  /// Async version of `updateActivationEnvironment(_:)`.
  func updateActivationEnvironment(_ environment: [String: String]) async throws

  /// List the queued owners of the given name.
  /// The queued owners are the names that have requested the name but not yet been granted it.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of queued owners.
  func listQueuedOwners(_ name: BusName) throws -> [BusName]

  /// Async version of `listQueuedOwners(_:)`.
  func listQueuedOwners(_ name: BusName) async throws -> [BusName]

  /// Get the connection Unix user ID of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if unable to determine it (for instance, because the process is not on the same machine as the bus daemon).
  /// - Returns: The connection Unix user ID.
  func getConnectionUnixUser(_ name: BusName) throws -> UInt32

  /// Async version of `getConnectionUnixUser(_:)`.
  func getConnectionUnixUser(_ name: BusName) async throws -> UInt32

  /// Get the connection Unix process ID of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if unable to determine it (for instance, because the process is not on the same machine as the bus daemon).
  /// - Returns: The connection Unix process ID.
  func getConnectionUnixProcessId(_ name: BusName) throws -> UInt32

  /// Async version of `getConnectionUnixProcessId(_:)`.
  func getConnectionUnixProcessId(_ name: BusName) async throws -> UInt32

  /// Get auditing data used by Solaris ADT of the given name, in an unspecified binary format.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The audit session data.
  func getAdtAuditSessionData(_ name: BusName) throws -> [UInt8]

  /// Async version of `getAdtAuditSessionData(_:)`.
  func getAdtAuditSessionData(_ name: BusName) async throws -> [UInt8]

  /// Get the SELinux security context of the given name, in an unspecified binary format.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The SELinux security context.
  func getConnectionSELinuxSecurityContext(_ name: BusName) throws -> [UInt8]

  /// Async version of `getConnectionSELinuxSecurityContext(_:)`.
  func getConnectionSELinuxSecurityContext(_ name: BusName) async throws -> [UInt8]

  /// Gets the unique ID of the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The unique ID of the bus.
  func getId() throws -> String

  /// Async version of `getId()`.
  func getId() async throws -> String

  /// Get as many credentials as possible for the process connected to the server.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  func getConnectionCredentials(_ name: BusName) throws -> [String: Variant<AnyArgument>]

  /// Async version of `getConnectionCredentials(_:)`.
  func getConnectionCredentials(_ name: BusName) async throws -> [String: Variant<AnyArgument>]
}

extension InterfaceName {
  /// Interface name of `BusInterface`.
  public static let bus: InterfaceName = "org.freedesktop.DBus"
}

/// Peer interface, see https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces-peer
public protocol PeerInterface {
  /// Ping the connection.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  func ping() throws(DBus.Error)

  /// Async version of `ping()`.
  func ping() async throws(DBus.Error)

  /// Get the machine ID.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The machine ID.
  func getMachineId() throws(DBus.Error) -> String

  /// Async version of `getMachineId()`.
  func getMachineId() async throws(DBus.Error) -> String
}

extension InterfaceName {
  /// Interface name of `PeerInterface`.
  public static let peer: InterfaceName = "org.freedesktop.DBus.Peer"
}

/// Objects instances may implement Introspect which returns an XML description of the object,
/// including its interfaces (with signals and methods),
/// objects below it in the object path tree, and its properties.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces-introspectable
public protocol IntrospectableInterface {
  /// Introspect the object.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The introspection data.
  func introspect() throws(DBus.Error) -> String
  /// Async version of `introspect()`.
  func introspect() async throws(DBus.Error) -> String
}

extension InterfaceName {
  /// Interface name of `IntrospectableInterface`.
  public static let introspectable: InterfaceName = "org.freedesktop.DBus.Introspectable"
}

///Properties interface, see https://dbus.freedesktop.org/doc/dbus-specification.html#standard-interfaces-properties
public protocol PropertiesInterface {
  /// Get all properties of the object.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The properties.
  func getAll() throws(DBus.Error) -> [String: Variant<AnyArgument>]
  /// Async version of `getAll()`.
  func getAll() async throws(DBus.Error) -> [String: Variant<AnyArgument>]

  /// Get a property of the object.
  ///
  /// - Parameter name: The name of the property.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The property.
  func get<R: Argument>(_ name: String) throws(DBus.Error) -> R
  /// Async version of `get(_:)`.
  func get<R: Argument>(_ name: String) async throws(DBus.Error) -> R

  /// Set a property of the object.
  ///
  /// - Parameters:
  ///   - name: The name of the property.
  ///   - value: The value of the property.
  /// - Throws: `DBus.Error` if the request failed.
  func set(_ name: String, _ value: some Argument) throws(DBus.Error)
  /// Async version of `set(_:_:)`.
  func set(_ name: String, _ value: some Argument) async throws(DBus.Error)
}

extension InterfaceName {
  /// Interface name of `PropertiesInterface`.
  public static let properties: InterfaceName = "org.freedesktop.DBus.Properties"
}

/// Flags for RequestName, see https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-request-name
public struct RequestNameFlags: OptionSet, Sendable {
  public let rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }

  /// Allow replacement of the name.
  public static let allowReplacement = Self(rawValue: 1 << 0)
  /// Replace the existing owner of the name.
  public static let replaceExisting = Self(rawValue: 1 << 1)
  /// Do not place the message in the queue if the name is not available.
  public static let doNotQueue = Self(rawValue: 1 << 2)
}

extension RequestNameFlags: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIter) {
    self.init(rawValue: UInt32(from: &iter))
  }

  public func append(to iter: inout MessageIter) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

/// Reply of RequestName, see https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-request-name
public enum RequestNameReply: UInt32 {
  /// The name has been successfully obtained.
  case primaryOwner = 1
  /// The name is already owned and the message has been placed in the queue.
  case inQueue = 2
  /// The name is already owned and the message has been discarded.
  case exists = 3
  /// The name is already owned and owned by the same connection.
  case alreadyOwner = 4
}

extension RequestNameReply: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIter) {
    self.init(rawValue: UInt32(from: &iter))!
  }

  public func append(to iter: inout MessageIter) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

/// Reply of ReleaseName, see https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-release-name
public enum ReleaseNameReply: UInt32 {
  /// The name has been successfully released.
  case released = 1
  /// The name does not exist.
  case nonExistent = 2
  /// The name is not owned by the connection.
  case notOwner = 3
}

extension ReleaseNameReply: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIter) {
    self.init(rawValue: UInt32(from: &iter))!
  }

  public func append(to iter: inout MessageIter) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

/// Flags for starting a service, see https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-start-service-by-name
public struct StartServiceFlags: OptionSet {
  public let rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
}

extension StartServiceFlags: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIter) {
    self.init(rawValue: UInt32(from: &iter))
  }

  public func append(to iter: inout MessageIter) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

/// Reply of StartServiceByName, see https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-start-service-by-name
public enum StartServiceReply: UInt32 {
  /// The service was successfully started.
  case started = 1
  /// The service was already running.
  case alreadyRunning = 2
}

extension StartServiceReply: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIter) {
    self.init(rawValue: UInt32(from: &iter))!
  }

  public func append(to iter: inout MessageIter) throws(Error) {
    try rawValue.append(to: &iter)
  }
}
