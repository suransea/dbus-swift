import CDBus

/// Represents a D-Bus message.
public class Message: @unchecked Sendable {
  /// The raw pointer to the `DBusMessage`.
  var raw: OpaquePointer?

  /// Initializes a `Message` with a raw pointer.
  ///
  /// - Parameter raw: The raw pointer to the `DBusMessage`.
  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  /// Initializes a `Message` with a specific type.
  ///
  /// - Parameter type: The type of the message.
  public init(type: MessageType) {
    raw = dbus_message_new(type.rawValue)
  }

  /// Initializes a method call message.
  ///
  /// - Parameter methodCall: A tuple containing the destination, path, interface, and name.
  public init(
    methodCall: (destination: BusName, path: ObjectPath, interface: InterfaceName, name: MemberName)
  ) {
    raw = dbus_message_new_method_call(
      methodCall.destination.rawValue, methodCall.path.rawValue,
      methodCall.interface.rawValue, methodCall.name.rawValue)
  }

  /// Initializes a method return message.
  ///
  /// - Parameter methodReturn: The message to return.
  public init(methodReturn: Message) {
    raw = dbus_message_new_method_return(methodReturn.raw)
  }

  /// Initializes an error message.
  ///
  /// - Parameter error: A tuple containing the reply-to message, error name, and error message.
  public init(error: (replyTo: Message, name: ErrorName, message: String)) {
    raw = dbus_message_new_error(error.replyTo.raw, error.name.rawValue, error.message)
  }

  /// Initializes a signal message.
  ///
  /// - Parameter signal: A tuple containing the path, interface, and name.
  public init(signal: (path: ObjectPath, interface: InterfaceName, name: MemberName)) {
    raw = dbus_message_new_signal(
      signal.path.rawValue, signal.interface.rawValue, signal.name.rawValue)
  }

  deinit {
    dbus_message_unref(raw)
  }

  /// The type of the message.
  public var type: MessageType {
    MessageType(rawValue: dbus_message_get_type(raw))!
  }

  /// Indicates whether the message expects no reply.
  public var isNoReply: Bool {
    get { dbus_message_get_no_reply(raw) != 0 }
    set { dbus_message_set_no_reply(raw, newValue ? 1 : 0) }
  }

  /// Indicates that an owner for the destination name will
  /// be automatically started before the message is delivered.
  /// When this flag is set, the message is held until a name owner finishes
  /// starting up, or fails to start up. In case of failure, the reply
  /// will be an error.
  public var isAutoStart: Bool {
    get { dbus_message_get_auto_start(raw) != 0 }
    set { dbus_message_set_auto_start(raw, newValue ? 1 : 0) }
  }

  /// The serial number of the message.
  /// The message's serial number is provided by the application sending
  /// the message and is used to identify replies to this message.
  public var serial: UInt32 {
    get { dbus_message_get_serial(raw) }
    set { dbus_message_set_serial(raw, newValue) }
  }

  /// The sender of the message.
  public var sender: BusName? {
    get { dbus_message_get_sender(raw).map(String.init(cString:)).map(BusName.init(rawValue:)) }
    set { dbus_message_set_sender(raw, newValue?.rawValue) }
  }

  /// The destination of the message.
  public var destination: BusName? {
    get {
      dbus_message_get_destination(raw).map(String.init(cString:)).map(BusName.init(rawValue:))
    }
    set {
      dbus_message_set_destination(raw, newValue?.rawValue)
    }
  }

  /// The object path of the message.
  public var path: ObjectPath? {
    get { dbus_message_get_path(raw).map(String.init(cString:)).map(ObjectPath.init(rawValue:)) }
    set { dbus_message_set_path(raw, newValue?.rawValue) }
  }

  /// The interface of the message.
  public var interface: InterfaceName? {
    get {
      dbus_message_get_interface(raw).map(String.init(cString:)).map(InterfaceName.init(rawValue:))
    }
    set {
      dbus_message_set_interface(raw, newValue?.rawValue)
    }
  }

  /// The member name of the message.
  public var member: MemberName? {
    get { dbus_message_get_member(raw).map(String.init(cString:)).map(MemberName.init(rawValue:)) }
    set { dbus_message_set_member(raw, newValue?.rawValue) }
  }

