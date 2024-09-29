import CDBus

/// D-Bus message argument type, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling
public enum ArgumentType: Int32 {
  /// Type code that is never equal to a legitimate type code
  case invalid = 0

  // Primitive types
  /// Type code marking an 8-bit unsigned integer
  case byte = 121  // 'y'
  /// Type code marking a boolean
  case boolean = 98  // 'b'
  /// Type code marking a 16-bit signed integer
  case int16 = 110  // 'n'
  /// Type code marking a 16-bit unsigned integer
  case uint16 = 113  // 'q'
  /// Type code marking a 32-bit signed integer
  case int32 = 105  // 'i'
  /// Type code marking a 32-bit unsigned integer
  case uint32 = 117  // 'u'
  /// Type code marking a 64-bit signed integer
  case int64 = 120  // 'x'
  /// Type code marking a 64-bit unsigned integer
  case uint64 = 116  // 't'
  /// Type code marking an 8-byte double in IEEE 754 format
  case double = 100  // 'd'
  /// Type code marking a UTF-8 encoded, nul-terminated Unicode string
  case string = 115  // 's'
  /// Type code marking a D-Bus object path
  case objectPath = 111  // 'o'
  /// Type code marking a D-Bus type signature
  case signature = 103  // 'g'
  /// Type code marking a unix file descriptor
  case unixFD = 104  // 'h'

  // Compound types
  /// Type code marking a D-Bus array type
  case array = 97  // 'a'
  /// Type code marking a D-Bus variant type
  case variant = 118  // 'v'

  /// STRUCT and DICT_ENTRY are sort of special since their codes can't
  /// appear in a type string, instead
  /// `DBUS_STRUCT_BEGIN_CHAR/DBUS_DICT_ENTRY_BEGIN_CHAR` have to appear
  /// Type code used to represent a struct; however, this type code does not appear
  /// in type signatures, instead `DBUS_STRUCT_BEGIN_CHAR` and `DBUS_STRUCT_END_CHAR` will
  /// appear in a signature.
  case `struct` = 114  // 'r'
  /// Type code used to represent a dict entry; however, this type code does not appear
  /// in type signatures, instead `DBUS_DICT_ENTRY_BEGIN_CHAR` and `DBUS_DICT_ENTRY_END_CHAR` will
  /// appear in a signature.
  case dictEntry = 101  // 'e'
}

extension ArgumentType {
  /// If the type is a basic type.
  public var isBasic: Bool {
    dbus_type_is_basic(rawValue) != 0
  }

  /// If the type is a container type.
  public var isContainer: Bool {
    dbus_type_is_container(rawValue) != 0
  }
}

/// D-Bus message argument.
///
/// It's necessary to implement this protocol for custom types,
/// which using in D-Bus method arguments/returns.
public protocol Argument {
  /// The type of the argument, at compile time.
  static var type: ArgumentType { get }
  /// The type signature of the argument, at compile time.
  static var signature: Signature { get }

  /// The type of the argument, at runtime.
  /// It's useful for dynamic types, eg. `AnyArgument`.
  var type: ArgumentType { get }
  /// The type signature of the argument, at runtime.
  /// It's useful for dynamic types, eg. `AnyArgument`.
  var signature: Signature { get }

  /// Read the argument from the message iterator.
  ///
  /// Parameter iter: The message iterator to read from.
  init(from iter: inout MessageIter)

  /// Append the argument to the message iterator.
  ///
  /// Parameter iter: The message iterator to append to.
  func append(to iter: inout MessageIter) throws(DBus.Error)
}

extension Argument {
  /// For basic types, the signature is the type code character.
  public static var signature: Signature {
    .init(rawValue: String(UnicodeScalar(UInt32(type.rawValue))!))
  }
  /// For static types, the runtime type is equal to the compile-time type.
  public var type: ArgumentType { Self.type }
  /// For basic types, the signature is the type code character.
  public var signature: Signature {
    .init(rawValue: String(UnicodeScalar(UInt32(self.type.rawValue))!))
  }
}

extension UInt8: Argument {
  public static var type: ArgumentType { .byte }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().byt
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(byt: self)
    try iter.append(basic: &basicValue, type: .byte)
  }
}

extension Bool: Argument {
  public static var type: ArgumentType { .boolean }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().bool_val != 0
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(bool_val: self ? 1 : 0)
    try iter.append(basic: &basicValue, type: .boolean)
  }
}

extension Int16: Argument {
  public static var type: ArgumentType { .int16 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().i16
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(i16: self)
    try iter.append(basic: &basicValue, type: .int16)
  }
}

