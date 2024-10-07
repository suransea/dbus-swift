import CDBus

/// Represents the type of a D-Bus bus.
public enum BusType: UInt32 {
  /// The login session bus.
  case session
  /// The systemwide bus.
  case system
  /// The bus that started us, if any.
  case starter
}

extension DBusBusType {
  /// Initializes a `DBusBusType` from a `BusType`.
  ///
  /// - Parameter type: The `BusType` to convert.
  init(_ type: BusType) {
    self.init(rawValue: type.rawValue)
  }
}

/// Represents a D-Bus bus name.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-names-bus
public struct BusName: RawRepresentable, Hashable, Equatable, Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension BusName: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.rawValue = value
  }
}

extension BusName: CustomStringConvertible {
  public var description: String { rawValue }
}

extension BusName: Argument {
  public static var type: ArgumentType { .string }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    self.rawValue = try String(from: &iter)
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

extension BusName {
  /// The bus name of the message bus.
  public static let bus: BusName = "org.freedesktop.DBus"
}

extension ObjectPath {
  /// The path of the message bus.
  public static let bus: ObjectPath = "/org/freedesktop/DBus"
}

extension InterfaceName {
  /// The interface name of message bus.
  public static let bus: InterfaceName = "org.freedesktop.DBus"
}

/// Message bus proxy, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus
public struct Bus {
  private let methods: MethodsProxy
  private let properties: PropertiesProxy
  private let signals: SignalsProxy

  /// Initializes a new message bus proxy on the given connection.
  ///
  /// - Parameters:
  ///   - connection: The connection to use.
  ///   - timeout: The timeout to use for method calls.
  public init(connection: Connection, timeout: TimeoutInterval = .useDefault) {
    let object = ObjectProxy(
      connection: connection, destination: .bus, path: .bus, timeout: timeout)
    methods = object.methods(interface: .bus)
    properties = object.properties(interface: .bus)
    signals = object.signals(interface: .bus)
  }

  /// Lists abstract "features" provided by the message bus.
  public var features: some ReadOnlyProperty<[String]> {
    properties.Features
  }

  /// Lists interfaces provided by the message bus.
  public var interfaces: some ReadOnlyProperty<[String]> {
    properties.Interfaces
  }

  /// Sends the org.freedesktop.DBus.Hello message to the message bus to obtain a unique name.
  /// If an application without a unique name tries to send a message to another application,
  /// or a message to the message bus itself that isn't the org.freedesktop.DBus.Hello message,
  /// it will be disconnected from the bus.
  /// There is no corresponding "disconnect" request;
  /// if a client wishes to disconnect from the bus, it simply closes the socket (or other communication channel).
  ///
  /// - Returns: Unique name assigned to the connection.
  public func hello() throws(DBus.Error) -> String {
    try methods.Hello()
  }

  /// Async version of `hello()`
  @available(macOS 10.15.0, *)
  public func hello() async throws(DBus.Error) -> String {
    try await methods.Hello()
  }

  /// Asks the message bus to assign the given name to the method caller.
  ///
  /// - Parameters:
  ///   - name: The name to request.
  ///   - flags: Flags to modify the behavior of the request.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  public func requestName(
    _ name: BusName, _ flags: RequestNameFlags
  ) throws(DBus.Error) -> RequestNameReply {
    try methods.RequestName(name, flags)
  }

  /// Async version of `requestName(_:_:)`
  @available(macOS 10.15.0, *)
  public func requestName(
    _ name: BusName, _ flags: RequestNameFlags
  ) async throws(DBus.Error) -> RequestNameReply {
    try await methods.RequestName(name, flags)
  }