  /// The error name of the message, if any.
  public var errorName: ErrorName? {
    get {
      dbus_message_get_error_name(raw).map(String.init(cString:)).map(ErrorName.init(rawValue:))
    }
    set {
      dbus_message_set_error_name(raw, newValue?.rawValue)
    }
  }

  /// The error associated with the message, if any.
  public var error: DBus.Error? {
    let error = RawError()
    dbus_set_error_from_message(&error.raw, raw)
    return DBus.Error(error)
  }

  /// The signature of the message.
  public var signature: Signature {
    Signature(rawValue: String(cString: dbus_message_get_signature(raw)))
  }

  /// Creates a copy of the message.
  ///
  /// - Returns: A new `Message` instance that is a copy of the original.
  public func copy() -> Message {
    Message(dbus_message_copy(raw))
  }
}

/// Represents the type of a D-Bus message.
public enum MessageType: Int32 {
  /// An invalid message.
  case invalid = 0
  /// A method call message.
  case methodCall = 1
  /// A method return message.
  case methodReturn = 2
  /// An error message.
  case error = 3
  /// A signal message.
  case signal = 4
}

/// Represents a basic value in a D-Bus message.
public typealias BasicValue = DBusBasicValue

/// Represents an iterator for a D-Bus message.
public struct MessageIterator: BitwiseCopyable {
  /// The raw iterator.
  var raw: DBusMessageIter

  /// Initializes a new `MessageIterator`.
  init() {
    raw = DBusMessageIter()
  }

  /// Initializes a `MessageIterator` for reading a message.
  ///
  /// - Parameter message: The message to read.
  public init(reading message: Message) {
    self.init()
    dbus_message_iter_init(message.raw, &raw)
  }

  /// Initializes a `MessageIterator` for appending to a message.
  ///
  /// - Parameter message: The message to append to.
  public init(appending message: Message) {
    self.init()
    dbus_message_iter_init_append(message.raw, &raw)
  }

  /// The current signature.
  public var signature: Signature? {
    mutating get {
      let signature = dbus_message_iter_get_signature(&raw)
      guard let signature else { return nil }
      defer { dbus_free(signature) }
      return Signature(rawValue: String(cString: signature))
    }
  }

  /// The type of the current element.
  /// If the iterator is at the end of the message, returns `invalid`.
  public var argumentType: ArgumentType {
    mutating get {
      ArgumentType(rawValue: dbus_message_iter_get_arg_type(&raw))!
    }
  }

  /// Advances the iterator to the next element.
  ///
  /// - Returns: `true` if the iterator was advanced, `false` otherwise.
  public mutating func next() -> Bool {
    dbus_message_iter_next(&raw) != 0
  }

  /// Checks if the current element has the specified type.
  ///
  /// - Parameter type: The type to check.
  /// - Throws: `DBus.Error` if the argument type does not match.
  public mutating func checkArgumentType(_ type: ArgumentType) throws(DBus.Error) {
    guard argumentType == type else {
      throw .init(
        name: .failed, message: "Expected argument type '\(type)', but got '\(argumentType)'")
    }
  }

  /// Gets the value of the current element as a basic value.
  ///
  /// - Returns: The basic value.
  /// - Throws: `DBus.Error` if the value is not a basic type.
  public mutating func getBasic() throws(DBus.Error) -> BasicValue {
    guard argumentType.isBasic else {
      throw .init(name: .failed, message: "Expected a basic type, but got '\(argumentType)'")
    }
    var value = BasicValue()
    dbus_message_iter_get_basic(&raw, &value)
    return value
  }

  /// Gets the value of the current element as a basic value and advances the iterator.
  ///
  /// - Returns: The basic value.
  /// - Throws: `DBus.Error` if the value is not a basic type.
  public mutating func nextBasic() throws(DBus.Error) -> BasicValue {
    defer { _ = next() }
    return try getBasic()
  }

  /// Recurses into the current container element.
  ///
  /// - Returns: The sub-iterator.
  /// - Throws: `DBus.Error` if the current element is not a container.
  public mutating func recurseContainer() throws(DBus.Error) -> MessageIterator {
    guard argumentType.isContainer else {
      throw .init(name: .failed, message: "Expected a container type, but got '\(argumentType)'")
    }
    var sub = MessageIterator()
    dbus_message_iter_recurse(&raw, &sub.raw)
    return sub
  }

