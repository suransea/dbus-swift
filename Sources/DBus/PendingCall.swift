import CDBus

/// Represents a pending call for a reply message.
public class PendingCall {
  /// The raw pointer to the D-Bus pending call.
  var raw: OpaquePointer

  /// Initializes a new `PendingCall` with the given raw pointer.
  ///
  /// - Parameter raw: The raw pointer to `DBusPendingCall`.
  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  deinit {
    cancel()
    dbus_pending_call_unref(raw)
  }

  /// Indicates whether the pending call is complete.
  ///
  /// - Returns: `true` if the call is complete, `false` otherwise.
  public var isComplete: Bool {
    dbus_pending_call_get_completed(raw) != 0
  }

  /// Steals the reply from the pending call.
  ///
  /// - Returns: The `Message` containing the reply, or `nil` if none has been received yet.
  public func stealReply() -> Message? {
    Message(dbus_pending_call_steal_reply(raw))
  }

  /// Sets a completion handler to be called when the pending call is complete.
  ///
  /// - Parameter block: The completion handler to be called.
  /// - Throws: `DBus.Error` if setting the notify function fails.
  public func setCompletionHandler(_ block: @escaping () -> Void) throws(DBus.Error) {
    let userData = Unmanaged.passRetained(block as AnyObject).toOpaque()
    let notification: DBusPendingCallNotifyFunction = { pendingCall, userData in
      let block = Unmanaged<AnyObject>.fromOpaque(userData!).takeUnretainedValue()
      (block as! () -> Void)()
    }
    let freeUserData: DBusFreeFunction = { userData in
      Unmanaged<AnyObject>.fromOpaque(userData!).release()
    }
    if dbus_pending_call_set_notify(raw, notification, userData, freeUserData) == 0 {
      throw .init(name: .noMemory, message: "Failed to set notify")
    }
  }

  /// Blocks the current thread until the pending call is complete.
  public func block() {
    dbus_pending_call_block(raw)
  }

  /// Cancels the pending call, such that any reply or error received
  /// will be ignored.
  public func cancel() {
    dbus_pending_call_cancel(raw)
  }
}