  /// Releases a previously requested name.
  /// This will release the name from the caller's ownership, allowing other clients to request it.
  ///
  /// - Parameter name: The name to release.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  public func releaseName(_ name: BusName) throws(DBus.Error) -> ReleaseNameReply {
    try methods.ReleaseName(name)
  }

  /// Async version of `releaseName(_:)`
  @available(macOS 10.15.0, *)
  public func releaseName(_ name: BusName) async throws(DBus.Error) -> ReleaseNameReply {
    try await methods.ReleaseName(name)
  }

  /// Lists all currently-owned names on the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of names.
  public func listNames() throws(DBus.Error) -> [BusName] {
    try methods.ListNames()
  }

  /// Async version of `listNames()`
  @available(macOS 10.15.0, *)
  public func listNames() async throws(DBus.Error) -> [BusName] {
    try await methods.ListNames()
  }

  /// Lists all names that can be activated on the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of names.
  public func listActivatableNames() throws(DBus.Error) -> [BusName] {
    try methods.ListActivatableNames()
  }

  /// Async version of `listActivatableNames()`
  @available(macOS 10.15.0, *)
  public func listActivatableNames() async throws(DBus.Error) -> [BusName] {
    try await methods.ListActivatableNames()
  }

  /// Adds a match rule to the connection.
  /// Match rules are used to select messages from the message bus.
  /// See https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-routing-match-rules
  ///
  /// - Parameter rule: The match rule to add.
  /// - Throws: `DBus.Error` if the request failed.
  public func addMatch(_ rule: MatchRule) throws(DBus.Error) {
    try methods.AddMatch(rule) as Void
  }

  /// Async version of `addMatch(_:)`
  @available(macOS 10.15.0, *)
  public func addMatch(_ rule: MatchRule) async throws(DBus.Error) {
    try await methods.AddMatch(rule) as Void
  }

  /// Removes a match rule from the connection.
  /// Match rules are used to select messages from the message bus.
  /// See https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-routing-match-rules
  ///
  /// - Parameter rule: The match rule to remove.
  /// - Throws: `DBus.Error` if the request failed.
  public func removeMatch(_ rule: MatchRule) throws(DBus.Error) {
    try methods.RemoveMatch(rule) as Void
  }

  /// Async version of `removeMatch(_:)`
  @available(macOS 10.15.0, *)
  public func removeMatch(_ rule: MatchRule) async throws(DBus.Error) {
    try await methods.RemoveMatch(rule) as Void
  }

  /// Checks if a name has an owner.
  ///
  /// - Parameter name: The name to check.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: `true` if the name has an owner, `false` otherwise.
  public func nameHasOwner(_ name: BusName) throws(DBus.Error) -> Bool {
    try methods.NameHasOwner(name)
  }

  /// Async version of `nameHasOwner(_:)`
  @available(macOS 10.15.0, *)
  public func nameHasOwner(_ name: BusName) async throws(DBus.Error) -> Bool {
    try await methods.NameHasOwner(name)
  }

  /// Gets the unique name of the owner of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: org.freedesktop.DBus.Error.NameHasNoOwner if the requested name doesn't have an owner.
  /// - Returns: The unique name of the owner.
  public func getNameOwner(_ name: BusName) throws(DBus.Error) -> BusName {
    try methods.GetNameOwner(name)
  }

  /// Async version of `getNameOwner(_:)`
  @available(macOS 10.15.0, *)
  public func getNameOwner(_ name: BusName) async throws(DBus.Error) -> BusName {
    try await methods.GetNameOwner(name)
  }

  /// Tries to launch the executable associated with a name (service activation), as an explicit request.
  ///
  /// - Parameters:
  ///   - name: The name of the service to start.
  ///   - flags: Flags to modify the behavior of the request, currently not used.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The reply of the request.
  public func startServiceByName(
    _ name: BusName, _ flags: StartServiceFlags
  ) throws(DBus.Error) -> StartServiceReply {
    try methods.StartServiceByName(name, flags)
  }

  /// Async version of `startServiceByName(_:_:)`
  @available(macOS 10.15.0, *)
  public func startServiceByName(
    _ name: BusName, _ flags: StartServiceFlags
  ) async throws(DBus.Error) -> StartServiceReply {
    try await methods.StartServiceByName(name, flags)
  }

  /// Updates the activation environment of the connection.
  ///
  /// - Parameter environment: The new activation environment.
  /// - Throws: `DBus.Error` if the request failed.
  public func updateActivationEnvironment(_ environment: [String: String]) throws(DBus.Error) {
    try methods.UpdateActivationEnvironment(environment) as Void
  }

  /// Async version of `updateActivationEnvironment(_:)`
  @available(macOS 10.15.0, *)
  public func updateActivationEnvironment(
    _ environment: [String: String]
  ) async throws(DBus.Error) {
    try await methods.UpdateActivationEnvironment(environment) as Void
  }

  /// Lists the queued owners of the given name.
  /// The queued owners are the names that have requested the name but not yet been granted it.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The list of queued owners.
  public func listQueuedOwners(_ name: BusName) throws(DBus.Error) -> [BusName] {
    try methods.ListQueuedOwners(name)
  }

  /// Async version of `listQueuedOwners(_:)`
  @available(macOS 10.15.0, *)
  public func listQueuedOwners(_ name: BusName) async throws(DBus.Error) -> [BusName] {
    try await methods.ListQueuedOwners(name)
  }

  /// Gets the connection Unix user ID of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if unable to determine it (for instance, because the process is not on the same machine as the bus daemon).
  /// - Returns: The connection Unix user ID.
  public func getConnectionUnixUser(_ name: BusName) throws(DBus.Error) -> UInt32 {
    try methods.GetConnectionUnixUser(name)
  }

  /// Async version of `getConnectionUnixUser(_:)`
  @available(macOS 10.15.0, *)
  public func getConnectionUnixUser(_ name: BusName) async throws(DBus.Error) -> UInt32 {
    try await methods.GetConnectionUnixUser(name)
  }

  /// Gets the connection Unix process ID of the given name.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if unable to determine it (for instance, because the process is not on the same machine as the bus daemon).
  /// - Returns: The connection Unix process ID.
  public func getConnectionUnixProcessId(_ name: BusName) throws(DBus.Error) -> UInt32 {
    try methods.GetConnectionUnixProcessId(name)
  }

  /// Async version of `getConnectionUnixProcessId(_:)`
  @available(macOS 10.15.0, *)
  public func getConnectionUnixProcessId(_ name: BusName) async throws(DBus.Error) -> UInt32 {
    try await methods.GetConnectionUnixProcessId(name)
  }

  /// Gets auditing data used by Solaris ADT of the given name, in an unspecified binary format.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The audit session data.
  public func getAdtAuditSessionData(_ name: BusName) throws(DBus.Error) -> [UInt8] {
    try methods.GetAdtAuditSessionData(name)
  }

  /// Async version of `getAdtAuditSessionData(_:)`
  @available(macOS 10.15.0, *)
  public func getAdtAuditSessionData(_ name: BusName) async throws(DBus.Error) -> [UInt8] {
    try await methods.GetAdtAuditSessionData(name)
  }

  /// Gets the SELinux security context of the given name, in an unspecified binary format.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The SELinux security context.
  public func getConnectionSELinuxSecurityContext(_ name: BusName) throws(DBus.Error) -> [UInt8] {
    try methods.GetConnectionSELinuxSecurityContext(name)
  }

  /// Async version of `getConnectionSELinuxSecurityContext(_:)`
  @available(macOS 10.15.0, *)
  public func getConnectionSELinuxSecurityContext(
    _ name: BusName
  ) async throws(DBus.Error) -> [UInt8] {
    try await methods.GetConnectionSELinuxSecurityContext(name)
  }

  /// Gets the unique ID of the bus.
  ///
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: The unique ID of the bus.
  public func getId() throws(DBus.Error) -> String {
    try methods.GetId()
  }

  /// Async version of `getId()`
  @available(macOS 10.15.0, *)
  public func getId() async throws(DBus.Error) -> String {
    try await methods.GetId()
  }

  /// Gets as many credentials as possible for the process connected to the server.
  ///
  /// - Parameter name: The name to query.
  /// - Throws: `DBus.Error` if the request failed.
  public func getConnectionCredentials(
    _ name: BusName
  ) throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    try methods.GetConnectionCredentials(name)
  }

  /// Async version of `getConnectionCredentials(_:)`
  @available(macOS 10.15.0, *)
  public func getConnectionCredentials(
    _ name: BusName
  ) async throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    try await methods.GetConnectionCredentials(name)
  }

  /// This signal indicates that the owner of a name has changed.
  /// It's also the signal to use to detect the appearance of new names on the bus.
  ///
  /// - Parameter handler: A block to handle the signal.
  ///   - name: Name with a new owner.
  ///   - oldOwner: Old owner or empty string if none.
  ///   - newOwner: New owner or empty string if none.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: A function to disconnect the signal handler.
  public func nameOwnerChanged(
    _ handler: @escaping (_ name: BusName, _ oldOwner: BusName, _ newOwner: BusName) -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try signals.NameOwnerChanged.connect(handler)
  }

  /// This signal is sent to a specific application when it loses ownership of a name.
  ///
  /// - Parameter handler: A block to handle the signal.
  ///   - name: Name that has been lost.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: A function to disconnect the signal handler.
  public func nameLost(
    _ handler: @escaping (_ name: BusName) -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try signals.NameLost.connect(handler)
  }

  /// This signal is sent to a specific application when it gains ownership of a name.
  ///
  /// - Parameter handler: A block to handle the signal.
  ///   - name: Name that has been acquired.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: A function to disconnect the signal handler.
  public func nameAcquired(
    _ handler: @escaping (_ name: BusName) -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try signals.NameAcquired.connect(handler)
  }

  /// This signal is sent when the list of activatable services,
  /// as returned by `listActivatableNames()`, might have changed.
  /// Clients that have cached information about the activatable
  /// services should call `listActivatableNames()` again to update their cache.
  ///
  /// - Parameter handler: A block to handle the signal.
  /// - Throws: `DBus.Error` if the request failed.
  /// - Returns: A function to disconnect the signal handler.
  public func activatableServicesChanged(
    _ handler: @escaping () -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try signals.ActivatableServicesChanged.connect(handler)
  }
}

