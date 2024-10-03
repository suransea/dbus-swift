import CDBus
import Dispatch
import Foundation

/// Indicates the status of incoming data on a `Connection`.
/// This determines whether `dispatch()` needs to be called.
public enum DispatchStatus: UInt32 {
  /// There is more data to potentially convert to messages.
  case dataRemains
  /// All currently available data has been processed.
  case complete
  /// More memory is needed to continue.
  case needMemory
}

extension DispatchStatus {
  /// Initializes a `DispatchStatus` from a `DBusDispatchStatus`.
  ///
  /// - Parameter status: The `DBusDispatchStatus`.
  init(_ status: DBusDispatchStatus) {
    self.init(rawValue: status.rawValue)!
  }
}

extension Connection {
  /// Sets up dispatching with a `RunLoop`.
  ///
  /// Note: This function sets `DispatchStatusHandler`, `WakeUpHandler`,
  /// `WatchDelegate`, and `TimeoutDelegate`, so you should not set them manually.
  /// - Parameter runLoop: The run loop to use for dispatching.
  /// - Throws: `DBus.Error` if the setup fails.
  public func setupDispatch(with runLoop: RunLoop) throws(DBus.Error) {
    let dispatchRemains = {
      CFRunLoopPerformBlock(runLoop.getCFRunLoop(), CFRunLoopMode.defaultMode.rawValue) {
        while self.dispatch() == .dataRemains {}
      }
    }
    setDispatchStatusHandler { status in
      if status == .dataRemains {
        dispatchRemains()
      }
    }
    setWakeUpHandler {
      CFRunLoopWakeUp(runLoop.getCFRunLoop())
    }
    try setWatchDelegate(RunLoopWatcher(runLoop: runLoop, dispatcher: dispatchRemains))
    try setTimeoutDelegate(RunLoopTimer(runLoop: runLoop))
  }

  /// Sets up dispatching with a `DispatchQueue`.
  ///
  /// Note: This function sets `DispatchStatusHandler`, `WatchDelegate`,
  /// and `TimeoutDelegate`, so you should not set them manually.
  /// - Parameter queue: The dispatch queue to use for dispatching.
  /// - Throws: `DBus.Error` if the setup fails.
  public func setupDispatch(with queue: DispatchQueue) throws(DBus.Error) {
    let dispatchRemains = {
      queue.async {
        while self.dispatch() == .dataRemains {}
      }
    }
    setDispatchStatusHandler { status in
      if status == .dataRemains {
        dispatchRemains()
      }
    }
    try setWatchDelegate(DispatchQueueWatcher(queue: queue, dispatcher: dispatchRemains))
    try setTimeoutDelegate(DispatchQueueTimer(queue: queue))
  }
}