  /// Recurses into the current container element and advances the iterator.
  ///
  /// - Returns: The sub-iterator.
  /// - Throws: `DBus.Error` if the current element is not a container.
  public mutating func nextContainer() throws(DBus.Error) -> MessageIterator {
    defer { _ = next() }
    return try recurseContainer()
  }

  /// Appends a basic value to the message.
  ///
  /// - Parameters:
  ///   - value: The basic value to append.
  ///   - type: The type of the argument.
  /// - Throws: `DBus.Error` if the append operation fails.
  public mutating func append(
    basic value: inout BasicValue, type: ArgumentType
  ) throws(DBus.Error) {
    if dbus_message_iter_append_basic(&raw, type.rawValue, &value) == 0 {
      throw .init(name: .noMemory, message: "Failed to append basic value")
    }
  }

  /// Opens a container element in the message and returns the sub-iterator.
  ///
  /// - Parameters:
  ///   - type: The type of the container, e.g., `struct`, `variant`, `dictEntry`, or `array`.
  ///   - signature: For variants, the `signature` should be the type of the single value inside
  ///     the variant. For structs and dict entries, `signature` should be nil (default value);
  ///     it will be set to whatever types you write into the struct. For arrays, `signature`
  ///     should be the type of the array elements.
  /// - Throws: `DBus.Error` if the open operation fails.
  /// - Returns: The sub-iterator for the container element.
  public mutating func openContainer(
    type: ArgumentType, signature: Signature? = nil
  ) throws(DBus.Error) -> MessageIterator {
    guard type.isContainer else {
      throw .init(name: .failed, message: "Expected a container type, but got '\(type)'")
    }
    var sub = MessageIterator()
    let success =
      dbus_message_iter_open_container(&raw, type.rawValue, signature?.rawValue, &sub.raw) != 0
    guard success else {
      throw .init(name: .noMemory, message: "Failed to open container")
    }
    return sub
  }

  /// Closes a container element in the message.
  ///
  /// - Parameter sub: The `MessageIteror` for the container element.
  /// - Throws: `DBus.Error` if the close operation fails.
  public mutating func closeContainer(_ sub: inout MessageIterator) throws(DBus.Error) {
    if dbus_message_iter_close_container(&raw, &sub.raw) == 0 {
      throw .init(name: .noMemory, message: "Failed to close container")
    }
  }

  /// Abandons a container element in the message.
  ///
  /// - Parameter sub: The `MessageIterator` for the container element.
  public mutating func abandonContainer(_ sub: inout MessageIterator) {
    dbus_message_iter_abandon_container(&raw, &sub.raw)
  }

  /// Abandons a container element in the message if it is open.
  ///
  /// Unlike `abandonContainer()`, it is valid to call this
  /// function on an iterator that was already closed or abandoned.
  /// - Parameter sub: The `MessageIterator` for the container element.
  public mutating func abandonContainerIfOpen(_ sub: inout MessageIterator) {
    dbus_message_iter_abandon_container_if_open(&raw, &sub.raw)
  }

  /// Appends a container element with the specified type and signature.
  ///
  /// This function opens a container, executes the provided block with the sub-iterator,
  /// and then closes the container. If the block throws an error, the container is not closed.
  ///
  /// - Parameters:
  ///   - type: The type of the container, see `openContainer`.
  ///   - signature: The optional signature of the container, see `openContainer`.
  ///   - block: A block to execute with the sub-iterator.
  /// - Throws: `DBus.Error` if opening or closing the container fails, or if the block throws an error.
  /// - Returns: The result of the block execution.
  public mutating func appendContainer<R>(
    type: ArgumentType, signature: Signature? = nil,
    _ block: (inout MessageIterator) throws(DBus.Error) -> R
  ) throws(DBus.Error) -> R {
    var sub = try openContainer(type: type, signature: signature)
    let result = try block(&sub)  // must not close container if block throws an error
    try closeContainer(&sub)
    return result
  }
}
