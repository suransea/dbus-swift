import CDBus
import Dispatch
import Foundation

public struct TimeoutInterval: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  @available(macOS 13.0, *)
  public init(_ duration: Duration) {
    let (seconds, attoseconds) = duration.components
    rawValue = Int32(seconds * 1000 + attoseconds / 1_000_000_000_000_000)
  }
}

extension TimeoutInterval {
  public static let useDefault = Self(rawValue: DBUS_TIMEOUT_USE_DEFAULT)
  public static let infinite = Self(rawValue: DBUS_TIMEOUT_INFINITE)

  public static func milliseconds(_ milliseconds: Int32) -> Self {
    .init(rawValue: milliseconds)
  }

  public static func seconds(_ seconds: Int32) -> Self {
    .init(rawValue: seconds * 1000)
  }

  public static func minutes(_ minutes: Int32) -> Self {
    .init(rawValue: minutes * 60 * 1000)
  }
}

public struct Timeout: Hashable, @unchecked Sendable {
  let raw: OpaquePointer

  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  public var interval: TimeoutInterval {
    .init(rawValue: dbus_timeout_get_interval(raw))
  }

  public var isEnabled: Bool {
    dbus_timeout_get_enabled(raw) != 0
  }

  public func handle() -> Bool {
    dbus_timeout_handle(raw) != 0
  }
}

public protocol TimeoutDelegate: AnyObject {
  func add(timeout: Timeout) -> Bool
  func remove(timeout: Timeout)
  func onToggled(timeout: Timeout)
}

public class RunLoopTimer: TimeoutDelegate {
  private let runLoop: RunLoop
  private var timers: [Timeout: Timer] = [:]

  public init(runLoop: RunLoop) {
    self.runLoop = runLoop
  }

  public func add(timeout: Timeout) -> Bool {
    let interval = timeout.interval.rawValue
    let timer = Timer(timeInterval: Double(interval) / 1000, repeats: false) { timer in
      _ = timeout.handle()
    }
    RunLoop.main.add(timer, forMode: .default)
    timers[timeout] = timer
    return true
  }

  public func remove(timeout: Timeout) {
    if let timer = timers.removeValue(forKey: timeout) {
      timer.invalidate()
    }
  }

  public func onToggled(timeout: Timeout) {
    if timeout.isEnabled {
      _ = add(timeout: timeout)
    } else {
      remove(timeout: timeout)
    }
  }
}

public class DispatchQueueTimer: TimeoutDelegate {
  private let queue: DispatchQueue
  private var timers: [Timeout: DispatchSourceTimer] = [:]

  public init(queue: DispatchQueue) {
    self.queue = queue
  }

  public func add(timeout: Timeout) -> Bool {
    let interval = timeout.interval.rawValue
    let timer = DispatchSource.makeTimerSource(queue: queue)
    timer.schedule(deadline: .now() + .milliseconds(Int(interval)))
    timer.setEventHandler {
      _ = timeout.handle()
    }
    timer.activate()
    timers[timeout] = timer
    return true
  }

  public func remove(timeout: Timeout) {
    if let timer = timers.removeValue(forKey: timeout) {
      timer.cancel()
    }
  }

  public func onToggled(timeout: Timeout) {
    if timeout.isEnabled {
      _ = add(timeout: timeout)
    } else {
      remove(timeout: timeout)
    }
  }
}
