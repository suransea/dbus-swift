import CDBus
import Foundation

/// Represents a proxy for a D-Bus object.
public class ObjectProxy {
  let connection: Connection
  let destination: BusName
  let path: ObjectPath
  let timeout: TimeoutInterval

  /// Initializes a new `ObjectProxy`.
  /// - Parameters:
  ///   - connection: The connection to use.
  ///   - destination: The bus name of the destination.
  ///   - path: The object path.
  ///   - timeout: The timeout interval.
  public init(
    connection: Connection,
    destination: BusName = "",
    path: ObjectPath,
    timeout: TimeoutInterval = .useDefault
  ) {
    self.connection = connection
    self.destination = destination
    self.path = path
    self.timeout = timeout
  }

  /// Returns a proxy for methods of the specified interface.
  ///
  /// - Parameter interface: The interface name.
  /// - Returns: A `MethodsProxy` for the specified interface.
  public func methods(interface: InterfaceName) -> MethodsProxy {
    .init(object: self, interface: interface)
  }

  /// Returns a proxy for signals of the specified interface.
  ///
  /// - Parameter interface: The interface name.
  /// - Returns: A `SignalsProxy` for the specified interface.
  public func signals(interface: InterfaceName) -> SignalsProxy {
    .init(object: self, interface: interface)
  }

  /// Returns a proxy for properties of the specified interface.
  ///
  /// - Parameter interface: The interface name.
  /// - Returns: A `PropertiesProxy` for the specified interface.
  public func properties(interface: InterfaceName) -> PropertiesProxy {
    .init(object: self, interface: interface)
  }

  lazy var propertiesDelegate = PropertiesDelegate(object: self)
}

/// Represents a proxy for methods of a D-Bus object.
@dynamicMemberLookup
public struct MethodsProxy {
  let object: ObjectProxy
  let interface: InterfaceName

  /// Initializes a new `MethodsProxy`.
  ///
  /// - Parameters:
  ///   - object: The object proxy.
  ///   - interface: The interface name.
  public init(object: ObjectProxy, interface: InterfaceName) {
    self.object = object
    self.interface = interface
  }

  /// Accesses the method proxy for the specified member.
  ///
  /// - Parameter member: The member name.
  /// - Returns: A `MethodProxy` for the specified member.
  public subscript(dynamicMember member: MemberName) -> MethodProxy {
    .init(object: object, interface: interface, method: member)
  }
}

/// Represents a proxy for a method of a D-Bus object.
public struct MethodProxy {
  let object: ObjectProxy
  let interface: InterfaceName
  let method: MemberName

  /// Calls the method with the specified arguments.
  ///
  /// - Parameter arguments: The arguments to pass to the method.
  /// - Throws: `DBus.Error` if the call fails.
  /// - Returns: The result of the method call.
  public func callAsFunction<each T: Argument, each R: Argument>(
    _ arguments: repeat each T
  ) throws(DBus.Error) -> (repeat each R) {
    let methodCall = (
      destination: object.destination,
      path: object.path,
      interface: interface,
      name: method
    )
    let message = Message(methodCall: methodCall)
    var iter = MessageIterator(appending: message)
    repeat try (each arguments).append(to: &iter)
    let reply = try object.connection.sendWithReplyAndBlock(
      message: message, timeout: object.timeout)
    var replyIter = MessageIterator(reading: reply)
    return (repeat try (each R).init(from: &replyIter))
  }

  /// Calls the method with the specified arguments and returns a single result.
  ///
  /// Note: This function helps the compiler infer the type of "each R" and
  /// could be removed when the Swift compiler fixes this issue.
  /// - Parameter arguments: The arguments to pass to the method.
  /// - Throws: `DBus.Error` if the call fails.
  /// - Returns: The result of the method call.
  public func callAsFunction<each T: Argument, R: Argument>(
    _ arguments: repeat each T
  ) throws(DBus.Error) -> R {
    let methodCall = (
      destination: object.destination,
      path: object.path,
      interface: interface,
      name: method
    )
    let message = Message(methodCall: methodCall)
    var iter = MessageIterator(appending: message)
    repeat try (each arguments).append(to: &iter)
    let reply = try object.connection.sendWithReplyAndBlock(
      message: message, timeout: object.timeout)
    var replyIter = MessageIterator(reading: reply)
    return try R(from: &replyIter)
  }

