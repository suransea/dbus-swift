import CDBus

public class PendingCall {
  var raw: OpaquePointer

  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  deinit {
    cancel()
    dbus_pending_call_unref(raw)
  }

  public var isComplete: Bool {
    dbus_pending_call_get_completed(raw) != 0
  }

  public func stealReply() -> Message? {
    Message(dbus_pending_call_steal_reply(raw))
  }

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

  public func block() {
    dbus_pending_call_block(raw)
  }

  public func cancel() {
    dbus_pending_call_cancel(raw)
  }
}
