import CDBus

/// D-Bus message argument type.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-marshaling
public enum ArgumentType: Int32 {
  /// Type code that is never equal to a legitimate type code.
  case invalid = 0

  // Primitive types
  /// Type code marking an 8-bit unsigned integer.
  case byte = 121  // 'y'
  /// Type code marking a boolean.
  case boolean = 98  // 'b'
  /// Type code marking a 16-bit signed integer.
  case int16 = 110  // 'n'
  /// Type code marking a 16-bit unsigned integer.
  case uint16 = 113  // 'q'
  /// Type code marking a 32-bit signed integer.
  case int32 = 105  // 'i'
  /// Type code marking a 32-bit unsigned integer.
  case uint32 = 117  // 'u'
  /// Type code marking a 64-bit signed integer.
  case int64 = 120  // 'x'
  /// Type code marking a 64-bit unsigned integer.
  case uint64 = 116  // 't'
  /// Type code marking an 8-byte double in IEEE 754 format.
  case double = 100  // 'd'
  /// Type code marking a UTF-8 encoded, nul-terminated Unicode string.
  case string = 115  // 's'
  /// Type code marking a D-Bus object path.
  case objectPath = 111  // 'o'
  /// Type code marking a D-Bus type signature.
  case signature = 103  // 'g'
  /// Type code marking a Unix file descriptor.
  case unixFD = 104  // 'h'

  // Compound types
  /// Type code marking a D-Bus array type.
  case array = 97  // 'a'
  /// Type code marking a D-Bus variant type.
  case variant = 118  // 'v'

  /// Type code used to represent a struct; however, this type code does not appear
  /// in type signatures. Instead, `DBUS_STRUCT_BEGIN_CHAR` and `DBUS_STRUCT_END_CHAR`
  /// will appear in a signature.
  case `struct` = 114  // 'r'
  /// Type code used to represent a dict entry; however, this type code does not appear
  /// in type signatures. Instead, `DBUS_DICT_ENTRY_BEGIN_CHAR` and `DBUS_DICT_ENTRY_END_CHAR`
  /// will appear in a signature.
  case dictEntry = 101  // 'e'
}

extension ArgumentType {
  /// Indicates if the type is a basic type.
  public var isBasic: Bool {
    dbus_type_is_basic(rawValue) != 0
  }

  /// Indicates if the type is a container type.
  public var isContainer: Bool {
    dbus_type_is_container(rawValue) != 0
  }
}

extension ArgumentType {
  /// The type code character.
  public var stringValue: String {
    String(UnicodeScalar(UInt32(rawValue))!)
  }
}

/// D-Bus message argument.
///
/// It's necessary to implement this protocol for custom types
/// used in D-Bus arguments.
public protocol Argument {
  /// The type of the argument at compile time.
  static var type: ArgumentType { get }
  /// The type signature of the argument at compile time.
  static var signature: Signature { get }

  /// The type of the argument at runtime.
  /// Useful for dynamic types, e.g., `AnyArgument`.
  var type: ArgumentType { get }
  /// The type signature of the argument at runtime.
  /// Useful for dynamic types, e.g., `AnyArgument`.
  var signature: Signature { get }

  /// Reads the argument from the message iterator.
  ///
  /// - Parameter iter: The message iterator to read from.
  /// - Throws: `DBus.Error` if the read operation fails.
  init(from iter: inout MessageIterator) throws(DBus.Error)

  /// Appends the argument to the message iterator.
  ///
  /// - Parameter iter: The message iterator to append to.
  /// - Throws: `DBus.Error` if the append operation fails.
  func append(to iter: inout MessageIterator) throws(DBus.Error)
}

extension Argument {
  /// For basic types, the signature is the type code character.
  public static var signature: Signature {
    .init(rawValue: type.stringValue)
  }

  /// For static types, the runtime type is equal to the compile-time type.
  public var type: ArgumentType { Self.type }

  /// For basic types, the signature is the type code character.
  public var signature: Signature {
    .init(rawValue: type.stringValue)
  }
}