  /// Calls the method asynchronously with the specified arguments.
  ///
  /// - Parameter arguments: The arguments to pass to the method.
  /// - Throws: `DBus.Error` if the call fails.
  /// - Returns: The result of the method call.
  @available(macOS 10.15.0, *)
  public func callAsFunction<each T: Argument, each R: Argument>(
    _ arguments: repeat each T
  ) async throws(DBus.Error) -> (repeat each R) {
    let methodCall = (
      destination: object.destination,
      path: object.path,
      interface: interface,
      name: method
    )
    let message = Message(methodCall: methodCall)
    var iter = MessageIterator(appending: message)
    repeat try (each arguments).append(to: &iter)
    let reply = try await object.connection.sendWithReply(
      message: message, timeout: object.timeout)
    var replyIter = MessageIterator(reading: reply)
    return (repeat try (each R).init(from: &replyIter))
  }

  /// Calls the method asynchronously with the specified arguments and returns a single result.
  ///
  /// Note: This function helps the compiler infer the type of "each R" and
  /// could be removed when the Swift compiler fixes this issue.
  /// - Parameter arguments: The arguments to pass to the method.
  /// - Throws: `DBus.Error` if the call fails.
  /// - Returns: The result of the method call.
  @available(macOS 10.15.0, *)
  public func callAsFunction<each T: Argument, R: Argument>(
    _ arguments: repeat each T
  ) async throws(DBus.Error) -> R {
    let methodCall = (
      destination: object.destination,
      path: object.path,
      interface: interface,
      name: method
    )
    let message = Message(methodCall: methodCall)
    var iter = MessageIterator(appending: message)
    repeat try (each arguments).append(to: &iter)
    let reply = try await object.connection.sendWithReply(
      message: message, timeout: object.timeout)
    var replyIter = MessageIterator(reading: reply)
    return try R(from: &replyIter)
  }

  /// Delegates the method to the specified handler.
  ///
  /// - Parameter handler: The handler to register.
  /// - Throws: `DBus.Error` if the handler could not be registered.
  /// - Returns: A function to unregister the handler.
  public func delegate<each T: Argument, each R: Argument>(
    to handler: @escaping (repeat each T) throws(DBus.Error) -> (repeat each R)
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try object.connection.registerHandler(path: object.path) { message in
      guard message.type == .methodCall else { return .notYet }
      guard message.interface == interface else { return .notYet }
      guard message.member == method else { return .notYet }
      var iter = MessageIterator(reading: message)
      let serial: UInt32?
      do {
        let results = try handler(repeat try (each T).init(from: &iter))
        let reply = Message(methodReturn: message)
        var replyIter = MessageIterator(appending: reply)
        repeat try (each results).append(to: &replyIter)
        serial = try? object.connection.send(message: reply)
      } catch {
        let error = error as! DBus.Error
        let reply = Message(error: (replyTo: message, name: error.name, message: error.message))
        serial = try? object.connection.send(message: reply)
      }
      return serial == nil ? .needMemory : .handled
    }
  }
}

/// Represents a proxy for signals of a D-Bus object.
@dynamicMemberLookup
public struct SignalsProxy {
  let object: ObjectProxy
  let interface: InterfaceName

  /// Initializes a new `SignalsProxy`.
  ///
  /// - Parameters:
  ///   - object: The object proxy.
  ///   - interface: The interface name.
  public init(object: ObjectProxy, interface: InterfaceName) {
    self.object = object
    self.interface = interface
  }

  /// Accesses the signal proxy for the specified member.
  ///
  /// - Parameter member: The member name.
  /// - Returns: A `SignalProxy` for the specified member.
  public subscript(dynamicMember member: MemberName) -> SignalProxy {
    .init(object: object, interface: interface, signal: member)
  }
}

/// Represents a proxy for a signal of a D-Bus object.
public struct SignalProxy {
  let object: ObjectProxy
  let interface: InterfaceName
  let signal: MemberName

