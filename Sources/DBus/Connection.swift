import CDBus

public class Connection: @unchecked Sendable {
  private let raw: OpaquePointer?
  private let isPrivate: Bool

  public init(address: String, private: Bool = false) throws(DBus.Error) {
    let error = RawError()
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
    let error = RawError()
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

  public var userId: UInt? {
    var uid: UInt = 0
    if dbus_connection_get_unix_user(raw, &uid) == 0 {
      return nil
    }
    return uid
  }

  public var dispatchStatus: DispatchStatus {
    DispatchStatus(dbus_connection_get_dispatch_status(raw))
  }

  public var hasMessagesToSend: Bool {
    dbus_connection_has_messages_to_send(raw) != 0
  }

  public var maxMessageSize: Int {
    get { dbus_connection_get_max_message_size(raw) }
    set { dbus_connection_set_max_message_size(raw, newValue) }
  }

  public var maxMessageFileDescriptors: Int {
    get { dbus_connection_get_max_message_unix_fds(raw) }
    set { dbus_connection_set_max_message_unix_fds(raw, newValue) }
  }

  public var maxReceivedSize: Int {
    get { dbus_connection_get_max_received_size(raw) }
    set { dbus_connection_set_max_received_size(raw, newValue) }
  }

  public var maxReceivedFileDescriptors: Int {
    get { dbus_connection_get_max_received_unix_fds(raw) }
    set { dbus_connection_set_max_received_unix_fds(raw, newValue) }
  }

  public var outgoingSize: Int {
    dbus_connection_get_outgoing_size(raw)
  }

  public var outgoingFileDescriptors: Int {
    dbus_connection_get_outgoing_unix_fds(raw)
  }

  public func setExitOnDisconnect(_ value: Bool) {
    dbus_connection_set_exit_on_disconnect(raw, value ? 1 : 0)
  }

  public func setAllowAnonymous(_ value: Bool) {
    dbus_connection_set_allow_anonymous(raw, value ? 1 : 0)
  }

  public func close() {
    dbus_connection_close(raw)
  }

  public func register() throws(DBus.Error) {
    let error = RawError()
    dbus_bus_register(raw, &error.raw)
    if let error = DBus.Error(error) {
      throw error
    }
  }

  public func readWrite(timeout: TimeoutInterval = .useDefault) -> Bool {
    dbus_connection_read_write(raw, timeout.rawValue) != 0
  }

  public func readWriteDispatch(timeout: TimeoutInterval = .useDefault) -> Bool {
    dbus_connection_read_write_dispatch(raw, timeout.rawValue) != 0
  }

  public func dispatch() -> DispatchStatus {
    DispatchStatus(dbus_connection_dispatch(raw))
  }

  public func flush() {
    dbus_connection_flush(raw)
  }

  public func canSend(type: ArgumentType) -> Bool {
    dbus_connection_can_send_type(raw, type.rawValue) != 0
  }

  public func send(message: Message) throws(DBus.Error) -> /* serial: */ UInt32 {
    var serial: UInt32 = 0
    if dbus_connection_send(raw, message.raw, &serial) == 0 {
      throw .init(name: .noMemory, message: "Failed to send message")
    }
    return serial
  }

  public func sendWithReply(
    message: Message, timeout: TimeoutInterval = .useDefault
  ) throws(DBus.Error) -> PendingCall {
    var pendingCall: OpaquePointer?
    if dbus_connection_send_with_reply(raw, message.raw, &pendingCall, timeout.rawValue) == 0 {
      throw .init(name: .noMemory, message: "Failed to send message with reply")
    }
    guard let pendingCall = pendingCall else {
      throw .init(
        name: .failed,
        message:
          "Connection is disconnected or send Unix file descriptors on a connection that does not support"
      )
    }
    return PendingCall(pendingCall)
  }

  public func sendWithReply(
    message: Message, timeout: TimeoutInterval = .useDefault,
    completion: @escaping (Result<Message, DBus.Error>) -> Void
  ) throws(DBus.Error) {
    let pendingCall = try sendWithReply(message: message, timeout: timeout)
    try pendingCall.setCompletionHandler {
      let reply = pendingCall.stealReply()!  // must not be nil if the call is complete
      if let error = reply.error {
        completion(.failure(error))
      } else {
        completion(.success(reply))
      }
    }
  }

  @available(macOS 10.15.0, *)
  public func sendWithReply(
    message: Message, timeout: TimeoutInterval = .useDefault
  ) async throws(DBus.Error) -> Message {
    let result = await withCheckedContinuation { continuation in
      do {
        try sendWithReply(message: message, timeout: timeout) { reply in
          continuation.resume(returning: reply)
        }
      } catch {
        continuation.resume(returning: Result.failure(error as! DBus.Error))
      }
    }
    return try result.get()
  }

  public func sendWithReplyAndBlock(
    message: Message, timeout: TimeoutInterval = .useDefault
  ) throws(DBus.Error) -> Message {
    let error = RawError()
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

  public func withBorrowedMessage<E, R>(
    _ block: (Message?, _ consumed: inout Bool) throws(E) -> R
  ) throws(E) -> R {
    let message = dbus_connection_borrow_message(raw).map(Message.init)
    var consumed = false
    guard let message else {
      return try block(nil, &consumed)
    }
    defer {
      if consumed {
        dbus_connection_steal_borrowed_message(raw, message.raw)
      } else {
        dbus_connection_return_message(raw, message.raw)
        message.raw = nil  // release ownership
      }
    }
    return try block(message, &consumed)
  }

  public func setWatchDelegate(_ delegate: any WatchDelegate) -> Bool {
    let userData = Unmanaged.passRetained(delegate as AnyObject).toOpaque()
    return dbus_connection_set_watch_functions(
      raw,
      { watch, userData in
        let delegate =
          Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue() as! WatchDelegate
        return delegate.add(watch: Watch(watch!)) ? 1 : 0
      },
      { watch, userData in
        let delegate =
          Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue() as! WatchDelegate
        delegate.remove(watch: Watch(watch!))
      },
      { watch, userData in
        let delegate =
          Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue() as! WatchDelegate
        delegate.onToggled(watch: Watch(watch!))
      },
      userData,
      { userData in
        Unmanaged<AnyObject>.fromOpaque(userData!).release()
      }) != 0
  }

  public func setTimeoutDelegate(_ delegate: any TimeoutDelegate) -> Bool {
    let userData = Unmanaged.passRetained(delegate as AnyObject).toOpaque()
    return dbus_connection_set_timeout_functions(
      raw,
      { timeout, userData in
        let delegate =
          Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue() as! TimeoutDelegate
        return delegate.add(timeout: Timeout(timeout!)) ? 1 : 0
      },
      { timeout, userData in
        let delegate =
          Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue() as! TimeoutDelegate
        delegate.remove(timeout: Timeout(timeout!))
      },
      { timeout, userData in
        let delegate =
          Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue() as! TimeoutDelegate
        delegate.onToggled(timeout: Timeout(timeout!))
      },
      userData,
      { userData in
        Unmanaged<AnyObject>.fromOpaque(userData!).release()
      }) != 0
  }

  public func setDispatchStatusHandler(_ handler: @escaping (DispatchStatus) -> Void) {
    let userData = Unmanaged.passRetained(handler as AnyObject).toOpaque()
    dbus_connection_set_dispatch_status_function(
      raw,
      { connection, status, userData in
        let callback = Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue()
        (callback as! (DispatchStatus) -> Void)(DispatchStatus(status))
      },
      userData,
      { userData in
        Unmanaged<AnyObject>.fromOpaque(userData!).release()
      })
  }

  public func setWakeUpHandler(_ handler: @escaping () -> Void) {
    let userData = Unmanaged.passRetained(handler as AnyObject).toOpaque()
    dbus_connection_set_wakeup_main_function(
      raw,
      { userData in
        let callback = Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue()
        (callback as! () -> Void)()
      },
      userData,
      { userData in
        Unmanaged<AnyObject>.fromOpaque(userData!).release()
      })
  }
}