extension Argument {
  /// Casts the argument to the given type.
  ///
  /// Note: The cast operation will marshal and unmarshal the argument, so it may be slow.
  /// - Returns: The argument cast to the given type.
  /// - Throws: `DBus.Error` if the cast operation fails.
  public func cast<T: Argument>() throws(DBus.Error) -> T {
    let message = Message(type: .signal)
    var outIter = MessageIterator(appending: message)
    try append(to: &outIter)
    var inIter = MessageIterator(reading: message)
    return try T(from: &inIter)
  }
}

extension UInt8: Argument {
  public static var type: ArgumentType { .byte }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.byte)
    self = try iter.nextBasic().byt
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(byt: self)
    try iter.append(basic: &basicValue, type: .byte)
  }
}

extension Bool: Argument {
  public static var type: ArgumentType { .boolean }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.boolean)
    self = try iter.nextBasic().bool_val != 0
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(bool_val: self ? 1 : 0)
    try iter.append(basic: &basicValue, type: .boolean)
  }
}

extension Int16: Argument {
  public static var type: ArgumentType { .int16 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.int16)
    self = try iter.nextBasic().i16
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(i16: self)
    try iter.append(basic: &basicValue, type: .int16)
  }
}

extension UInt16: Argument {
  public static var type: ArgumentType { .uint16 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.uint16)
    self = try iter.nextBasic().u16
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(u16: self)
    try iter.append(basic: &basicValue, type: .uint16)
  }
}

extension Int32: Argument {
  public static var type: ArgumentType { .int32 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.int32)
    self = try iter.nextBasic().i32
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(i32: self)
    try iter.append(basic: &basicValue, type: .int32)
  }
}

extension UInt32: Argument {
  public static var type: ArgumentType { .uint32 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.uint32)
    self = try iter.nextBasic().u32
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(u32: self)
    try iter.append(basic: &basicValue, type: .uint32)
  }
}

extension Int64: Argument {
  public static var type: ArgumentType { .int64 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.int64)
    self = try iter.nextBasic().i64
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(i64: self)
    try iter.append(basic: &basicValue, type: .int64)
  }
}

extension UInt64: Argument {
  public static var type: ArgumentType { .uint64 }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.uint64)
    self = try iter.nextBasic().u64
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(u64: self)
    try iter.append(basic: &basicValue, type: .uint64)
  }
}

extension Double: Argument {
  public static var type: ArgumentType { .double }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.double)
    self = try iter.nextBasic().dbl
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(dbl: self)
    try iter.append(basic: &basicValue, type: .double)
  }
}

extension String: Argument {
  public static var type: ArgumentType { .string }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.string)
    self = String(cString: try iter.nextBasic().str)
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    try withCStringTypedThrows { cString throws(DBus.Error) in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      try iter.append(basic: &basicValue, type: .string)
    }
  }
}

/// Argument type signatures.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#type-system
public struct Signature: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension Signature: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.rawValue = value
  }
}

extension Signature: CustomStringConvertible {
  public var description: String { rawValue }
}

extension Signature: Argument {
  public static var type: ArgumentType { .signature }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.signature)
    self.rawValue = String(cString: try iter.nextBasic().str)
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    try rawValue.withCStringTypedThrows { cString throws(DBus.Error) in
      var basicValue = DBusBasicValue(str: UnsafeMutablePointer(mutating: cString))
      try iter.append(basic: &basicValue, type: .signature)
    }
  }
}

extension Signature {
  /// Creates a signature from the given argument types.
  ///
  /// Note: Only for compatibility with older versions of macOS.
  /// Please use `Struct<...>.signature` if targeting macOS 14.0.0 or later.
  /// - Parameter types: The argument types.
  /// - Returns: A signature representing the given argument types.
  public static func `struct`<each T: Argument>(_ types: repeat (each T).Type) -> Signature {
    var signatures = DBUS_STRUCT_BEGIN_CHAR_AS_STRING
    for type in repeat (each T).signature {
      signatures += type.rawValue
    }
    signatures += DBUS_STRUCT_END_CHAR_AS_STRING
    return .init(rawValue: signatures)
  }

