import CDBus

public class ObjectProxy {
  let connection: Connection
  let destination: BusName
  let path: ObjectPath
  let timeout: TimeoutInterval

  public init(
    connection: Connection, destination: BusName, path: ObjectPath,
    timeout: TimeoutInterval = .useDefault
  ) {
    self.connection = connection
    self.destination = destination
    self.path = path
    self.timeout = timeout
  }

  public func interface(named name: InterfaceName) -> InterfaceProxy {
    InterfaceProxy(objectProxy: self, interface: name)
  }
}

@dynamicMemberLookup
public struct InterfaceProxy {
  let objectProxy: ObjectProxy
  let interface: InterfaceName

  public init(objectProxy: ObjectProxy, interface: InterfaceName) {
    self.objectProxy = objectProxy
    self.interface = interface
  }

  public var properties: PropertiesProxy {
    PropertiesProxy(objectProxy: objectProxy, interface: interface)
  }

  public subscript(dynamicMember member: MemberName) -> MethodProxy {
    .init(objectProxy: objectProxy, interface: interface, method: member)
  }
}

public struct MethodProxy {
  let objectProxy: ObjectProxy
  let interface: InterfaceName
  let method: MemberName

  public func callAsFunction<each T: Argument, each R: Argument>(
    _ arguments: repeat each T
  ) throws(DBus.Error) -> (repeat each R) {
    let methodCall = (
      destination: objectProxy.destination, path: objectProxy.path,
      interface: interface, name: method
    )
    let message = Message(methodCall: methodCall)
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try objectProxy.connection.sendWithReplyAndBlock(
      message: message, timeout: objectProxy.timeout)
    var replyIter = MessageIter(reading: reply)
    return (repeat (each R).init(from: &replyIter))
  }

  /// A overload function that help compiler to infer the type of "each R".
  /// Could be removed when Swift compiler fixed this issue.
  public func callAsFunction<each T: Argument, R: Argument>(
    _ arguments: repeat each T
  ) throws(DBus.Error) -> R {
    let methodCall = (
      destination: objectProxy.destination, path: objectProxy.path,
      interface: interface, name: method
    )
    let message = Message(methodCall: methodCall)
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try objectProxy.connection.sendWithReplyAndBlock(
      message: message, timeout: objectProxy.timeout)
    var replyIter = MessageIter(reading: reply)
    return R(from: &replyIter)
  }

  @available(macOS 10.15.0, *)
  public func callAsFunction<each T: Argument, each R: Argument>(
    _ arguments: repeat each T
  ) async throws(DBus.Error) -> (repeat each R) {
    let methodCall = (
      destination: objectProxy.destination, path: objectProxy.path,
      interface: interface, name: method
    )
    let message = Message(methodCall: methodCall)
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try await objectProxy.connection.sendWithReply(
      message: message, timeout: objectProxy.timeout)
    var replyIter = MessageIter(reading: reply)
    return (repeat (each R).init(from: &replyIter))
  }

  /// A overload function that help compiler to infer the type of "each R".
  /// Could be removed when Swift compiler fixed this issue.
  @available(macOS 10.15.0, *)
  public func callAsFunction<each T: Argument, R: Argument>(
    _ arguments: repeat each T
  ) async throws(DBus.Error) -> R {
    let methodCall = (
      destination: objectProxy.destination, path: objectProxy.path,
      interface: interface, name: method
    )
    let message = Message(methodCall: methodCall)
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try await objectProxy.connection.sendWithReply(
      message: message, timeout: objectProxy.timeout)
    var replyIter = MessageIter(reading: reply)
    return R(from: &replyIter)
  }
}

@dynamicMemberLookup
public struct PropertiesProxy {
  let properties: InterfaceProxy
  let interface: InterfaceName

  public init(objectProxy: ObjectProxy, interface: InterfaceName) {
    properties = objectProxy.interface(named: .properties)
    self.interface = interface
  }

  public func getAll() throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    try properties.GetAll(interface)
  }

  @available(macOS 10.15.0, *)
  public func getAll() async throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    try await properties.GetAll(interface)
  }

  public subscript(dynamicMember name: String) -> PropertyProxy {
    PropertyProxy(properties: properties, interface: interface, name: name)
  }
}

public struct PropertyProxy {
  private let properties: InterfaceProxy
  private let interface: InterfaceName
  private let name: String

  public init(properties: InterfaceProxy, interface: InterfaceName, name: String) {
    self.properties = properties
    self.interface = interface
    self.name = name
  }

  public func get<R: Argument>() throws(DBus.Error) -> R {
    (try properties.Get(interface, name) as Variant<R>).value
  }

  @available(macOS 10.15.0, *)
  public func get<R: Argument>() async throws(DBus.Error) -> R {
    (try await properties.Get(interface, name) as Variant<R>).value
  }

  public func set(_ value: some Argument) throws(DBus.Error) {
    try properties.Set(interface, name, Variant(value: value)) as Void
  }

  @available(macOS 10.15.0, *)
  public func set(_ value: some Argument) async throws(DBus.Error) {
    try await properties.Set(interface, name, Variant(value: value)) as Void
  }
}
