import CDBus

public class ObjectProxy {
  private let connection: Connection
  private let destination: BusName
  private let path: ObjectPath
  private let timeout: Timeout

  public init(
    connection: Connection, destination: BusName, path: ObjectPath, timeout: Timeout = .useDefault
  ) {
    self.connection = connection
    self.destination = destination
    self.path = path
    self.timeout = timeout
  }

  public func call<each T: Argument, each R: Argument>(
    method: Member, interface: Interface, arguments: repeat each T
  ) throws(DBus.Error) -> (repeat each R) {
    let message = Message(
      methodCall: (destination: destination, path: path, interface: interface, name: method))
    var messageIter = MessageIter(for: message)
    let success = messageIter.append(repeat each arguments)
    guard success else {
      throw .init(name: .noMemory, message: "Failed to append arguments")
    }
    let reply = try connection.sendWithReplyAndBlock(message: message, timeout: timeout)
    var replyIter = MessageIter(for: reply)
    return replyIter.getArguments()
  }
}

@dynamicMemberLookup
public class InterfaceProxy {
  private let objectProxy: ObjectProxy
  private let interface: Interface

  public init(objectProxy: ObjectProxy, interface: Interface) {
    self.objectProxy = objectProxy
    self.interface = interface
  }

  public init(
    connection: Connection, destination: BusName, path: ObjectPath, interface: Interface,
    timeout: Timeout = .useDefault
  ) {
    self.objectProxy = ObjectProxy(
      connection: connection, destination: destination, path: path, timeout: timeout)
    self.interface = interface
  }

  public subscript(dynamicMember member: Member) -> MemberObject {
    MemberObject(interfaceProxy: self, member: member)
  }

  public func call<each T: Argument, each R: Argument>(
    method: Member, arguments: repeat each T
  ) throws(DBus.Error) -> (repeat each R) {
    try objectProxy.call(method: method, interface: interface, arguments: repeat each arguments)
  }

  public class MemberObject {
    private let interfaceProxy: InterfaceProxy
    private let member: Member

    public init(interfaceProxy: InterfaceProxy, member: Member) {
      self.interfaceProxy = interfaceProxy
      self.member = member
    }

    public func callAsFunction<each T: Argument, each R: Argument>(
      _ arguments: repeat each T
    ) throws(DBus.Error) -> (repeat each R) {
      try interfaceProxy.call(method: member, arguments: repeat each arguments)
    }
  }
}
