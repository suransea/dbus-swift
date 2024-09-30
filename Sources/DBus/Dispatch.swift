import CDBus
import Dispatch
import Foundation

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

extension Connection {
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
