import CDBus

public class Connection {
  private let raw: OpaquePointer?
  private let isPrivate: Bool

  public init(address: String, private: Bool = false) throws(DBus.Error) {
    let error = DBusError()
    raw =
      if `private` {
        dbus_connection_open_private(address, &error.raw)
      } else {
        dbus_connection_open(address, &error.raw)
      }
    if let error = DBus.Error(error) {
      throw error
    }
    isPrivate = `private`
  }

  public init(type: BusType, private: Bool = false) throws(DBus.Error) {
    let error = DBusError()
    raw =
      if `private` {
        dbus_bus_get_private(DBusBusType(type), &error.raw)
      } else {
        dbus_bus_get(DBusBusType(type), &error.raw)
      }
    if let error = DBus.Error(error) {
      throw error
    }
    isPrivate = `private`
  }

  deinit {
    if isPrivate {
      close()
    }
    dbus_connection_unref(raw)
  }

  public func close() {
    dbus_connection_close(raw)
  }

  public var uniqueName: String {
    String(cString: dbus_bus_get_unique_name(raw))
  }

  public var isConnected: Bool {
    dbus_connection_get_is_connected(raw) != 0
  }

  public var isAuthenticated: Bool {
    dbus_connection_get_is_authenticated(raw) != 0
  }

  public var isAnonymous: Bool {
    dbus_connection_get_is_anonymous(raw) != 0
  }

  public var serverId: String {
    String(cString: dbus_connection_get_server_id(raw))
  }

  public var dispatchStatus: DispatchStatus {
    DispatchStatus(dbus_connection_get_dispatch_status(raw))
  }

  public var hasMessagesToSend: Bool {
    dbus_connection_has_messages_to_send(raw) != 0
  }

  public var maxMessageSize: Int {
    dbus_connection_get_max_message_size(raw)
  }

  public var maxMessageUnixFds: Int {
    dbus_connection_get_max_message_unix_fds(raw)
  }

  public var outgoingSize: Int {
    dbus_connection_get_outgoing_size(raw)
  }

  public var outgoingUnixFds: Int {
    dbus_connection_get_outgoing_unix_fds(raw)
  }

  public var maxReceivedSize: Int {
    dbus_connection_get_max_received_size(raw)
  }

  public var maxReceivedUnixFds: Int {
    dbus_connection_get_max_received_unix_fds(raw)
  }

  public func register() throws(DBus.Error) {
    let error = DBusError()
    dbus_bus_register(raw, &error.raw)
    if let error = DBus.Error(error) {
      throw error
    }
  }

  public func readWrite(timeout: Timeout = .useDefault) -> Bool {
    dbus_connection_read_write(raw, timeout.rawValue) != 0
  }

  public func readWriteDispatch(timeout: Timeout = .useDefault) -> Bool {
    dbus_connection_read_write_dispatch(raw, timeout.rawValue) != 0
  }

  public func dispatch() -> DispatchStatus {
    DispatchStatus(dbus_connection_dispatch(raw))
  }

  public func flush() {
    dbus_connection_flush(raw)
  }

  public func canSend(type: ArgumentTypeCode) -> Bool {
    dbus_connection_can_send_type(raw, type.rawValue) != 0
  }

  public func send(message: Message) -> /* serial: */ UInt32? {
    var serial: UInt32 = 0
    if dbus_connection_send(raw, message.raw, &serial) == 0 {
      return nil
    }
    return serial
  }

  public func sendWithReply(
    message: Message, timeout: Timeout = .useDefault
  ) -> PendingCall? {
    var pendingCall: OpaquePointer?
    if dbus_connection_send_with_reply(raw, message.raw, &pendingCall, timeout.rawValue) == 0 {
      return nil
    }
    return PendingCall(pendingCall!)
  }

  public func sendWithReply(
    message: Message, timeout: Timeout = .useDefault, _ block: @escaping (_ reply: Message?) -> Void
  ) -> Bool {
    let pendingCall = sendWithReply(message: message, timeout: timeout)
    guard let pendingCall = pendingCall else {
      return false
    }
    pendingCall.setNotify {
      block(pendingCall.stealReply())
    }
    return true
  }

  public func sendWithReplyAndBlock(
    message: Message, timeout: Timeout = .useDefault
  ) throws(DBus.Error) -> Message {
    let error = DBusError()
    let reply = dbus_connection_send_with_reply_and_block(
      raw, message.raw, timeout.rawValue, &error.raw)
    if let error = DBus.Error(error) {
      throw error
    }
    return Message(reply!)
  }

  public func popMessage() -> Message? {
    dbus_connection_pop_message(raw).map(Message.init)
  }

  public func borrowingMessage<E, R>(
    _ block: (Message?, _ steal: inout Bool) throws(E) -> R
  ) throws(E) -> R {
    let message = dbus_connection_borrow_message(raw).map(Message.init)
    var steal = false
    let result = try block(message, &steal)
    if steal {
      dbus_connection_steal_borrowed_message(raw, message?.raw)
    } else {
      dbus_connection_return_message(raw, message?.raw)
      message?.raw = nil  // release ownership
    }
    return result
  }
}

public enum DispatchStatus: UInt32 {
  case dataRemains
  case complete
  case needMemory
}

extension DispatchStatus {
  init(_ status: DBusDispatchStatus) {
    self.init(rawValue: status.rawValue)!
  }
}