  /// Creates a signature from the given arguments.
  ///
  /// Note: Only for compatibility with older versions of macOS.
  /// Please use `Struct(...).signature` if targeting macOS 14.0.0 or later.
  /// - Parameter arguments: The arguments.
  /// - Returns: A signature representing the given arguments.
  public static func `struct`<each T: Argument>(_ arguments: repeat (each T)) -> Signature {
    var signatures = DBUS_STRUCT_BEGIN_CHAR_AS_STRING
    for argument in repeat each arguments {
      signatures += argument.signature.rawValue
    }
    signatures += DBUS_STRUCT_END_CHAR_AS_STRING
    return .init(rawValue: signatures)
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

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.unixFD)
    self.rawValue = try iter.nextBasic().fd
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    var basicValue = DBusBasicValue(fd: self.rawValue)
    try iter.append(basic: &basicValue, type: .unixFD)
  }
}

/// Represents any D-Bus argument.
public struct AnyArgument {
  /// The wrapped value.
  public let value: any Argument

  /// Initializes a new argument with the given value.
  /// - Parameter value: The value to wrap.
  public init(_ value: any Argument) {
    self.value = value
  }
}

extension AnyArgument: Argument {
  public static var type: ArgumentType {
    fatalError("Cannot get the type at compile time for `AnyArgument`.")
  }

  public static var signature: Signature {
    fatalError("Cannot get the signature at compile time for `AnyArgument`.")
  }

  public var type: ArgumentType { value.type }
  public var signature: Signature { value.signature }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    value =
      switch iter.argumentType {
      case .byte: try UInt8(from: &iter)
      case .boolean: try Bool(from: &iter)
      case .int16: try Int16(from: &iter)
      case .uint16: try UInt16(from: &iter)
      case .int32: try Int32(from: &iter)
      case .uint32: try UInt32(from: &iter)
      case .int64: try Int64(from: &iter)
      case .uint64: try UInt64(from: &iter)
      case .double: try Double(from: &iter)
      case .string: try String(from: &iter)
      case .objectPath: try ObjectPath(from: &iter)
      case .signature: try Signature(from: &iter)
      case .unixFD: try FileDescriptor(from: &iter)
      case .array: try [AnyArgument](from: &iter)
      case .variant: try Variant<AnyArgument>(from: &iter)
      case .struct: try AnyStruct(from: &iter)
      case .dictEntry: try DictEntry<AnyArgument, AnyArgument>(from: &iter)
      case .invalid: fatalError("Invalid argument type")
      }
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try value.append(to: &iter)
  }
}

extension Array: Argument where Element: Argument {
  public static var type: ArgumentType { .array }

  public static var signature: Signature {
    .init(rawValue: type.stringValue + Element.signature.rawValue)
  }

  public var signature: Signature {
    if isEmpty {
      Self.signature
    } else {
      .init(rawValue: type.stringValue + self[0].signature.rawValue)
    }
  }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.array)
    self.init()
    var subIter = try iter.nextContainer()
    while subIter.argumentType != .invalid {
      append(try Element(from: &subIter))
    }
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    // If the array is not empty, use the first element's signature.
    let signature = isEmpty ? Element.signature : self[0].signature
    try iter.appendContainer(type: .array, signature: signature) { subIter throws(DBus.Error) in
      for element in self {
        try element.append(to: &subIter)
      }
    }
  }
}

/// Represents a D-Bus variant type.
public struct Variant<T: Argument> {
  /// The wrapped value.
  public let value: T

  /// Initializes a new variant with the given value.
  ///
  /// - Parameter value: The value to wrap.
  public init(_ value: T) {
    self.value = value
  }
}

extension Variant: Argument {
  public static var type: ArgumentType { .variant }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.variant)
    var subIter = try iter.nextContainer()
    value = try T(from: &subIter)
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    try iter.appendContainer(
      type: .variant, signature: value.signature
    ) { subIter throws(DBus.Error) in
      try value.append(to: &subIter)
    }
  }
}

/// Represents a D-Bus struct type.
///
/// Note: This type is available only on macOS 14.0.0 or later,
/// because "parameter packs in generic types" cannot be back-deployed.
/// As a workaround, you can use `AnyStruct` or a custom struct that implements `Argument` instead.
@available(macOS 14.0.0, *)
public struct Struct<each T: Argument> {
  /// The values of the struct.
  public let values: (repeat each T)

  /// Initializes a new struct with the given values.
  /// - Parameter values: The values of the struct.
  public init(_ values: repeat each T) {
    self.values = (repeat each values)
  }

