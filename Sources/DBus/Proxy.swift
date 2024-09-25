import CDBus

public struct ObjectProxy {
  let connection: Connection
  let destination: BusName
  let path: ObjectPath
  let timeout: TimeoutInterval = .useDefault

  public func call<each T: Argument, each R: Argument>(
    method: Member, of interface: Interface, arguments: repeat each T
  ) throws(DBus.Error) -> (repeat each R) {
    let message = Message(
      methodCall: (destination: destination, path: path, interface: interface, name: method))
    var messageIter = MessageIter(appending: message)
    repeat try (each arguments).append(to: &messageIter)
    let reply = try connection.sendWithReplyAndBlock(message: message, timeout: timeout)
    var replyIter = MessageIter(reading: reply)
    return (repeat (each R).init(from: &replyIter))
  }
}

@dynamicMemberLookup
public struct InterfaceProxy {
  private let objectProxy: ObjectProxy
  private let interface: Interface

  public init(objectProxy: ObjectProxy, interface: Interface) {
    self.objectProxy = objectProxy
    self.interface = interface
  }

  public subscript(dynamicMember member: Member) -> MemberProxy {
    .init(objectProxy: objectProxy, interface: interface, member: member)
  }
}

public struct MemberProxy {
  let objectProxy: ObjectProxy
  let interface: Interface
  let member: Member

  public func callAsFunction<each T: Argument, each R: Argument>(
    _ arguments: repeat each T
  ) throws(DBus.Error) -> (repeat each R) {
    try objectProxy.call(method: member, of: interface, arguments: repeat each arguments)
  }
}
