import CDBus

public class Message: @unchecked Sendable {
  var raw: OpaquePointer?

  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  public init(type: MessageType) {
    raw = dbus_message_new(type.rawValue)
  }

  public init(
    methodCall: (destination: BusName, path: ObjectPath, interface: Interface, name: Member)
  ) {
    raw = dbus_message_new_method_call(
      methodCall.destination, methodCall.path.rawValue, methodCall.interface, methodCall.name)
  }

  public init(methodReturn: Message) {
    raw = dbus_message_new_method_return(methodReturn.raw)
  }

  public init(error: (replyTo: Message, name: ErrorName, message: String)) {
    raw = dbus_message_new_error(error.replyTo.raw, error.name.rawValue, error.message)
  }

  public init(signal: (path: ObjectPath, interface: Interface, name: Member)) {
    raw = dbus_message_new_signal(signal.path.rawValue, signal.interface, signal.name)
  }

  deinit {
    dbus_message_unref(raw)
  }

  public var type: MessageType {
    MessageType(rawValue: dbus_message_get_type(raw))!
  }

  public var isNoReply: Bool {
    get {
      dbus_message_get_no_reply(raw) != 0
    }
    set {
      dbus_message_set_no_reply(raw, newValue ? 1 : 0)
    }
  }

  public var isAutoStart: Bool {
    get {
      dbus_message_get_auto_start(raw) != 0
    }
    set {
      dbus_message_set_auto_start(raw, newValue ? 1 : 0)
    }
  }

  public var serial: UInt32 {
    get {
      dbus_message_get_serial(raw)
    }
    set {
      dbus_message_set_serial(raw, newValue)
    }
  }

  public var sender: BusName? {
    get {
      dbus_message_get_sender(raw).map(String.init(cString:))
    }
    set {
      dbus_message_set_sender(raw, newValue)
    }
  }

  public var destination: BusName? {
    get {
      dbus_message_get_destination(raw).map(String.init(cString:))
    }
    set {
      dbus_message_set_destination(raw, newValue)
    }
  }

  public var path: ObjectPath? {
    get {
      dbus_message_get_path(raw).map(String.init(cString:)).map(ObjectPath.init)
    }
    set {
      dbus_message_set_path(raw, newValue?.rawValue)
    }
  }

  public var interface: Interface? {
    get {
      dbus_message_get_interface(raw).map(String.init(cString:))
    }
    set {
      dbus_message_set_interface(raw, newValue)
    }
  }

  public var member: Member? {
    get {
      dbus_message_get_member(raw).map(String.init(cString:))
    }
    set {
      dbus_message_set_member(raw, newValue)
    }
  }

  public var errorName: ErrorName? {
    get {
      dbus_message_get_error_name(raw).map(String.init(cString:)).map(ErrorName.init)
    }
    set {
      dbus_message_set_error_name(raw, newValue?.rawValue)
    }
  }

  public var error: DBus.Error? {
    let error = DBusError()
    dbus_set_error_from_message(&error.raw, raw)
    return DBus.Error(error)
  }

  public var signature: Signature {
    Signature(rawValue: String(cString: dbus_message_get_signature(raw)))
  }

  public func copy() -> Message {
    Message(dbus_message_copy(raw))
  }
}

public enum MessageType: Int32 {
  case invalid = 0
  case methodCall = 1
  case methodReturn = 2
  case error = 3
  case signal = 4
}

public struct MessageIter: BitwiseCopyable {
  var raw: DBusMessageIter

  init() {
    raw = DBusMessageIter()
  }

  public init(reading message: Message) {
    self.init()
    dbus_message_iter_init(message.raw, &raw)
  }

  public init(appending message: Message) {
    self.init()
    dbus_message_iter_init_append(message.raw, &raw)
  }

  public var signature: Signature? {
    mutating get {
      dbus_message_iter_get_signature(&raw).map { String(cString: $0) }.map(Signature.init)
    }
  }

  public var argumentType: ArgumentType {
    mutating get {
      ArgumentType(rawValue: dbus_message_iter_get_arg_type(&raw))!
    }
  }

  public mutating func next() -> Bool {
    dbus_message_iter_next(&raw) != 0
  }

  public mutating func getBasic() -> DBusBasicValue {
    var value = DBusBasicValue()
    dbus_message_iter_get_basic(&raw, &value)
    return value
  }

  public mutating func iterateRecurse() -> MessageIter {
    var sub = MessageIter()
    dbus_message_iter_recurse(&raw, &sub.raw)
    return sub
  }

  public mutating func append(
    basic value: inout DBusBasicValue, type: ArgumentType
  ) throws(DBus.Error) {
    if dbus_message_iter_append_basic(&raw, type.rawValue, &value) == 0 {
      throw .init(name: .noMemory, message: "Failed to append basic value")
    }
  }

  public mutating func openContainer(
    type: ArgumentType, signature: Signature? = nil
  ) throws(DBus.Error) -> MessageIter {
    var sub = MessageIter()
    let success =
      dbus_message_iter_open_container(&raw, type.rawValue, signature?.rawValue, &sub.raw) != 0
    guard success else {
      throw .init(name: .noMemory, message: "Failed to open container")
    }
    return sub
  }

  public mutating func closeContainer(_ sub: inout MessageIter) throws(DBus.Error) {
    if dbus_message_iter_close_container(&raw, &sub.raw) == 0 {
      throw .init(name: .noMemory, message: "Failed to close container")
    }
  }

  public mutating func abondonContainer(_ sub: inout MessageIter) {
    dbus_message_iter_abandon_container(&raw, &sub.raw)
  }

  public mutating func abondonContainerIfOpen(_ sub: inout MessageIter) {
    dbus_message_iter_abandon_container_if_open(&raw, &sub.raw)
  }

  public mutating func withContainer<R>(
    type: ArgumentType, signature: Signature? = nil,
    _ block: (inout MessageIter) throws(DBus.Error) -> R
  ) throws(DBus.Error) -> R {
    var sub = try openContainer(type: type, signature: signature)
    let result = try block(&sub)  // must not close container if block throws an error
    try closeContainer(&sub)
    return result
  }
}
