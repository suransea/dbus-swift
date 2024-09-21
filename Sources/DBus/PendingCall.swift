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

  public func setNotify(_ block: @escaping () -> Void) {
    class Ref<T> {
      let value: T
      init(_ value: T) {
        self.value = value
      }
    }
    let userData = Unmanaged.passRetained(Ref(block)).toOpaque()
    let notification: DBusPendingCallNotifyFunction = { pendingCall, userData in
      let block = Unmanaged<Ref<() -> Void>>.fromOpaque(userData!).takeUnretainedValue()
      block.value()
    }
    let freeUserData: DBusFreeFunction = { userData in
      Unmanaged<Ref<() -> Void>>.fromOpaque(userData!).release()
    }
    dbus_pending_call_set_notify(raw, notification, userData, freeUserData)
  }

  public func block() {
    dbus_pending_call_block(raw)
  }

  public func cancel() {
    dbus_pending_call_cancel(raw)
  }
}
