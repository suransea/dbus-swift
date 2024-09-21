import CDBus

public class Message {
  var raw: OpaquePointer?

  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  public init(type: MessageType) {
    raw = dbus_message_new(type.rawValue)
  }

  public init(
    methodCall: (busName: BusName, path: ObjectPath, interface: Interface, method: Member)
  ) {
    raw = dbus_message_new_method_call(
      methodCall.busName, methodCall.path, methodCall.interface, methodCall.method)
  }

  public init(methodReturn: Message) {
    raw = dbus_message_new_method_return(methodReturn.raw)
  }

  public init(error: (replyTo: Message, name: ErrorName, message: String)) {
    raw = dbus_message_new_error(error.replyTo.raw, error.name.rawValue, error.message)
  }

  public init(signal: (path: ObjectPath, interface: Interface, name: Member)) {
    raw = dbus_message_new_signal(signal.path, signal.interface, signal.name)
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
      dbus_message_get_path(raw).map(String.init(cString:))
    }
    set {
      dbus_message_set_path(raw, newValue)
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

  public var signature: String {
    String(cString: dbus_message_get_signature(raw))
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
