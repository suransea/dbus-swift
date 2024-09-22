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

protocol AsBasicValue {
  func asBasicValue() -> DBusBasicValue
}

protocol WithBasicValue {
  func withBasicValue<R>(_ block: (inout DBusBasicValue) -> R) -> R
}

public protocol ArgumentProtocol {
  static var typeCode: ArgumentTypeCode { get }
  static var signature: Signature { get }
}

extension ArgumentProtocol {
  public static var signature: Signature {
    Signature(rawValue: String(UnicodeScalar(UInt32(typeCode.rawValue))!))
  }
}

extension UInt8: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .byte }
}

extension UInt8: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(byt: self)
  }
}

extension Bool: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .boolean }
}

extension Bool: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(bool_val: self ? 1 : 0)
  }
}

extension Int16: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .int16 }
}

extension Int16: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(i16: self)
  }
}

extension UInt16: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .uint16 }
}

extension UInt16: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(u16: self)
  }
}

extension Int32: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .int32 }
}

extension Int32: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(i32: self)
  }
}

extension UInt32: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .uint32 }
}

extension UInt32: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(u32: self)
  }
}

extension Int64: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .int64 }
}

extension Int64: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(i64: self)
  }
}

extension UInt64: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .uint64 }
}

extension UInt64: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(u64: self)
  }
}

extension Double: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .double }
}

extension Double: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(dbl: self)
  }
}

extension String: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .string }
}

extension String: WithBasicValue {
  public func withBasicValue<R>(_ block: (inout DBusBasicValue) -> R) -> R {
    return self.withCString { cString in
      var value = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return block(&value)
    }
  }
}

public struct ObjectPath: ArgumentProtocol, Sendable, Equatable, Hashable, RawRepresentable {
  public static var typeCode: ArgumentTypeCode { .objectPath }
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension ObjectPath: WithBasicValue {
  public func withBasicValue<R>(_ block: (inout DBusBasicValue) -> R) -> R {
    return self.rawValue.withCString { cString in
      var value = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return block(&value)
    }
  }
}

public struct Signature: ArgumentProtocol, Sendable, Equatable, Hashable, RawRepresentable {
  public static var typeCode: ArgumentTypeCode { .signature }

  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension Signature: WithBasicValue {
  public func withBasicValue<R>(_ block: (inout DBusBasicValue) -> R) -> R {
    return self.rawValue.withCString { cString in
      var value = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return block(&value)
    }
  }
}

public struct FileDescriptor: ArgumentProtocol, RawRepresentable {
  public static var typeCode: ArgumentTypeCode { .unixFD }

  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }
}

extension FileDescriptor: AsBasicValue {
  public func asBasicValue() -> DBusBasicValue {
    DBusBasicValue(fd: self.rawValue)
  }
}

extension FileDescriptor: Sendable, Equatable, Hashable {}

extension Array: ArgumentProtocol where Element: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { .array }
}

extension Optional: ArgumentProtocol where Wrapped: ArgumentProtocol {
  public static var typeCode: ArgumentTypeCode { Wrapped.typeCode }
}