extension UInt16: Argument {
  public static var type: ArgumentType { .uint16 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().u16
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(u16: self)
    try iter.append(basic: &basicValue, type: .uint16)
  }
}

extension Int32: Argument {
  public static var type: ArgumentType { .int32 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().i32
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(i32: self)
    try iter.append(basic: &basicValue, type: .int32)
  }
}

extension UInt32: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().u32
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(u32: self)
    try iter.append(basic: &basicValue, type: .uint32)
  }
}

extension Int64: Argument {
  public static var type: ArgumentType { .int64 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().i64
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(i64: self)
    try iter.append(basic: &basicValue, type: .int64)
  }
}

extension UInt64: Argument {
  public static var type: ArgumentType { .uint64 }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().u64
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(u64: self)
    try iter.append(basic: &basicValue, type: .uint64)
  }
}

extension Double: Argument {
  public static var type: ArgumentType { .double }

  public init(from iter: inout MessageIter) {
    self = iter.getBasic().dbl
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(dbl: self)
    try iter.append(basic: &basicValue, type: .double)
  }
}

extension String: Argument {
  public static var type: ArgumentType { .string }

  public init(from iter: inout MessageIter) {
    self = String(cString: iter.getBasic().str)
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try withCStringTypedThrows { cString throws(DBus.Error) in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      try iter.append(basic: &basicValue, type: .string)
    }
  }
}

/// D-Bus object path, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling-object-path
public struct ObjectPath: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension ObjectPath: Argument {
  public static var type: ArgumentType { .objectPath }

  public init(from iter: inout MessageIter) {
    self.rawValue = String(cString: iter.getBasic().str)
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try rawValue.withCStringTypedThrows { cString throws(DBus.Error) in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      try iter.append(basic: &basicValue, type: .objectPath)
    }
  }
}

/// D-Bus type signature, see https://dbus.freedesktop.org/doc/dbus-specification.html#type-system
public struct Signature: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension Signature: Argument {
  public static var type: ArgumentType { .signature }

  public init(from iter: inout MessageIter) {
    self.rawValue = String(cString: iter.getBasic().str)
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try rawValue.withCStringTypedThrows { cString throws(DBus.Error) in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      try iter.append(basic: &basicValue, type: .signature)
    }
  }
}

/// Unix file descriptor.
public struct FileDescriptor: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }
}

extension FileDescriptor: Argument {
  public static var type: ArgumentType { .unixFD }

  public init(from iter: inout MessageIter) {
    self.rawValue = iter.getBasic().fd
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    var basicValue = DBusBasicValue(fd: self.rawValue)
    try iter.append(basic: &basicValue, type: .unixFD)
  }
}

public struct AnyArgument {
  public let value: any Argument
}

extension AnyArgument: Argument {
  public static var type: ArgumentType {
    fatalError("Cannot get type at compile time for `AnyArgument`")
  }
  public static var signature: Signature {
    fatalError("Cannot get signature at compile time for `AnyArgument`")
  }
  public var type: ArgumentType { value.type }
  public var signature: Signature { value.signature }

  public init(from iter: inout MessageIter) {
    value =
      switch iter.argumentType {
      case .byte: UInt8(from: &iter)
      case .boolean: Bool(from: &iter)
      case .int16: Int16(from: &iter)
      case .uint16: UInt16(from: &iter)
      case .int32: Int32(from: &iter)
      case .uint32: UInt32(from: &iter)
      case .int64: Int64(from: &iter)
      case .uint64: UInt64(from: &iter)
      case .double: Double(from: &iter)
      case .string: String(from: &iter)
      case .objectPath: ObjectPath(from: &iter)
      case .signature: Signature(from: &iter)
      case .unixFD: FileDescriptor(from: &iter)
      case .array: [AnyArgument](from: &iter)
      case .variant: Variant<AnyArgument>(from: &iter)
      case .struct: AnyStruct(from: &iter)
      case .dictEntry: DictEntry<AnyArgument, AnyArgument>(from: &iter)
      case .invalid: fatalError("Invalid argument type")
      }
  }

  public func append(to iter: inout MessageIter) throws(Error) {
    try value.append(to: &iter)
  }
}

extension Array: Argument where Element: Argument {
  public static var type: ArgumentType { .array }

  public init(from iter: inout MessageIter) {
    self.init()
    var subIter = iter.iterateRecurse()
    if subIter.argumentType != .invalid {
      append(Element(from: &subIter))
    }
    while subIter.next() {
      append(Element(from: &subIter))
    }
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    // If the array is not empty, use the first element's signature.
    let signature = isEmpty ? Element.signature : self[0].signature
    try iter.withContainer(type: .array, signature: signature) { subIter throws(DBus.Error) in
      for element in self {
        try element.append(to: &subIter)
      }
    }
  }
}