  /// Emits the signal with the specified arguments.
  ///
  /// - Parameter arguments: The arguments to include in the signal.
  /// - Throws: `DBus.Error` if the signal could not be emitted.
  public func emit<each T: Argument>(
    _ arguments: repeat each T
  ) throws(DBus.Error) {
    let message = Message(signal: (path: object.path, interface: interface, name: signal))
    var iter = MessageIterator(appending: message)
    repeat try (each arguments).append(to: &iter)
    _ = try object.connection.send(message: message)
  }

  /// Registers a handler for the signal.
  ///
  /// - Parameters:
  ///   - consumed: Whether the signal should be consumed.
  ///   - handler: The handler to register.
  /// - Throws: `DBus.Error` if the handler could not be registered.
  /// - Returns: A function to unregister the handler.
  public func connect<each T: Argument>(
    consumed: Bool = false,
    _ handler: @escaping (repeat each T) -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try object.connection.registerHandler(path: object.path) { message in
      guard message.type == .signal else { return .notYet }
      guard message.interface == interface else { return .notYet }
      guard message.member == signal else { return .notYet }
      var iter = MessageIterator(reading: message)
      do {
        handler(repeat try (each T).init(from: &iter))
      } catch {
        perror("[dbus] SignalProxy: Failed to handle signal: \(error)")
        return .notYet
      }
      return consumed ? .handled : .notYet
    }
  }
}

/// A delegate for handling properties.
class PropertiesDelegate: PropertiesInterface {
  private let object: ObjectProxy
  private var properties: [Key: Accessor] = [:]
  private var unregisterInterfce: (() throws(DBus.Error) -> Void)?

  init(object: ObjectProxy) {
    self.object = object
  }

  /// Registers a property.
  func register(
    interface: InterfaceName, name: String, accessor: Accessor
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    if properties.isEmpty {
      try registerInterface()
    }
    let key = Key(interface: interface, name: name)
    properties[key] = accessor
    return { () throws(DBus.Error) in
      self.properties.removeValue(forKey: key)
      if self.properties.isEmpty {
        try self.unregisterInterfce?()
        self.unregisterInterfce = nil
      }
    }
  }

  /// Registers this properties interface.
  private func registerInterface() throws(DBus.Error) {
    let methods = object.methods(interface: .properties)
    let unregisterGet = try methods.Get.delegate(to: self.get)
    let unregisterGetAll = try methods.GetAll.delegate(to: self.getAll)
    let unregisterSet = try methods.Set.delegate(to: self.set)
    unregisterInterfce = { () throws(DBus.Error) in
      try unregisterGet()
      try unregisterGetAll()
      try unregisterSet()
    }
  }

  func getAll(
    _ interface: InterfaceName
  ) throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    properties
      .filter { (key, _) in key.interface == interface }
      .reduce(into: [:]) { result, pair in
        let (key, accessor) = pair
        result[key.name] = Variant(AnyArgument(accessor.get()))
      }
  }

  func get(
    _ interface: InterfaceName, _ name: String
  ) throws(DBus.Error) -> Variant<AnyArgument> {
    let key = Key(interface: interface, name: name)
    guard let accessor = properties[key] else {
      throw .init(name: .unknownProperty, message: "Unknown property: \(name)")
    }
    return Variant(AnyArgument(accessor.get()))
  }

  func set(
    _ interface: InterfaceName, _ name: String, _ value: Variant<AnyArgument>
  ) throws(DBus.Error) {
    let key = Key(interface: interface, name: name)
    guard let accessor = properties[key] else {
      throw .init(name: .unknownProperty, message: "Unknown property: \(name)")
    }
    guard let set = accessor.set else {
      throw .init(name: .propertyReadOnly, message: "Property is read-only: \(name)")
    }
    try set(value.value).get()
  }

  /// Unique key for a property.
  struct Key: Hashable {
    let interface: InterfaceName
    let name: String
  }

  /// Accessors for a property.
  typealias Accessor = (
    get: () -> any Argument,
    set: ((any Argument) -> Result<(), DBus.Error>)?
  )
}

/// Represents a proxy for properties of a D-Bus object.
@dynamicMemberLookup
public struct PropertiesProxy {
  let object: ObjectProxy
  let methods: MethodsProxy
  let changedSignal: SignalProxy
  let interface: InterfaceName

  /// Initializes a new `PropertiesProxy`.
  ///
  /// - Parameters:
  ///   - object: The object proxy.
  ///   - interface: The interface name.
  public init(object: ObjectProxy, interface: InterfaceName) {
    self.object = object
    methods = object.methods(interface: .properties)
    changedSignal = object.signals(interface: .properties).PropertiesChanged
    self.interface = interface
  }

