import Foundation

/// D-Bus interface name, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-names
public typealias InterfaceName = String

/// Interface protocol represents a D-Bus interface.
///
/// `InterfaceProtocol` declares the destination, object path and interface name of an interface,
/// and provides a static function to create a proxy object.
///
/// It's suggested to create a new protocol extended this for each D-Bus interface.
public protocol InterfaceProtocol {
  /// The destination of the interface.
  static var destination: BusName { get }
  /// The object path of the interface.
  static var objectPath: ObjectPath { get }
  /// The name of the interface.
  static var name: InterfaceName { get }
}

extension InterfaceProtocol {
  /// Create a new proxy on the given connection.
  ///
  /// - Parameter connection: The connection to create the proxy on.
  public static func proxy(on connection: Connection) -> InterfaceProxy {
    InterfaceProxy(
      objectProxy: ObjectProxy(
        connection: connection, destination: Self.destination, path: Self.objectPath),
      interface: Self.name)
  }
}

/// D-Bus message bus interface, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus
public struct DBusInterface: InterfaceProtocol {
  public static var destination: BusName { "org.freedesktop.DBus" }
  public static var objectPath: ObjectPath { .init(rawValue: "/org/freedesktop/DBus") }
  public static var name: InterfaceName { "org.freedesktop.DBus" }

  private let proxy: InterfaceProxy

  /// Create a new D-Bus interface on the given connection.
  ///
  /// - Parameter connection: The connection to create the interface on.
  public init(on connection: Connection) {
    proxy = Self.proxy(on: connection)
  }

  /// Before an application is able to send messages to other applications it must send the
  /// org.freedesktop.DBus.Hello message to the message bus to obtain a unique name.
  /// If an application without a unique name tries to send a message to another application,
  /// or a message to the message bus itself that isn't the org.freedesktop.DBus.Hello message,
  /// it will be disconnected from the bus.
  /// There is no corresponding "disconnect" request;
  /// if a client wishes to disconnect from the bus, it simply closes the socket (or other communication channel).
  ///
  /// - Returns: Unique name assigned to the connection.
  public func hello() throws(DBus.Error) -> String { try proxy.Hello() }

  /// Async version of `hello()`.
  @available(macOS 10.15.0, *)
  public func hello() async throws(DBus.Error) -> String { try await proxy.Hello() }