  /// Initializes a new struct with the given values.
  /// - Parameter values: The values of the struct.
  public init(values: (repeat each T)) {
    self.values = values
  }
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
    return .init(rawValue: signatures)
  }

  public var signature: Signature {
    var signatures = DBUS_STRUCT_BEGIN_CHAR_AS_STRING
    for value in repeat each values {
      signatures += value.signature.rawValue
    }
    signatures += DBUS_STRUCT_END_CHAR_AS_STRING
    return .init(rawValue: signatures)
  }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.struct)
    var subIter = try iter.nextContainer()
    values = (repeat try (each T).init(from: &subIter))
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    try iter.appendContainer(type: .struct) { subIter throws(DBus.Error) in
      for value in repeat each values {
        try value.append(to: &subIter)
      }
    }
  }
}

/// Represents any D-Bus struct type.
public struct AnyStruct {
  /// The values of the struct.
  public let values: [any Argument]

  /// Initializes a new struct with the given values.
  /// - Parameter values: The values of the struct.
  public init(_ values: any Argument...) {
    self.values = values
  }
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
    return .init(rawValue: signatures)
  }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.struct)
    var subIter = try iter.nextContainer()
    values = try [AnyArgument](from: &subIter).map(\.value)
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    try iter.appendContainer(type: .struct) { subIter throws(DBus.Error) in
      for value in values {
        try value.append(to: &subIter)
      }
    }
  }
}

/// Represents a dictionary entry with a key and value.
public struct DictEntry<K: Argument, V: Argument> {
  /// The key of the entry.
  public let key: K
  /// The value of the entry.
  public let value: V

  /// Initializes a new dictionary entry with the given key and value.
  /// - Parameters:
  ///   - key: The key of the entry.
  ///   - value: The value of the entry.
  public init(key: K, value: V) {
    self.key = key
    self.value = value
  }
}

extension DictEntry: Argument {
  public static var type: ArgumentType { .dictEntry }

  public static var signature: Signature {
    let signatures =
      DBUS_DICT_ENTRY_BEGIN_CHAR_AS_STRING + K.signature.rawValue + V.signature.rawValue
      + DBUS_DICT_ENTRY_END_CHAR_AS_STRING
    return .init(rawValue: signatures)
  }

  public var signature: Signature {
    let signatures =
      DBUS_DICT_ENTRY_BEGIN_CHAR_AS_STRING + key.signature.rawValue + value.signature.rawValue
      + DBUS_DICT_ENTRY_END_CHAR_AS_STRING
    return .init(rawValue: signatures)
  }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    try iter.checkArgumentType(.dictEntry)
    var subIter = try iter.nextContainer()
    key = try K(from: &subIter)
    value = try V(from: &subIter)
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    try iter.appendContainer(type: .dictEntry) { subIter throws(DBus.Error) in
      try key.append(to: &subIter)
      try value.append(to: &subIter)
    }
  }
}

extension Dictionary: Argument where Key: Argument, Value: Argument {
  public static var type: ArgumentType { .array }

  public static var signature: Signature {
    .init(rawValue: type.stringValue + DictEntry<Key, Value>.signature.rawValue)
  }

  public var signature: Signature {
    if isEmpty {
      return Self.signature
    }
    let (key, value) = first!
    return .init(rawValue: type.stringValue + DictEntry(key: key, value: value).signature.rawValue)
  }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    let entries = try [DictEntry<Key, Value>](from: &iter)
    self.init()
    for entry in entries {
      self[entry.key] = entry.value
    }
  }

  public func append(to iter: inout MessageIterator) throws(DBus.Error) {
    try map { (key, value) in DictEntry(key: key, value: value) }.append(to: &iter)
  }
}

extension String {
  /// A workaround for the lack of `withCString` that throws typed errors.
  ///
  /// - Parameters:
  ///   - block: The block to execute with the C string.
  /// - Throws: An error of type `E`.
  /// - Returns: The result of the block.
  func withCStringTypedThrows<E, R>(_ block: (UnsafePointer<Int8>) throws(E) -> R) throws(E) -> R {
    try withCString { cString in
      Result { () throws(E) -> R in
        try block(cString)
      }
    }.get()
  }
}