  /// Gets all properties of the interface.
  ///
  /// - Throws: `DBus.Error` if the properties could not be retrieved.
  /// - Returns: A dictionary of property names and values.
  public func getAll() throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    try methods.GetAll(interface)
  }

  /// Gets all properties of the interface asynchronously.
  ///
  /// - Throws: `DBus.Error` if the properties could not be retrieved.
  /// - Returns: A dictionary of property names and values.
  @available(macOS 10.15.0, *)
  public func getAll() async throws(DBus.Error) -> [String: Variant<AnyArgument>] {
    try await methods.GetAll(interface)
  }

  /// Emits a signal that the properties have changed.
  ///
  /// - Parameters:
  ///   - changed: A dictionary of changed properties.
  ///   - invalidated: An array of invalidated property names.
  /// - Throws: `DBus.Error` if the notification could not be sent.
  public func didChange(
    changed: [String: Variant<AnyArgument>],
    invalidated: [String]
  ) throws(DBus.Error) {
    try changedSignal.emit(interface, changed, invalidated)
  }

  /// Registers a handler for property changes.
  ///
  /// - Parameter handler: The handler to register.
  /// - Throws: `DBus.Error` if the handler could not be registered.
  /// - Returns: A function to unregister the handler.
  public func observe(
    _ handler: @escaping (
      _ changed: [String: Variant<AnyArgument>],
      _ invalidates: [String]
    ) -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try changedSignal.connect {
      (interface: InterfaceName, changed: [String: Variant<AnyArgument>], invalidated: [String]) in
      guard interface == self.interface else { return }
      handler(changed, invalidated)
    }
  }

  /// Accesses the property proxy for the specified name.
  ///
  /// - Parameter name: The property name.
  /// - Returns: A `PropertyProxy` for the specified property.
  public subscript<T: Argument>(dynamicMember name: String) -> PropertyProxy<T> {
    .init(object: object, interface: interface, name: name)
  }
}

/// Represents a proxy for a property of a D-Bus object.
public struct PropertyProxy<T: Argument>: ObservableReadWriteProperty {
  private let object: ObjectProxy
  private let methods: MethodsProxy
  private let changedSignal: SignalProxy
  private let interface: InterfaceName
  private let name: String

  /// Initializes a new `PropertyProxy`.
  ///
  /// - Parameters:
  ///   - object: The object proxy.
  ///   - interface: The interface name.
  ///   - name: The property name.
  public init(
    object: ObjectProxy, interface: InterfaceName, name: String
  ) {
    self.object = object
    methods = object.methods(interface: .properties)
    changedSignal = object.signals(interface: .properties).PropertiesChanged
    self.interface = interface
    self.name = name
  }

  /// Gets the value of the property.
  ///
  /// - Throws: `DBus.Error` if the property could not be retrieved.
  /// - Returns: The value of the property.
  public func get() throws(DBus.Error) -> T {
    (try methods.Get(interface, name) as Variant).value
  }

  /// Gets the value of the property asynchronously.
  ///
  /// - Throws: `DBus.Error` if the property could not be retrieved.
  /// - Returns: The value of the property.
  @available(macOS 10.15.0, *)
  public func get() async throws(DBus.Error) -> T {
    (try await methods.Get(interface, name) as Variant).value
  }

  /// Sets the value of the property.
  ///
  /// - Parameter value: The value to set.
  /// - Throws: `DBus.Error` if the property could not be set.
  public func set(_ value: T) throws(DBus.Error) {
    try methods.Set(interface, name, Variant(value)) as Void
  }

  /// Sets the value of the property asynchronously.
  ///
  /// - Parameter value: The value to set.
  /// - Throws: `DBus.Error` if the property could not be set.
  @available(macOS 10.15.0, *)
  public func set(_ value: T) async throws(DBus.Error) {
    try await methods.Set(interface, name, Variant(value)) as Void
  }

  /// Emits a signal that the property has changed.
  /// - Throws: `DBus.Error` if the signal could not be emitted.
  public func didChange() throws(DBus.Error) {
    try changedSignal.emit(interface, [String: Variant<T>](), [name])
  }

