import CDBus
import Dispatch
import Foundation

/// Represents a timeout interval.
public struct TimeoutInterval: Sendable, Equatable, Hashable, RawRepresentable {
  /// The raw value of the timeout interval in milliseconds.
  public let rawValue: Int32

  /// Initializes a new `TimeoutInterval` with the given raw value.
  ///
  /// - Parameter rawValue: The raw value of the timeout interval in milliseconds.
  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  /// Initializes a new `TimeoutInterval` from a `Duration`.
  ///
  /// - Parameter duration: The duration to convert to a timeout interval.
  @available(macOS 13.0, *)
  public init(_ duration: Duration) {
    let (seconds, attoseconds) = duration.components
    rawValue = Int32(seconds * 1000 + attoseconds / 1_000_000_000_000_000)
  }
}

extension TimeoutInterval {
  /// Uses the default timeout interval.
  public static let useDefault = Self(rawValue: DBUS_TIMEOUT_USE_DEFAULT)
  /// Represents an infinite timeout interval, i.e., no timeout.
  public static let infinite = Self(rawValue: DBUS_TIMEOUT_INFINITE)

  /// Creates a `TimeoutInterval` from milliseconds.
  ///
  /// - Parameter milliseconds: The number of milliseconds.
  /// - Returns: A `TimeoutInterval` representing the given milliseconds.
  public static func milliseconds(_ milliseconds: Int32) -> Self {
    .init(rawValue: milliseconds)
  }

  /// Creates a `TimeoutInterval` from seconds.
  ///
  /// - Parameter seconds: The number of seconds.
  /// - Returns: A `TimeoutInterval` representing the given seconds.
  public static func seconds(_ seconds: Int32) -> Self {
    .init(rawValue: seconds * 1000)
  }

  /// Creates a `TimeoutInterval` from minutes.
  ///
  /// - Parameter minutes: The number of minutes.
  /// - Returns: A `TimeoutInterval` representing the given minutes.
  public static func minutes(_ minutes: Int32) -> Self {
    .init(rawValue: minutes * 60 * 1000)
  }
}

/// A wrapper for `DBusTimeout`.
public struct Timeout: Hashable, @unchecked Sendable {
  /// The raw pointer to `DBusTimeout`.
  let raw: OpaquePointer

  /// Initializes a new `Timeout` with the given raw pointer.
  ///
  /// - Parameter raw: The raw pointer to `DBusTimeout`.
  init(_ raw: OpaquePointer) {
    self.raw = raw
  }

  /// The interval of the timeout.
  public var interval: TimeoutInterval {
    .init(rawValue: dbus_timeout_get_interval(raw))
  }

  /// Indicates whether the timeout is enabled.
  public var isEnabled: Bool {
    dbus_timeout_get_enabled(raw) != 0
  }

  /// Handles the timeout.
  ///
  /// - Throws: `DBus.Error` if handling the timeout fails.
  public func handle() throws(DBus.Error) {
    guard dbus_timeout_handle(raw) != 0 else {
      throw .init(name: .noMemory, message: "Failed to handle timeout")
    }
  }
}

/// A protocol for handling timeouts.
public protocol TimeoutDelegate: AnyObject {
  /// Adds a timeout.
  ///
  /// - Parameter timeout: The timeout to add.
  /// - Returns: `true` if the timeout was added successfully, `false` otherwise.
  func add(timeout: Timeout) -> Bool

  /// Removes a timeout.
  ///
  /// - Parameter timeout: The timeout to remove.
  func remove(timeout: Timeout)

  /// Called when a timeout is toggled.
  ///
  /// - Parameter timeout: The toggled timeout.
  func onToggled(timeout: Timeout)
}

/// A class that handles timeouts using `RunLoop`.
public class RunLoopTimer: TimeoutDelegate {
  /// The run loop used to handle timers.
  private let runLoop: RunLoop
  /// A dictionary mapping timeouts to timers.
  private var timers: [Timeout: Timer] = [:]

  /// Initializes a new `RunLoopTimer` with the given run loop.
  ///
  /// - Parameter runLoop: The run loop to use for handling timers.
  public init(runLoop: RunLoop) {
    self.runLoop = runLoop
  }

  /// Adds a timeout to the run loop.
  ///
  /// - Parameter timeout: The timeout to add.
  /// - Returns: `true` if the timeout was added successfully, `false` otherwise.
  public func add(timeout: Timeout) -> Bool {
    let interval = timeout.interval.rawValue
    let timer = Timer(timeInterval: Double(interval) / 1000, repeats: false) { timer in
      do {
        try timeout.handle()
      } catch {
        perror("[dbus]: RunLoopTimer: \(error)")
      }
    }
    RunLoop.main.add(timer, forMode: .default)
    timers[timeout] = timer
    return true
  }

  /// Removes a timeout from the run loop.
  ///
  /// - Parameter timeout: The timeout to remove.
  public func remove(timeout: Timeout) {
    if let timer = timers.removeValue(forKey: timeout) {
      timer.invalidate()
    }
  }

  /// Called when a timeout is toggled.
  ///
  /// - Parameter timeout: The toggled timeout.
  public func onToggled(timeout: Timeout) {
    if timeout.isEnabled {
      _ = add(timeout: timeout)
    } else {
      remove(timeout: timeout)
    }
  }
}

/// A class that handles timeouts using `DispatchQueue`.
public class DispatchQueueTimer: TimeoutDelegate {
  /// The dispatch queue used to handle timers.
  private let queue: DispatchQueue
  /// A dictionary mapping timeouts to dispatch source timers.
  private var timers: [Timeout: DispatchSourceTimer] = [:]

  /// Initializes a new `DispatchQueueTimer` with the given dispatch queue.
  ///
  /// - Parameter queue: The dispatch queue to use for handling timers.
  public init(queue: DispatchQueue) {
    self.queue = queue
  }

  /// Adds a timeout to the dispatch queue.
  ///
  /// - Parameter timeout: The timeout to add.
  /// - Returns: `true` if the timeout was added successfully, `false` otherwise.
  public func add(timeout: Timeout) -> Bool {
    let interval = timeout.interval.rawValue
    let timer = DispatchSource.makeTimerSource(queue: queue)
    timer.schedule(deadline: .now() + .milliseconds(Int(interval)))
    timer.setEventHandler {
      do {
        try timeout.handle()
      } catch {
        perror("[dbus]: DispatchQueueTimer: \(error)")
      }
    }
    timer.activate()
    timers[timeout] = timer
    return true
  }

  /// Removes a timeout from the dispatch queue.
  ///
  /// - Parameter timeout: The timeout to remove.
  public func remove(timeout: Timeout) {
    if let timer = timers.removeValue(forKey: timeout) {
      timer.cancel()
    }
  }

  /// Called when a timeout is toggled.
  ///
  /// - Parameter timeout: The toggled timeout.
  public func onToggled(timeout: Timeout) {
    if timeout.isEnabled {
      _ = add(timeout: timeout)
    } else {
      remove(timeout: timeout)
    }
  }
}
