import CDBus

public enum ArgumentTypeCode: Int32 {
  /** Type code that is never equal to a legitimate type code */
  case invalid = 0

  /* Primitive types */
  /** Type code marking an 8-bit unsigned integer */
  case byte = 121  // 'y'
  /** Type code marking a boolean */
  case boolean = 98  // 'b'
  /** Type code marking a 16-bit signed integer */
  case int16 = 110  // 'n'
  /** Type code marking a 16-bit unsigned integer */
  case uint16 = 113  // 'q'
  /** Type code marking a 32-bit signed integer */
  case int32 = 105  // 'i'
  /** Type code marking a 32-bit unsigned integer */
  case uint32 = 117  // 'u'
  /** Type code marking a 64-bit signed integer */
  case int64 = 120  // 'x'
  /** Type code marking a 64-bit unsigned integer */
  case uint64 = 116  // 't'
  /** Type code marking an 8-byte double in IEEE 754 format */
  case double = 100  // 'd'
  /** Type code marking a UTF-8 encoded, nul-terminated Unicode string */
  case string = 115  // 's'
  /** Type code marking a D-Bus object path */
  case objectPath = 111  // 'o'
  /** Type code marking a D-Bus type signature */
  case signature = 103  // 'g'
  /** Type code marking a unix file descriptor */
  case unixFD = 104  // 'h'

  /* Compound types */
  /** Type code marking a D-Bus array type */
  case array = 97  // 'a'
  /** Type code marking a D-Bus variant type */
  case variant = 118  // 'v'

  /** STRUCT and DICT_ENTRY are sort of special since their codes can't
     * appear in a type string, instead
     * DBUS_STRUCT_BEGIN_CHAR/DBUS_DICT_ENTRY_BEGIN_CHAR have to appear
     */
  /** Type code used to represent a struct; however, this type code does not appear
     * in type signatures, instead #DBUS_STRUCT_BEGIN_CHAR and #DBUS_STRUCT_END_CHAR will
     * appear in a signature.
     */
  case `struct` = 114  // 'r'
  /** Type code used to represent a dict entry; however, this type code does not appear
     * in type signatures, instead #DBUS_DICT_ENTRY_BEGIN_CHAR and #DBUS_DICT_ENTRY_END_CHAR will
     * appear in a signature.
     */
  case dictEntry = 101  // 'e'
}

public protocol AsBasicValue {
  func asBasicValue() -> DBusBasicValue
}

public protocol WithBasicValue {
  func withBasicValue<R>(_ block: (inout DBusBasicValue) -> R) -> R
}

public protocol FromBasicValue {
  init(_ value: DBusBasicValue)
}

public protocol Argument {
  static var typeCode: ArgumentTypeCode { get }
  static var signature: Signature { get }
}

extension Argument {
  public static var signature: Signature {
    Signature(rawValue: String(UnicodeScalar(UInt32(typeCode.rawValue))!))
  }
}

extension UInt8: Argument {
  public static var typeCode: ArgumentTypeCode { .byte }
}

extension UInt8: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(byt: self)
  }
}

extension UInt8: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.byt
  }
}

extension Bool: Argument {
  public static var typeCode: ArgumentTypeCode { .boolean }
}

extension Bool: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(bool_val: self ? 1 : 0)
  }
}

extension Bool: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.bool_val != 0
  }
}

extension Int16: Argument {
  public static var typeCode: ArgumentTypeCode { .int16 }
}

extension Int16: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(i16: self)
  }
}

extension Int16: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.i16
  }
}

extension UInt16: Argument {
  public static var typeCode: ArgumentTypeCode { .uint16 }
}

extension UInt16: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(u16: self)
  }
}

extension UInt16: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.u16
  }
}

extension Int32: Argument {
  public static var typeCode: ArgumentTypeCode { .int32 }
}

extension Int32: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(i32: self)
  }
}

extension Int32: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.i32
  }
}

extension UInt32: Argument {
  public static var typeCode: ArgumentTypeCode { .uint32 }
}

extension UInt32: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(u32: self)
  }
}

extension UInt32: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.u32
  }
}

extension Int64: Argument {
  public static var typeCode: ArgumentTypeCode { .int64 }
}

extension Int64: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(i64: self)
  }
}

extension Int64: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.i64
  }
}

extension UInt64: Argument {
  public static var typeCode: ArgumentTypeCode { .uint64 }
}

extension UInt64: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(u64: self)
  }
}

extension UInt64: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.u64
  }
}

extension Double: Argument {
  public static var typeCode: ArgumentTypeCode { .double }
}

extension Double: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(dbl: self)
  }
}

extension Double: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = value.dbl
  }
}

extension String: Argument {
  public static var typeCode: ArgumentTypeCode { .string }
}

extension String: WithBasicValue {
  public func withBasicValue<R>(_ block: (inout DBusBasicValue) -> R) -> R {
    withCString { cString in
      var value = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return block(&value)
    }
  }
}

extension String: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self = String(cString: value.str)
  }
}

public struct ObjectPath: Argument, Sendable, Equatable, Hashable, RawRepresentable {
  public static var typeCode: ArgumentTypeCode { .objectPath }
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension ObjectPath: WithBasicValue {
  public func withBasicValue<R>(_ block: (inout DBusBasicValue) -> R) -> R {
    rawValue.withCString { cString in
      var value = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return block(&value)
    }
  }
}

extension ObjectPath: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self.rawValue = String(cString: value.str)
  }
}

public struct Signature: Argument, Sendable, Equatable, Hashable, RawRepresentable {
  public static var typeCode: ArgumentTypeCode { .signature }

  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension Signature: WithBasicValue {
  public func withBasicValue<R>(_ block: (inout DBusBasicValue) -> R) -> R {
    rawValue.withCString { cString in
      var value = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return block(&value)
    }
  }
}

extension Signature: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self.rawValue = String(cString: value.str)
  }
}

public struct FileDescriptor: Argument, RawRepresentable {
  public static var typeCode: ArgumentTypeCode { .unixFD }

  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }
}

extension FileDescriptor: Sendable, Equatable, Hashable {}

extension FileDescriptor: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(fd: self.rawValue)
  }
}

extension FileDescriptor: FromBasicValue {
  public init(_ value: DBusBasicValue) {
    self.rawValue = value.fd
  }
}

extension Array: Argument where Element: Argument {
  public static var typeCode: ArgumentTypeCode { .array }
}