/// Flags for RequestName.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-request-name
public struct RequestNameFlags: OptionSet, Sendable {
  public let rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }

  /// Allows replacement of the name.
  public static let allowReplacement = Self(rawValue: 1 << 0)
  /// Replaces the existing owner of the name.
  public static let replaceExisting = Self(rawValue: 1 << 1)
  /// Does not place the message in the queue if the name is not available.
  public static let doNotQueue = Self(rawValue: 1 << 2)
}

extension RequestNameFlags: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    self.init(rawValue: try UInt32(from: &iter))
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

/// Reply of RequestName.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-request-name
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

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    self.init(rawValue: try UInt32(from: &iter))!
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

/// Reply of ReleaseName.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-release-name
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

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    self.init(rawValue: try UInt32(from: &iter))!
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

/// Flags for starting a service.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-start-service-by-name
public struct StartServiceFlags: OptionSet {
  public let rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
}

extension StartServiceFlags: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    self.init(rawValue: try UInt32(from: &iter))
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

/// Reply of StartServiceByName.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#bus-messages-start-service-by-name
public enum StartServiceReply: UInt32 {
  /// The service was successfully started.
  case started = 1
  /// The service was already running.
  case alreadyRunning = 2
}

extension StartServiceReply: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    self.init(rawValue: try UInt32(from: &iter))!
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try rawValue.append(to: &iter)
  }
}
