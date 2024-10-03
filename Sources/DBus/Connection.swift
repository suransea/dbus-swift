import CDBus
import Foundation

/// Represents a connection to a remote application and associated
/// incoming/outgoing message queues.
public class Connection: @unchecked Sendable {
  private let raw: OpaquePointer?
  private let isPrivate: Bool

  /// Initializes a new connection to the D-Bus message bus system using an address.
  /// - Parameters:
  ///   - address: The address of the D-Bus message bus.
  ///   - private: Whether the connection should be private.
  /// - Throws: `DBus.Error` if the connection could not be established.
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

  /// Initializes a new connection to the D-Bus message bus system using a bus type.
  /// - Parameters:
  ///   - type: The type of the D-Bus message bus.
  ///   - private: Whether the connection should be private.
  /// - Throws: `DBus.Error` if the connection could not be established.
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
    if isPrivate {  // Shouldn't close shared connections
      close()
    }
    dbus_connection_unref(raw)
  }

  /// The unique name of the connection as assigned by the message bus.
  public var uniqueName: String {
    String(cString: dbus_bus_get_unique_name(raw))
  }

  /// Indicates whether the connection is currently open. A connection may
  /// become disconnected when the remote application closes its end or
  /// exits; a connection may also be disconnected with `close()`.
  public var isConnected: Bool {
    dbus_connection_get_is_connected(raw) != 0
  }

  /// Indicates whether the connection was authenticated.
  ///
  /// Note: If the connection was authenticated then disconnected,
  /// this property will still return `true`.
  public var isAuthenticated: Bool {
    dbus_connection_get_is_authenticated(raw) != 0
  }

  /// Indicates whether the connection is not authenticated as a specific
  /// user. If the connection is not authenticated, this property
  /// returns `true`, and if it is authenticated but as an anonymous user,
  /// it returns `true`. If it is authenticated as a specific user, then
  /// this returns `false`.
  ///
  /// Note: If the connection was authenticated
  /// as anonymous then disconnected, this property still returns `true`.
  public var isAnonymous: Bool {
    dbus_connection_get_is_anonymous(raw) != 0
  }

  /// The ID of the server address we are authenticated to.
  public var serverId: String {
    String(cString: dbus_connection_get_server_id(raw))
  }

  /// The UNIX user ID of the connection if known.
  public var userId: UInt? {
    var uid: UInt = 0
    if dbus_connection_get_unix_user(raw, &uid) == 0 {
      return nil
    }
    return uid
  }

  /// The current state of the incoming message queue.
  public var dispatchStatus: DispatchStatus {
    DispatchStatus(dbus_connection_get_dispatch_status(raw))
  }

  /// Indicates whether there are messages in the outgoing message queue.
  public var hasMessagesToSend: Bool {
    dbus_connection_has_messages_to_send(raw) != 0
  }

  /// The maximum size message this connection is allowed to
  /// receive. Larger messages will result in disconnecting the
  /// connection.
  public var maxMessageSize: Int {
    get { dbus_connection_get_max_message_size(raw) }
    set { dbus_connection_set_max_message_size(raw, newValue) }
  }

  /// The maximum number of UNIX file descriptors a message on this
  /// connection is allowed to receive. Messages with more UNIX file
  /// descriptors will result in disconnecting the connection.
  public var maxMessageFileDescriptors: Int {
    get { dbus_connection_get_max_message_unix_fds(raw) }
    set { dbus_connection_set_max_message_unix_fds(raw, newValue) }
  }

  /// The maximum total number of bytes that can be used for all messages
  /// received on this connection. Messages count toward the maximum until
  /// they are finalized. When the maximum is reached, the connection will
  /// not read more data until some messages are finalized.
  public var maxReceivedSize: Int {
    get { dbus_connection_get_max_received_size(raw) }
    set { dbus_connection_set_max_received_size(raw, newValue) }
  }

  /// The maximum total number of UNIX file descriptors that can be used
  /// for all messages received on this connection. Messages count toward
  /// the maximum until they are finalized. When the maximum is reached,
  /// the connection will not read more data until some messages are
  /// finalized.
  public var maxReceivedFileDescriptors: Int {
    get { dbus_connection_get_max_received_unix_fds(raw) }
    set { dbus_connection_set_max_received_unix_fds(raw, newValue) }
  }

  /// The approximate size in bytes of all messages in the outgoing
  /// message queue. The size is approximate in that you shouldn't use
  /// it to decide how many bytes to read off the network or anything
  /// of that nature, as optimizations may choose to tell small white lies
  /// to avoid performance overhead.
  public var outgoingSize: Int {
    dbus_connection_get_outgoing_size(raw)
  }

  /// The approximate number of UNIX file descriptors of all messages in the
  /// outgoing message queue.
  public var outgoingFileDescriptors: Int {
    dbus_connection_get_outgoing_unix_fds(raw)
  }

  /// Sets whether the connection should exit on disconnect.
  /// - Parameter value: `true` to exit on disconnect, `false` otherwise.
  public func setExitOnDisconnect(_ value: Bool) {
    dbus_connection_set_exit_on_disconnect(raw, value ? 1 : 0)
  }

  /// Sets whether the connection can proceed even if
  /// the client does not authenticate as some user identity, i.e., clients
  /// can connect anonymously.
  /// - Parameter value: `true` to allow anonymous connect, `false` otherwise.
  public func setAllowAnonymous(_ value: Bool) {
    dbus_connection_set_allow_anonymous(raw, value ? 1 : 0)
  }

  /// Closes a private connection, so no further data can be sent or received.
  /// This disconnects the transport (such as a socket) underlying the
  /// connection.
  public func close() {
    dbus_connection_close(raw)
  }

  /// Registers a connection with the bus.
  ///
  /// Note: Shared (not private) connections are automatically registered
  /// with the bus.
  /// - Throws: `DBus.Error` if the registration fails.
  public func register() throws(DBus.Error) {
    let error = RawError()
    dbus_bus_register(raw, &error.raw)
    if let error = DBus.Error(error) {
      throw error
    }
  }

  /// Reads and writes data on the connection.
  ///
  /// Note: This function will block if there is no data to read or write.
  /// It's recommended to use `setupDispatch(with:)`.
  /// - Parameter timeout: The timeout interval.
  /// - Returns: `true` if still connected.
  public func readWrite(timeout: TimeoutInterval = .useDefault) -> Bool {
    dbus_connection_read_write(raw, timeout.rawValue) != 0
  }

  /// Reads, writes, and dispatches data on the connection.
  ///
  /// Note: This function will block if there is no data to read or write.
  /// It's recommended to use `setupDispatch(with:)`.
  /// - Parameter timeout: The timeout interval.
  /// - Returns: `true` if the disconnect message has not been processed.
  public func readWriteDispatch(timeout: TimeoutInterval = .useDefault) -> Bool {
    dbus_connection_read_write_dispatch(raw, timeout.rawValue) != 0
  }

  /// Processes any incoming data.
  ///
  /// Note: This function is called automatically while using
  /// `setupDispatch(with:)`.
  /// - Returns: The dispatch status.
  public func dispatch() -> DispatchStatus {
    DispatchStatus(dbus_connection_dispatch(raw))
  }

  /// Blocks until the outgoing message queue is empty.
  public func flush() {
    dbus_connection_flush(raw)
  }

  /// Checks if the connection can send a specific type of argument.
  /// - Parameter type: The type of argument.
  /// - Returns: `true` if the connection can send the argument type.
  public func canSend(type: ArgumentType) -> Bool {
    dbus_connection_can_send_type(raw, type.rawValue) != 0
  }

  /// Sends a message on the connection.
  /// - Parameter message: The message to send.
  /// - Throws: `DBus.Error` if the message could not be sent.
  /// - Returns: The serial number of the sent message.
  public func send(message: Message) throws(DBus.Error) -> /* serial: */ UInt32 {
    var serial: UInt32 = 0
    if dbus_connection_send(raw, message.raw, &serial) == 0 {
      throw .init(name: .noMemory, message: "Failed to send message")
    }
    return serial
  }

  /// Sends a message with a reply on the connection.
  /// - Parameters:
  ///   - message: The message to send.
  ///   - timeout: The timeout interval.
  /// - Throws: `DBus.Error` if the message could not be sent.
  /// - Returns: A pending call to track the reply.
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

  /// Sends a message with a reply on the connection and executes a completion handler.
  ///
  /// Note: If the reply is an error, the result will be a `failure` rather
  /// than a `success` with the error reply.
  /// - Parameters:
  ///   - message: The message to send.
  ///   - timeout: The timeout interval.
  ///   - completion: The completion handler to execute when the reply is received.
  /// - Throws: `DBus.Error` if the message could not be sent.
  /// - Returns: A function to cancel the pending call.
  public func sendWithReply(
    message: Message, timeout: TimeoutInterval = .useDefault,
    completion: @escaping (Result<Message, DBus.Error>) -> Void
  ) throws(DBus.Error) -> () -> Void {
    let pendingCall = try sendWithReply(message: message, timeout: timeout)
    try pendingCall.setCompletionHandler {
      let reply = pendingCall.stealReply()!  // Must not be nil if the call is complete
      if let error = reply.error {
        completion(.failure(error))
      } else {
        completion(.success(reply))
      }
    }
    return { pendingCall.cancel() }
  }

  /// Sends a message with a reply on the connection asynchronously.
  ///
  /// Note: Cancellation is not supported currently.
  /// - Parameters:
  ///   - message: The message to send.
  ///   - timeout: The timeout interval.
  /// - Throws: `DBus.Error` if the message could not be sent, or timeout,
  ///            or the reply is an error.
  /// - Returns: The reply message.
  @available(macOS 10.15.0, *)
  public func sendWithReply(
    message: Message, timeout: TimeoutInterval = .useDefault
  ) async throws(DBus.Error) -> Message {
    let result = await withCheckedContinuation { continuation in
      do {
        _ = try sendWithReply(message: message, timeout: timeout) { reply in
          continuation.resume(returning: reply)
        }
      } catch {
        continuation.resume(returning: Result.failure(error as! DBus.Error))
      }
    }
    return try result.get()
  }

  /// Sends a message with a reply on the connection and blocks until the reply is received.
  /// - Parameters:
  ///   - message: The message to send.
  ///   - timeout: The timeout interval.
  /// - Throws: `DBus.Error` if the message could not be sent, or timeout,
  ///           or the reply is an error.
  /// - Returns: The reply message.
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

  /// Pops a message from the incoming message queue.
  /// - Returns: The popped message, or `nil` if no message is available.
  public func popMessage() -> Message? {
    dbus_connection_pop_message(raw).map(Message.init)
  }

  /// Executes a block with a borrowed message.
  /// - Parameters:
  ///   - block: The block to execute with the borrowed message. Please set
  ///            `consumed` to `true` if the message is consumed, otherwise it will be returned.
  /// - Throws: An error if the block throws an error.
  /// - Returns: The result of the block.
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
        message.raw = nil  // Release ownership
      }
    }
    return try block(message, &consumed)
  }

  /// Sets the watch delegate for the connection.
  ///
  /// The watch delegate is used to monitor file descriptors for read/write
  /// events. It's useful for integrating the connection with an event
  /// system, such as `RunLoop`, `libevent`, or low-level `epoll`, `kqueue`, etc.
  /// - Parameter delegate: The watch delegate.
  /// - Throws: `DBus.Error` if the watch delegate could not be set.
  public func setWatchDelegate(_ delegate: any WatchDelegate) throws(DBus.Error) {
    let userData = Unmanaged.passRetained(delegate as AnyObject).toOpaque()
    let result = dbus_connection_set_watch_functions(
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
      })
    guard result != 0 else {
      throw .init(name: .noMemory, message: "Failed to set watch delegate")
    }
  }

  /// Sets the timeout delegate for the connection.
  ///
  /// The timeout delegate is used to set timers. It's useful for
  /// integrating the connection with a timer, usually provided by an
  /// event loop.
  /// - Parameter delegate: The timeout delegate.
  /// - Throws: `DBus.Error` if the timeout delegate could not be set.
  public func setTimeoutDelegate(_ delegate: any TimeoutDelegate) throws(DBus.Error) {
    let userData = Unmanaged.passRetained(delegate as AnyObject).toOpaque()
    let result = dbus_connection_set_timeout_functions(
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
      })
    guard result != 0 else {
      throw .init(name: .noMemory, message: "Failed to set timeout delegate")
    }
  }

  /// Sets the dispatch status handler for the connection.
  ///
  /// Note: If the dispatch status is `dataRemains`, then
  /// `dispatch()` needs to be called to process incoming
  /// messages. However, `dispatch()` must NOT be called inside the handler.
  /// Instead, usually, call `dispatch()` in the next iteration of the event loop.
  /// - Parameter handler: The dispatch status handler.
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

  /// Sets the wake-up handler for the connection.
  ///
  /// The wake-up handler is used to wake up an event loop if the dispatch
  /// is handled by it.
  /// - Parameter handler: The wake-up handler.
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

  /// Adds a message filter. Filters are handlers that are run on all
  /// incoming messages, prior to the object handlers registered with
  /// `registerHandler(path:handler:)`. Filters are run in the order
  /// that they were added. The same handler can be added as a filter
  /// more than once, in which case it will be run more than once.
  /// Filters added during a filter callback won't be run on the message
  /// being processed.
  /// - Parameter filter: The filter to add.
  /// - Throws: `DBus.Error` if the filter could not be added.
  /// - Returns: A function to remove the filter.
  public func addFilter(_ filter: (Message) -> HandlerResult) throws(DBus.Error) -> () -> Void {
    let userData = Unmanaged.passRetained(filter as AnyObject).toOpaque()
    let filterFunction: DBusHandleMessageFunction = { connection, message, userData in
      let filter = Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue()
      dbus_message_ref(message)
      let message = Message(message!)
      return DBusHandlerResult((filter as! (Message) -> HandlerResult)(message).rawValue)
    }
    let freeFunction: DBusFreeFunction = { userData in
      Unmanaged<AnyObject>.fromOpaque(userData!).release()
    }
    let result = dbus_connection_add_filter(raw, filterFunction, userData, freeFunction)
    guard result != 0 else {
      throw .init(name: .noMemory, message: "Failed to add filter")
    }
    return {
      dbus_connection_remove_filter(self.raw, filterFunction, userData)
    }
  }

  private var handlers: [ObjectPath: [(id: UUID, (Message) -> HandlerResult)]] = [:]

  /// Registers a handler for a specific object path.
  ///
  /// The same object path can have multiple handlers, which are run in
  /// the order they were registered, if the previous handler returns
  /// `notYet`.
  /// - Parameters:
  ///   - path: The object path.
  ///   - handler: The handler to register.
  /// - Throws: `DBus.Error` if the handler could not be registered.
  /// - Returns: A function to unregister the handler.
  public func registerHandler(
    path: ObjectPath, handler: @escaping (Message) -> HandlerResult
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    let handlerId = UUID()
    handlers[path, default: []].append((handlerId, handler))
    if handlers[path]!.count == 1 {
      let handle: (Message) -> HandlerResult = { [weak self] message in
        guard let handlers = self?.handlers[path] else { return .notYet }
        for (_, handler) in handlers {
          let result = handler(message)
          if result != .notYet {
            return result
          }
        }
        return .notYet
      }
      let userData = Unmanaged.passRetained(handle as AnyObject).toOpaque()
      var vtable = DBusObjectPathVTable()
      vtable.message_function = { connection, message, userData in
        let handle = Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue()
        dbus_message_ref(message)
        let message = Message(message!)
        return DBusHandlerResult((handle as! (Message) -> HandlerResult)(message).rawValue)
      }
      vtable.unregister_function = { connection, userData in
        Unmanaged<AnyObject>.fromOpaque(userData!).release()
      }
      let error = RawError()
      _ = dbus_connection_try_register_object_path(  // ignore the return value since error is handled
        raw, path.rawValue, &vtable, userData, &error.raw)
      if let error = DBus.Error(error) {
        throw error
      }
    }
    return { () throws(DBus.Error) in
      self.handlers[path]!.removeAll { (id, _) in id == handlerId }
      if self.handlers[path]!.isEmpty {
        guard dbus_connection_unregister_object_path(self.raw, path.rawValue) != 0 else {
          throw .init(name: .noMemory, message: "Failed to unregister object path")
        }
      }
    }
  }
}

/// Results that a message handler can return.
public enum HandlerResult: UInt32 {
  /// Message has had its effect - no need to run more handlers.
  case handled
  /// Message has not had any effect - see if other handlers want it.
  case notYet
  /// Need more memory in order to return `handled` or `notYet`.
  /// Please try again later with more memory.
  case needMemory
}

extension HandlerResult {
  /// Initializes a handler result from a libdbus handler result.
  /// - Parameter rawValue: The raw value of the libdbus handler result.
  init(_ result: DBusHandlerResult) {
    self.init(rawValue: result.rawValue)!
  }
}