  /// Ask the message bus to assign the given name to the method caller.
  ///
  /// - Parameters:
  ///   - name: The name to request.
  ///   - flags: Flags to modify the behavior of the request.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  public func requestName(
    _ name: BusName, _ flags: RequestNameFlags
  ) throws(DBus.Error) -> RequestNameReply {
    try proxy.RequestName(name, flags)
  }

  /// Async version of `requestName(_:flags:)`.
  @available(macOS 10.15.0, *)
  public func requestName(
    _ name: BusName, _ flags: RequestNameFlags
  ) async throws(DBus.Error) -> RequestNameReply {
    try await proxy.RequestName(name, flags)
  }

  /// Release a previously requested name.
  /// This will release the name from the caller's ownership, allowing other clients to request it.
  ///
  /// - Parameter name: The name to release.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  public func releaseName(_ name: BusName) throws(DBus.Error) -> ReleaseNameReply {
    try proxy.ReleaseName(name)
  }

  /// async version of `releaseName(_:)`.
  @available(macOS 10.15.0, *)
  public func releaseName(_ name: BusName) async throws(DBus.Error) -> ReleaseNameReply {
    try await proxy.ReleaseName(name)
  }

  /// List all currently-owned names on the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of names.
  public func listNames() throws(DBus.Error) -> [BusName] {
    try proxy.ListNames()
  }

  /// Async version of `listNames()`.
  @available(macOS 10.15.0, *)
  public func listNames() async throws(DBus.Error) -> [BusName] {
    try await proxy.ListNames()
  }

  /// List all names that can be activated on the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of names.
  public func listActivatableNames() throws(DBus.Error) -> [BusName] {
    try proxy.ListActivatableNames()
  }

  /// Async version of `listActivatableNames()`.
  @available(macOS 10.15.0, *)
  public func listActivatableNames() async throws(DBus.Error) -> [BusName] {
    try await proxy.ListActivatableNames()
  }

  /// Add a match rule to the connection.
  /// Match rules are used to select messages from the message bus, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-routing-match-rules
  ///
  /// - Parameter rule: The match rule to add.
  /// - Throws: `DBus.Error` if the request failed.
  public func addMatch(_ rule: String) throws(DBus.Error) {
    try proxy.AddMatch(rule) as Void
  }

  /// Async version of `addMatch(_:)`.
  @available(macOS 10.15.0, *)
  public func addMatch(_ rule: String) async throws(DBus.Error) {
    try await proxy.AddMatch(rule) as Void
  }

  /// Remove a match rule from the connection.
  /// Match rules are used to select messages from the message bus, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-routing-match-rules
  ///
  /// - Parameter rule: The match rule to remove.
  /// - Throws: `DBus.Error` if the request failed.
  public func removeMatch(_ rule: String) throws(DBus.Error) {
    try proxy.RemoveMatch(rule) as Void
  }

  /// Async version of `removeMatch(_:)`.
  @available(macOS 10.15.0, *)
  public func removeMatch(_ rule: String) async throws(DBus.Error) {
    try await proxy.RemoveMatch(rule) as Void
  }

  /// Check if a name has an owner.
  ///
  /// - Parameter name: The name to check.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: `true` if the name has an owner, `false` otherwise.
  public func nameHasOwner(_ name: BusName) throws(DBus.Error) -> Bool {
    try proxy.NameHasOwner(name)
  }

  /// Async version of `nameHasOwner(_:)`.
  @available(macOS 10.15.0, *)
  public func nameHasOwner(_ name: BusName) async throws(DBus.Error) -> Bool {
    try await proxy.NameHasOwner(name)
  }

  /// Get the unique name of the owner of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: org.freedesktop.DBus.Error.NameHasNoOwner if the requested name doesn't have an owner
  /// - Returns: The unique name of the owner.
  public func getNameOwner(_ name: BusName) throws(DBus.Error) -> BusName {
    try proxy.GetNameOwner(name)
  }

  /// Async version of `getNameOwner(_:)`.
  @available(macOS 10.15.0, *)
  public func getNameOwner(_ name: BusName) async throws(DBus.Error) -> BusName {
    try await proxy.GetNameOwner(name)
  }

  /// Tries to launch the executable associated with a name (service activation), as an explicit request.
  ///
  /// - Parameters:
  ///   - name: The name of the service to start.
  ///   - flags: Flags to modify the behavior of the request, currently not used
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  public func startServiceByName(
    _ name: BusName, _ flags: StartServiceFlags
  ) throws(DBus.Error) -> StartServiceReply {
    try proxy.StartServiceByName(name, flags)
  }

  /// Async version of `startServiceByName(_:flags:)`.
  @available(macOS 10.15.0, *)
  public func startServiceByName(
    _ name: BusName, _ flags: StartServiceFlags
  ) async throws(DBus.Error) -> StartServiceReply {
    try await proxy.StartServiceByName(name, flags)
  }

  /// Update the activation environment of the connection.
  ///
  /// - Parameter environment: The new activation environment.
  /// - Throws: `DBus.Error` if the request failed.
  public func updateActivationEnvironment(_ environment: [String: String]) throws(DBus.Error) {
    try proxy.UpdateActivationEnvironment(environment) as Void
  }

  /// Async version of `updateActivationEnvironment(_:)`.
  @available(macOS 10.15.0, *)
  public func updateActivationEnvironment(_ environment: [String: String]) async throws(DBus.Error)
  {
    try await proxy.UpdateActivationEnvironment(environment) as Void
  }

  /// List the queued owners of the given name.
  /// The queued owners are the names that have requested the name but not yet been granted it.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of queued owners.
  public func listQueuedOwners(_ name: BusName) throws(DBus.Error) -> [BusName] {
    try proxy.ListQueuedOwners(name)
  }

  /// Async version of `listQueuedOwners(_:)`.
  @available(macOS 10.15.0, *)
  public func listQueuedOwners(_ name: BusName) async throws(DBus.Error) -> [BusName] {
    try await proxy.ListQueuedOwners(name)
  }

  /// Get the connection Unix user ID of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if unable to determine it (for instance, because the process is not on the same machine as the bus daemon).
  /// - Returns: The connection Unix user ID.
  public func getConnectionUnixUser(_ name: BusName) throws(DBus.Error) -> UInt32 {
    try proxy.GetConnectionUnixUser(name)
  }

  /// Async version of `getConnectionUnixUser(_:)`.
  @available(macOS 10.15.0, *)
  public func getConnectionUnixUser(_ name: BusName) async throws(DBus.Error) -> UInt32 {
    try await proxy.GetConnectionUnixUser(name)
  }

  /// Get the connection Unix process ID of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if unable to determine it (for instance, because the process is not on the same machine as the bus daemon).
  /// - Returns: The connection Unix process ID.
  public func getConnectionUnixProcessId(_ name: BusName) throws(DBus.Error) -> UInt32 {
    try proxy.GetConnectionUnixProcessId(name)
  }

  /// Async version of `getConnectionUnixProcessId(_:)`.
  @available(macOS 10.15.0, *)
  public func getConnectionUnixProcessId(_ name: BusName) async throws(DBus.Error) -> UInt32 {
    try await proxy.GetConnectionUnixProcessId(name)
  }

  /// Get auditing data used by Solaris ADT of the given name, in an unspecified binary format.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The audit session data.
  public func getAdtAuditSessionData(_ name: BusName) throws(DBus.Error) -> [UInt8] {
    try proxy.GetAdtAuditSessionData(name)
  }

  /// Async version of `getAdtAuditSessionData(_:)`.
  @available(macOS 10.15.0, *)
  public func getAdtAuditSessionData(_ name: BusName) async throws(DBus.Error) -> [UInt8] {
    try await proxy.GetAdtAuditSessionData(name)
  }

  /// Get the SELinux security context of the given name, in an unspecified binary format.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The SELinux security context.
  public func getConnectionSELinuxSecurityContext(_ name: BusName) throws(DBus.Error) -> [UInt8] {
    try proxy.GetConnectionSELinuxSecurityContext(name)
  }

  /// Async version of `getConnectionSELinuxSecurityContext(_:)`.
  @available(macOS 10.15.0, *)
  public func getConnectionSELinuxSecurityContext(_ name: BusName) async throws(DBus.Error)
    -> [UInt8]
  {
    try await proxy.GetConnectionSELinuxSecurityContext(name)
  }

  /// Gets the unique ID of the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The unique ID of the bus.
  public func getId() throws(DBus.Error) -> String {
    try proxy.GetId()
  }

  /// Async version of `getId()`.
  @available(macOS 10.15.0, *)
  public func getId() async throws(DBus.Error) -> String {
    try await proxy.GetId()
  }

  /// Get as many credentials as possible for the process connected to the server.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  ///
  public func getConnectionCredentials(_ name: BusName) throws(DBus.Error) -> [String: AnyVariant] {
    try proxy.GetConnectionCredentials(name)
  }

  /// Async version of `getConnectionCredentials(_:)`.
  @available(macOS 10.15.0, *)
  public func getConnectionCredentials(_ name: BusName) async throws(DBus.Error) -> [String:
    AnyVariant]
  {
    try await proxy.GetConnectionCredentials(name)
  }
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
