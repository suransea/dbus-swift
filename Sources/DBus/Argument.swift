import CDBus

/// D-Bus message argument type code.
/// see [D-Bus specification](https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling)
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

/// D-Bus message argument.
public protocol Argument {
  /// The type code of the argument.
  static var typeCode: ArgumentTypeCode { get }
  /// The type signature of the argument.
  static var signature: Signature { get }

  /// Read the argument from the message iterator.
  init(from iter: inout MessageIter)

  /// Append the argument to the message iterator.
  func append(to iter: inout MessageIter) -> Bool
}

extension Argument {
  /// For basic types, the signature is the type code.
  public static var signature: Signature {
    Signature(rawValue: String(UnicodeScalar(UInt32(typeCode.rawValue))!))
  }
}

extension UInt8: Argument {
  public static var typeCode: ArgumentTypeCode { .byte }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().byt
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(byt: self)
    return iter.append(basic: &basicValue, type: .byte)
  }
}

extension Bool: Argument {
  public static var typeCode: ArgumentTypeCode { .boolean }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().bool_val != 0
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(bool_val: self ? 1 : 0)
    return iter.append(basic: &basicValue, type: .boolean)
  }
}

extension Int16: Argument {
  public static var typeCode: ArgumentTypeCode { .int16 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().i16
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(i16: self)
    return iter.append(basic: &basicValue, type: .int16)
  }
}

extension UInt16: Argument {
  public static var typeCode: ArgumentTypeCode { .uint16 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().u16
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(u16: self)
    return iter.append(basic: &basicValue, type: .uint16)
  }
}

extension Int32: Argument {
  public static var typeCode: ArgumentTypeCode { .int32 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().i32
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(i32: self)
    return iter.append(basic: &basicValue, type: .int32)
  }
}

extension UInt32: Argument {
  public static var typeCode: ArgumentTypeCode { .uint32 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().u32
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(u32: self)
    return iter.append(basic: &basicValue, type: .uint32)
  }
}

extension Int64: Argument {
  public static var typeCode: ArgumentTypeCode { .int64 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().i64
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(i64: self)
    return iter.append(basic: &basicValue, type: .int64)
  }
}

extension UInt64: Argument {
  public static var typeCode: ArgumentTypeCode { .uint64 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().u64
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(u64: self)
    return iter.append(basic: &basicValue, type: .uint64)
  }
}

extension Double: Argument {
  public static var typeCode: ArgumentTypeCode { .double }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().dbl
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(dbl: self)
    return iter.append(basic: &basicValue, type: .double)
  }
}

extension String: Argument {
  public static var typeCode: ArgumentTypeCode { .string }

  public init(from iter: inout MessageIter) {
    self = String(cString: iter.getBasic().str)
  }

  public func append(to iter: inout MessageIter) -> Bool {
    withCString { cString in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return iter.append(basic: &basicValue, type: .string)
    }
  }
}

public struct ObjectPath: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension ObjectPath: Argument {
  public static var typeCode: ArgumentTypeCode { .objectPath }

  public init(from iter: inout MessageIter) {
    self.rawValue = String(cString: iter.getBasic().str)
  }

  public func append(to iter: inout MessageIter) -> Bool {
    rawValue.withCString { cString in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return iter.append(basic: &basicValue, type: .objectPath)
    }
  }
}

public struct Signature: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension Signature: Argument {
  public static var typeCode: ArgumentTypeCode { .signature }

  public init(from iter: inout MessageIter) {
    self.rawValue = String(cString: iter.getBasic().str)
  }

  public func append(to iter: inout MessageIter) -> Bool {
    rawValue.withCString { cString in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      return iter.append(basic: &basicValue, type: .signature)
    }
  }
}

public struct FileDescriptor: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }
}

extension FileDescriptor: Argument {
  public static var typeCode: ArgumentTypeCode { .unixFD }

  public init(from iter: inout MessageIter) {
    self.rawValue = iter.getBasic().fd
  }

  public func append(to iter: inout MessageIter) -> Bool {
    var basicValue = DBusBasicValue(fd: self.rawValue)
    return iter.append(basic: &basicValue, type: .unixFD)
  }
}

extension Array: Argument where Element: Argument {
  public static var typeCode: ArgumentTypeCode { .array }

  public init(from iter: inout MessageIter) {
    self = []
    var subIter = iter.iterateRecurse()
    if subIter.argumentType != .invalid {
      append(Element(from: &subIter))
    }
    while subIter.next() {
      append(Element(from: &subIter))
    }
  }

  public func append(to iter: inout MessageIter) -> Bool {
    iter.withContainer(type: .array, signature: Element.signature) { subIter in
      for element in self {
        guard element.append(to: &subIter) else {
          return false
        }
      }
      return true
    }
  }
}

public struct Struct<each T: Argument> {
  public let values: (repeat each T)
}

extension Struct: Argument {
  public static var typeCode: ArgumentTypeCode { .struct }

  public static var signature: Signature {
    var signatures = DBUS_STRUCT_BEGIN_CHAR_AS_STRING
    for signature in repeat (each T).signature {
      signatures += signature.rawValue
    }
    signatures += DBUS_STRUCT_END_CHAR_AS_STRING
    return Signature(rawValue: signatures)
  }

  public init(from iter: inout MessageIter) {
    values = (repeat (each T).init(from: &iter))
  }

  public func append(to iter: inout MessageIter) -> Bool {
    iter.withContainer(type: .struct) { subIter in
      for value in repeat each values {
        guard value.append(to: &subIter) else {
          return false
        }
      }
      return true
    }
  }
}