  /// Emits a signal that the property has changed, with the new value.
  /// - Parameter newValue: The new value of the property.
  /// - Throws: `DBus.Error` if the signal could not be emitted.
  public func didChange(_ newValue: T) throws(DBus.Error) {
    try changedSignal.emit(interface, [name: Variant(newValue)], [name])
  }

  /// Registers a handler for property changes.
  /// - Parameter handler: The handler to register.
  /// - Throws: `DBus.Error` if the handler could not be registered.
  /// - Returns: A function to unregister the handler.
  public func observe(
    _ handler: @escaping () -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try changedSignal.connect {
      (interface: InterfaceName, changed: [String: Variant<AnyArgument>], invalidated: [String]) in
      guard interface == self.interface else { return }
      if invalidated.contains(name) || changed.keys.contains(name) {
        handler()
      }
    }
  }

  /// Registers a handler for property changes, with the new value conveyed.
  /// - Parameter handler: The handler to register.
  /// - Throws: `DBus.Error` if the handler could not be registered.
  /// - Returns: A function to unregister the handler.
  public func observe(
    _ handler: @escaping (T) -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    try changedSignal.connect {
      (interface: InterfaceName, properties: [String: Variant<AnyArgument>], keys: [String]) in
      guard interface == self.interface else { return }
      do {
        guard let newValue: T = try properties[self.name]?.value.cast() else { return }
        handler(newValue)
      } catch {
        perror("[dbus] PropertyProxy: Failed to handle property change: \(error)")
      }
    }
  }

  /// Delegates the property to the specified accessor.
  /// - Parameters:
  ///   - get: The getter of the property.
  ///   - set: The setter of the property, nil if read-only.
  /// - Throws: `DBus.Error` if the accessor could not be registered.
  /// - Returns: A function to unregister the accessor.
  public func delegate(
    get: @escaping () -> T,
    set: ((T) -> Void)? = nil
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void {
    let accessor = (
      get: { get() },
      set: set.map { set in
        { (value: any Argument) in
          Result { () throws(DBus.Error) in set(try value.cast()) }
        }
      }
    )
    return try object.propertiesDelegate.register(
      interface: interface, name: name, accessor: accessor)
  }
}

/// Represents a read-only property of a D-Bus object.
public protocol ReadOnlyProperty<Value> {
  associatedtype Value: Argument

  /// Gets the value of the property.
  ///
  /// - Throws: `DBus.Error` if the property could not be retrieved.
  /// - Returns: The value of the property.
  func get() throws(DBus.Error) -> Value

  /// Gets the value of the property asynchronously.
  ///
  /// - Throws: `DBus.Error` if the property could not be retrieved.
  /// - Returns: The value of the property.
  func get() async throws(DBus.Error) -> Value
}

/// Represents a read-write property of a D-Bus object.
public protocol ReadWriteProperty<Value>: ReadOnlyProperty {
  /// Sets the value of the property.
  ///
  /// - Parameter value: The value to set.
  /// - Throws: `DBus.Error` if the property could not be set.
  func set(_ value: Value) throws(DBus.Error)

  /// Sets the value of the property asynchronously.
  ///
  /// - Parameter value: The value to set.
  /// - Throws: `DBus.Error` if the property could not be set.
  func set(_ value: Value) async throws(DBus.Error)
}

/// Represents an observable property of a D-Bus object.
public protocol ObservableReadOnlyProperty<Value>: ReadOnlyProperty {
  /// Registers a handler for property changes.
  /// - Parameter handler: The handler to register.
  /// - Throws: `DBus.Error` if the handler could not be registered.
  /// - Returns: A function to unregister the handler.
  func observe(
    _ handler: @escaping () -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void

  /// Registers a handler for property changes, with the new value conveyed.
  /// - Parameter handler: The handler to register.
  /// - Throws: `DBus.Error` if the handler could not be registered.
  /// - Returns: A function to unregister the handler.
  func observe(
    _ handler: @escaping (Value) -> Void
  ) throws(DBus.Error) -> () throws(DBus.Error) -> Void
}

/// Represents a read-write observable property of a D-Bus object.
public protocol ObservableReadWriteProperty<Value>: ObservableReadOnlyProperty, ReadWriteProperty {}