public struct Variant<T: Argument> {
  public let value: T
}

extension Variant: Argument {
  public static var type: ArgumentType { .variant }

  public init(from iter: inout MessageIter) {
    var subIter = iter.iterateRecurse()
    value = T(from: &subIter)
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try iter.withContainer(
      type: .variant, signature: value.signature
    ) { subIter throws(DBus.Error) in
      try value.append(to: &subIter)
    }
  }
}

@available(macOS 14.0.0, *)
public struct Struct<each T: Argument> {
  public let values: (repeat each T)
}

@available(macOS 14.0.0, *)
extension Struct: Argument {
  public static var type: ArgumentType { .struct }

  public static var signature: Signature {
    var signatures = DBUS_STRUCT_BEGIN_CHAR_AS_STRING
    for signature in repeat (each T).signature {
      signatures += signature.rawValue
    }
    signatures += DBUS_STRUCT_END_CHAR_AS_STRING
    return Signature(rawValue: signatures)
  }

  public init(from iter: inout MessageIter) {
    var subIter = iter.iterateRecurse()
    var first = true
    func nextValue<V: Argument>() -> V {
      if first {
        first = false
      } else {
        _ = subIter.next()
      }
      return V(from: &subIter)
    }
    values = (repeat nextValue() as each T)
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try iter.withContainer(type: .struct) { subIter throws(DBus.Error) in
      for value in repeat each values {
        try value.append(to: &subIter)
      }
    }
  }
}

public struct AnyStruct {
  public let values: [AnyArgument]
}

extension AnyStruct: Argument {
  public static var type: ArgumentType { .struct }
  public static var signature: Signature {
    fatalError("Cannot get signature at compile time for `AnyStruct`")
  }
  public var signature: Signature {
    var signatures = DBUS_STRUCT_BEGIN_CHAR_AS_STRING
    for value in values {
      signatures += value.signature.rawValue
    }
    signatures += DBUS_STRUCT_END_CHAR_AS_STRING
    return Signature(rawValue: signatures)
  }

  public init(from iter: inout MessageIter) {
    var subIter = iter.iterateRecurse()
    values = [AnyArgument](from: &subIter)
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try iter.withContainer(type: .struct) { subIter throws(DBus.Error) in
      for value in values {
        try value.append(to: &subIter)
      }
    }
  }
}

public struct DictEntry<K: Argument, V: Argument> {
  public let key: K
  public let value: V
}

extension DictEntry: Argument {
  public static var type: ArgumentType { .dictEntry }

  public static var signature: Signature {
    let signatures =
      DBUS_DICT_ENTRY_BEGIN_CHAR_AS_STRING
      + K.signature.rawValue + V.signature.rawValue
      + DBUS_DICT_ENTRY_END_CHAR_AS_STRING
    return Signature(rawValue: signatures)
  }

  public var signature: Signature {
    let signatures =
      DBUS_DICT_ENTRY_BEGIN_CHAR_AS_STRING
      + key.signature.rawValue + value.signature.rawValue
      + DBUS_DICT_ENTRY_END_CHAR_AS_STRING
    return Signature(rawValue: signatures)
  }

  public init(from iter: inout MessageIter) {
    var subIter = iter.iterateRecurse()
    key = K(from: &subIter)
    _ = subIter.next()
    value = V(from: &subIter)
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try iter.withContainer(type: .dictEntry) { subIter throws(DBus.Error) in
      try key.append(to: &subIter)
      try value.append(to: &subIter)
    }
  }
}

extension Dictionary: Argument where Key: Argument, Value: Argument {
  public static var type: ArgumentType { .array }

  public init(from iter: inout MessageIter) {
    self.init()
    let entries = [DictEntry<Key, Value>](from: &iter)
    for entry in entries {
      self[entry.key] = entry.value
    }
  }

  public func append(to iter: inout MessageIter) throws(DBus.Error) {
    try map { (key, value) in DictEntry(key: key, value: value) }.append(to: &iter)
  }
}

extension String {
  /// A workaround for the lack of `withCString` that throws typed.
  func withCStringTypedThrows<E, R>(_ block: (UnsafePointer<Int8>) throws(E) -> R) throws(E) -> R {
    try withCString { cString in
      Result { () throws(E) -> R in
        try block(cString)
      }
    }.get()
  }
}
