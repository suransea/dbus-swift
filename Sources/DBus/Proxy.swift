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

  public func call<each T: ArgumentProtocol, R: ArgumentProtocol>(
    method: Member, interface: Interface, arguments: repeat each T
  ) throws -> R {
    fatalError("TODO")
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

  public class MemberObject {
    private let interfaceProxy: InterfaceProxy
    private let member: Member

    public init(interfaceProxy: InterfaceProxy, member: Member) {
      self.interfaceProxy = interfaceProxy
      self.member = member
    }

    public func callAsFunction<each T: ArgumentProtocol, R: ArgumentProtocol>(
      _ arguments: repeat each T
    ) throws -> R {
      return try interfaceProxy.objectProxy.call(
        method: member, interface: interfaceProxy.interface, arguments: repeat each arguments)
    }
  }
}
