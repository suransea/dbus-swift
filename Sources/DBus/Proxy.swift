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

  public func call<each T: ArgumentProtocol>(
    method: Member, interface: Interface, arguments: repeat each T
  ) throws -> Message {
    fatalError("TODO")
  }
}
