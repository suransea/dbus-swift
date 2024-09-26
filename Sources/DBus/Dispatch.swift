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
  public func setupDispatch(with runLoop: RunLoop) -> Bool {
    let dispatchRemains = {
      runLoop.perform {
        while self.dispatch() == .dataRemains {}
      }
      CFRunLoopWakeUp(runLoop.getCFRunLoop())
    }
    setDispatchStatusHandler { status in
      if status == .dataRemains {
        dispatchRemains()
      }
    }
    setWakeUpHandler {
      CFRunLoopWakeUp(CFRunLoopGetMain())
    }
    let watchDelegate = RunLoopWatcher(runLoop: runLoop, dispatcher: dispatchRemains)
    let timeoutDelegate = RunLoopTimer(runLoop: runLoop)
    return setWatchDelegate(watchDelegate) && setTimeoutDelegate(timeoutDelegate)
  }

  public func setupDispatch(with queue: DispatchQueue) -> Bool {
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
    let watchDelegate = DispatchQueueWatcher(queue: queue, dispatcher: dispatchRemains)
    let timeoutDelegate = DispatchQueueTimer(queue: queue)
    return setWatchDelegate(watchDelegate) && setTimeoutDelegate(timeoutDelegate)
  }
}
