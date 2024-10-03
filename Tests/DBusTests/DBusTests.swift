import Testing

@testable import DBus

@Test func signatures() async throws {
  #expect("a{sv}" == [String: Variant<AnyArgument>].signature)
  #expect("aa{si}" == [["": 0 as Int32]].signature)
  if #available(macOS 14.0.0, *) {
    #expect(
      "(yyyyuua(yv))"
        == Struct<
          UInt8, UInt8, UInt8, UInt8, UInt32, UInt32, [Struct<UInt8, Variant<AnyArgument>>]
        >.signature)
    #expect(
      "(ybnqiuxtdsogh)"
        == Struct<
          UInt8, Bool, Int16, UInt16, Int32, UInt32, Int64, UInt64, Double, String, ObjectPath,
          Signature,
          FileDescriptor
        >.signature
    )
    #expect(
      "(ybnqiuxtdsogh)"
        == Struct(
          0 as UInt8, false, 0 as Int16, 0 as UInt16, 0 as Int32, 0 as UInt32, 0 as Int64,
          0 as UInt64, 0.0, "", ObjectPath.bus, Signature(rawValue: ""), FileDescriptor(rawValue: 0)
        ).signature)
  }
  #expect("(si)" == AnyStruct("", 0 as Int32).signature)
  #expect(
    "(yyyyuua(yv))"
      == AnyStruct(
        0 as UInt8, 0 as UInt8, 0 as UInt8, 0 as UInt8, 0 as UInt32, 0 as UInt32,
        [AnyStruct(0 as UInt8, Variant(0 as Int32))]
      ).signature)
}
