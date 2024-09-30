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

/// Bus names, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-names-bus
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

  public init(from iter: inout MessageIter) {
    self.rawValue = String(from: &iter)
  }

  public func append(to iter: inout MessageIter) throws(Error) {
    try rawValue.append(to: &iter)
  }
}

extension BusName {
  /// The D-Bus bus name.
  public static let bus: BusName = "org.freedesktop.DBus"
}

/// Bus object, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus
public struct Bus: BusInterface, PeerInterface, IntrospectableInterface {
  private let bus: InterfaceProxy
  private let peer: InterfaceProxy
  private let introspectable: InterfaceProxy
  private let properties: PropertiesProxy

  /// Create a new bus object on the given connection.
  ///
  /// - Parameters:
  ///   - connection: The connection to use.
  ///   - timeout: The timeout to use for method calls.
  public init(on connection: Connection, timeout: TimeoutInterval = .useDefault) {
    let objectProxy = ObjectProxy(
      connection: connection, destination: .bus, path: .bus, timeout: timeout)
    bus = objectProxy.interface(named: .bus)
    peer = objectProxy.interface(named: .peer)
    introspectable = objectProxy.interface(named: .introspectable)
    properties = bus.properties
  }

  public func features() throws(DBus.Error) -> [String] {
    try properties.Features.get()
  }

  @available(macOS 10.15.0, *)
  public func features() async throws(DBus.Error) -> [String] {
    try await properties.Features.get()
  }

  public func hello() throws(DBus.Error) -> String { try bus.Hello() }

  @available(macOS 10.15.0, *)
  public func hello() async throws(DBus.Error) -> String { try await bus.Hello() }

  public func requestName(
    _ name: BusName, _ flags: RequestNameFlags
  ) throws(DBus.Error) -> RequestNameReply {
    try bus.RequestName(name, flags)
  }

  @available(macOS 10.15.0, *)
  public func requestName(
    _ name: BusName, _ flags: RequestNameFlags
  ) async throws(DBus.Error) -> RequestNameReply {
    try await bus.RequestName(name, flags)
  }

  public func releaseName(_ name: BusName) throws(DBus.Error) -> ReleaseNameReply {
    try bus.ReleaseName(name)
  }

  @available(macOS 10.15.0, *)
  public func releaseName(_ name: BusName) async throws(DBus.Error) -> ReleaseNameReply {
    try await bus.ReleaseName(name)
  }

  public func listNames() throws(DBus.Error) -> [BusName] {
    try bus.ListNames()
  }

  @available(macOS 10.15.0, *)
  public func listNames() async throws(DBus.Error) -> [BusName] {
    try await bus.ListNames()
  }

  public func listActivatableNames() throws(DBus.Error) -> [BusName] {
    try bus.ListActivatableNames()
  }

  @available(macOS 10.15.0, *)
  public func listActivatableNames() async throws(DBus.Error) -> [BusName] {
    try await bus.ListActivatableNames()
  }

  public func addMatch(_ rule: String) throws(DBus.Error) {
    try bus.AddMatch(rule) as Void
  }

  @available(macOS 10.15.0, *)
  public func addMatch(_ rule: String) async throws(DBus.Error) {
    try await bus.AddMatch(rule) as Void
  }

  public func removeMatch(_ rule: String) throws(DBus.Error) {
    try bus.RemoveMatch(rule) as Void
  }

  @available(macOS 10.15.0, *)
  public func removeMatch(_ rule: String) async throws(DBus.Error) {
    try await bus.RemoveMatch(rule) as Void
  }

  public func nameHasOwner(_ name: BusName) throws(DBus.Error) -> Bool {
    try bus.NameHasOwner(name)
  }

  @available(macOS 10.15.0, *)
  public func nameHasOwner(_ name: BusName) async throws(DBus.Error) -> Bool {
    try await bus.NameHasOwner(name)
  }

  public func getNameOwner(_ name: BusName) throws(DBus.Error) -> BusName {
    try bus.GetNameOwner(name)
  }

