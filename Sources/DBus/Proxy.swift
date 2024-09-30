import CDBus

public struct ObjectProxy {
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

  public func call<each T: Argument, each R: Argument>(
    method: MemberName, of interface: InterfaceName, arguments: repeat each T
  ) throws(DBus.Error) -> (repeat each R) {
    let message = Message(
      methodCall: (destination: destination, path: path, interface: interface, name: method))
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try connection.sendWithReplyAndBlock(message: message, timeout: timeout)
    var replyIter = MessageIter(reading: reply)
    return (repeat (each R).init(from: &replyIter))
  }

  /// A overload function that help compiler to infer the type of "each R".
  /// Could be removed when Swift compiler fixed this issue.
  public func call<each T: Argument, R: Argument>(
    method: MemberName, of interface: InterfaceName, arguments: repeat each T
  ) throws(DBus.Error) -> R {
    let message = Message(
      methodCall: (destination: destination, path: path, interface: interface, name: method))
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try connection.sendWithReplyAndBlock(message: message, timeout: timeout)
    var replyIter = MessageIter(reading: reply)
    return R(from: &replyIter)
  }

  @available(macOS 10.15.0, *)
  public func call<each T: Argument, each R: Argument>(
    method: MemberName, of interface: InterfaceName, arguments: repeat each T
  ) async throws(DBus.Error) -> (repeat each R) {
    let message = Message(
      methodCall: (destination: destination, path: path, interface: interface, name: method))
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try await connection.sendWithReply(message: message, timeout: timeout)
    var replyIter = MessageIter(reading: reply)
    return (repeat (each R).init(from: &replyIter))
  }

  // A overload function that help compiler to infer the type of "each R".
  // Could be removed when Swift compiler fixed this issue.
  @available(macOS 10.15.0, *)
  public func call<each T: Argument, R: Argument>(
    method: MemberName, of interface: InterfaceName, arguments: repeat each T
  ) async throws(DBus.Error) -> R {
    let message = Message(
      methodCall: (destination: destination, path: path, interface: interface, name: method))
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try await connection.sendWithReply(message: message, timeout: timeout)
    var replyIter = MessageIter(reading: reply)
    return R(from: &replyIter)
  }
}

@dynamicMemberLookup
public struct InterfaceProxy {
  private let objectProxy: ObjectProxy
  private let interface: InterfaceName

  public init(objectProxy: ObjectProxy, interface: InterfaceName) {
    self.objectProxy = objectProxy
    self.interface = interface
  }

  public subscript(dynamicMember member: MemberName) -> MemberProxy {
    .init(objectProxy: objectProxy, interface: interface, member: member)
  }
}

public struct MemberProxy {
  let objectProxy: ObjectProxy
  let interface: InterfaceName
  let member: MemberName

  public func callAsFunction<each T: Argument, each R: Argument>(
    _ arguments: repeat each T
  ) throws(DBus.Error) -> (repeat each R) {
    try objectProxy.call(method: member, of: interface, arguments: repeat each arguments)
  }

  /// A overload function that help compiler to infer the type of "each R".
  /// Could be removed when Swift compiler fixed this issue.
  public func callAsFunction<each T: Argument, R: Argument>(
    _ arguments: repeat each T
  ) throws(DBus.Error) -> R {
    try objectProxy.call(method: member, of: interface, arguments: repeat each arguments)
  }

  @available(macOS 10.15.0, *)
  public func callAsFunction<each T: Argument, each R: Argument>(
    _ arguments: repeat each T
  ) async throws(DBus.Error) -> (repeat each R) {
    try await objectProxy.call(method: member, of: interface, arguments: repeat each arguments)
  }

  /// A overload function that help compiler to infer the type of "each R".
  /// Could be removed when Swift compiler fixed this issue.
  @available(macOS 10.15.0, *)
  public func callAsFunction<each T: Argument, R: Argument>(
    _ arguments: repeat each T
  ) async throws(DBus.Error) -> R {
    try await objectProxy.call(method: member, of: interface, arguments: repeat each arguments)
  }
}
