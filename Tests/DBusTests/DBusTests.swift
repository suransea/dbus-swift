import Testing

@testable import DBus

@Test func example() async throws {
  // Write your test here and use APIs like `#expect(...)` to check expected conditions.
  let connection = try Connection(type: .session)
  print("Connected to session bus as \(connection.uniqueName)")
  let objectProxy = ObjectProxy(
    connection: connection,
    destination: "org.freedesktop.DBus",
    path: ObjectPath(rawValue: "/"))
  let interfaceProxy = InterfaceProxy(
    objectProxy: objectProxy,
    interface: "org.freedesktop.DBus")
  let names: [String] = try interfaceProxy.ListNames()
  print("Names: \(names)")
}
