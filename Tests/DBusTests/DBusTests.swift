import Dispatch
import Foundation
import Testing

@testable import DBus

@Test func example() async throws {
  // Write your test here and use APIs like `#expect(...)` to check expected conditions.
  let connection = try Connection(type: .session)
  try connection.setupDispatch(with: RunLoop.main)
  print("Connected to session bus as \(connection.uniqueName)")
  let bus = Bus(on: connection)
  let names = try await bus.listActivatableNames()
  print("Names: \(names)")
  let introspect = try await bus.introspect()
  print("Introspect: \(introspect)")
  let features = try await bus.features()
  print("Features: \(features)")
}