  @available(macOS 10.15.0, *)
  public func getNameOwner(_ name: BusName) async throws(DBus.Error) -> BusName {
    try await bus.GetNameOwner(name)
  }

  public func startServiceByName(
    _ name: BusName, _ flags: StartServiceFlags
  ) throws(DBus.Error) -> StartServiceReply {
    try bus.StartServiceByName(name, flags)
  }

  @available(macOS 10.15.0, *)
  public func startServiceByName(
    _ name: BusName, _ flags: StartServiceFlags
  ) async throws(DBus.Error) -> StartServiceReply {
    try await bus.StartServiceByName(name, flags)
  }

  public func updateActivationEnvironment(_ environment: [String: String]) throws(DBus.Error) {
    try bus.UpdateActivationEnvironment(environment) as Void
  }

  @available(macOS 10.15.0, *)
  public func updateActivationEnvironment(_ environment: [String: String]) async throws(DBus.Error)
  {
    try await bus.UpdateActivationEnvironment(environment) as Void
  }

  public func listQueuedOwners(_ name: BusName) throws(DBus.Error) -> [BusName] {
    try bus.ListQueuedOwners(name)
  }

  @available(macOS 10.15.0, *)
  public func listQueuedOwners(_ name: BusName) async throws(DBus.Error) -> [BusName] {
    try await bus.ListQueuedOwners(name)
  }

  public func getConnectionUnixUser(_ name: BusName) throws(DBus.Error) -> UInt32 {
    try bus.GetConnectionUnixUser(name)
  }

  @available(macOS 10.15.0, *)
  public func getConnectionUnixUser(_ name: BusName) async throws(DBus.Error) -> UInt32 {
    try await bus.GetConnectionUnixUser(name)
  }

  public func getConnectionUnixProcessId(_ name: BusName) throws(DBus.Error) -> UInt32 {
    try bus.GetConnectionUnixProcessId(name)
  }

  @available(macOS 10.15.0, *)
  public func getConnectionUnixProcessId(_ name: BusName) async throws(DBus.Error) -> UInt32 {
    try await bus.GetConnectionUnixProcessId(name)
  }

  public func getAdtAuditSessionData(_ name: BusName) throws(DBus.Error) -> [UInt8] {
    try bus.GetAdtAuditSessionData(name)
  }

  @available(macOS 10.15.0, *)
  public func getAdtAuditSessionData(_ name: BusName) async throws(DBus.Error) -> [UInt8] {
    try await bus.GetAdtAuditSessionData(name)
  }

  public func getConnectionSELinuxSecurityContext(_ name: BusName) throws(DBus.Error) -> [UInt8] {
    try bus.GetConnectionSELinuxSecurityContext(name)
  }

  @available(macOS 10.15.0, *)
  public func getConnectionSELinuxSecurityContext(_ name: BusName) async throws(DBus.Error)
    -> [UInt8]
  {
    try await bus.GetConnectionSELinuxSecurityContext(name)
  }

  public func getId() throws(DBus.Error) -> String {
    try bus.GetId()
  }

  @available(macOS 10.15.0, *)
  public func getId() async throws(DBus.Error) -> String {
    try await bus.GetId()
  }

  public func getConnectionCredentials(
    _ name: BusName
  ) throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    try bus.GetConnectionCredentials(name)
  }

  @available(macOS 10.15.0, *)
  public func getConnectionCredentials(
    _ name: BusName
  ) async throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    try await bus.GetConnectionCredentials(name)
  }

  public func ping() throws(Error) {
    try peer.Ping() as Void
  }

  @available(macOS 10.15.0, *)
  public func ping() async throws(Error) {
    try await peer.Ping() as Void
  }

  public func getMachineId() throws(Error) -> String {
    try peer.GetMachineId()
  }

  @available(macOS 10.15.0, *)
  public func getMachineId() async throws(Error) -> String {
    try await peer.GetMachineId()
  }

  public func introspect() throws(Error) -> String {
    try introspectable.Introspect()
  }

  @available(macOS 10.15.0, *)
  public func introspect() async throws(Error) -> String {
    try await introspectable.Introspect()
  }
}
