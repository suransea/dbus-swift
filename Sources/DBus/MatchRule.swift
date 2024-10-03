/// A structure representing a match rule for messages bus.
/// See https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-routing-match-rules
public struct MatchRule {
  /// The type of the message.
  public var type: MessageType?
  /// The sender of the message.
  public var sender: BusName?
  /// The object path of the message.
  public var path: ObjectPath?
  /// The namespace of the object path.
  public var pathNamespace: ObjectPath?
  /// The destination of the message.
  public var destination: BusName?
  /// The interface of the message.
  public var interface: InterfaceName?
  /// The member (method or signal) of the message.
  public var member: MemberName?
  /// Whether eavesdrop messages.
  public var eavesdrop: Bool?

  /// Initializes a new `MatchRule` with the given parameters.
  /// - Parameters:
  ///   - type: The type of the message.
  ///   - sender: The sender of the message.
  ///   - path: The object path of the message.
  ///   - pathNamespace: The namespace of the object path.
  ///   - destination: The destination of the message.
  ///   - interface: The interface of the message.
  ///   - member: The member (method or signal) of the message.
  ///   - eavesdrop: Whether eavesdrop messages.
  public init(
    type: MessageType? = nil,
    sender: BusName? = nil,
    path: ObjectPath? = nil,
    pathNamespace: ObjectPath? = nil,
    destination: BusName? = nil,
    interface: InterfaceName? = nil,
    member: MemberName? = nil,
    eavesdrop: Bool? = nil
  ) {
    self.type = type
    self.sender = sender
    self.path = path
    self.pathNamespace = pathNamespace
    self.destination = destination
    self.interface = interface
    self.member = member
    self.eavesdrop = eavesdrop
  }
}

extension MatchRule {
  /// A string representation of the message type.
  var typeString: String? {
    guard let type else { return nil }
    return switch type {
    case .methodCall: "method_call"
    case .methodReturn: "method_return"
    case .error: "error"
    case .signal: "signal"
    case .invalid: nil
    }
  }

  /// Encodes the match rule into a string representation.
  ///
  /// - Returns: A string representation of the match rule.
  public func encode() -> String {
    var components: [(key: String, value: String)] = []
    if let typeString {
      components.append(("type", typeString))
    }
    if let sender {
      components.append(("sender", sender.rawValue))
    }
    if let path {
      components.append(("path", path.rawValue))
    }
    if let pathNamespace {
      components.append(("path_namespace", pathNamespace.rawValue))
    }
    if let destination {
      components.append(("destination", destination.rawValue))
    }
    if let interface {
      components.append(("interface", interface.rawValue))
    }
    if let member {
      components.append(("member", member.rawValue))
    }
    if let eavesdrop {
      components.append(("eavesdrop", eavesdrop ? "true" : "false"))
    }
    return components.map { (key, value) in "\(key)='\(value)'" }.joined(separator: ",")
  }
}

extension MatchRule: Argument {
  public static var type: ArgumentType { .string }

  public init(from iter: inout MessageIterator) throws(DBus.Error) {
    fatalError("Not implemented")  // `MatchRule` is not currently used for input arguments.
  }

  public func append(to iter: inout MessageIterator) throws(Error) {
    try encode().append(to: &iter)
  }
}
