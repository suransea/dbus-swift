import CDBus

public struct Error: Swift.Error, Equatable, Hashable {
  public let name: ErrorName
  public let message: String
}

extension Error: CustomStringConvertible {
  public var description: String {
    "\(name): \(message)"
  }
}

public struct ErrorName: Sendable, Equatable, Hashable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension ErrorName: CustomStringConvertible {
  public var description: String {
    rawValue
  }
}

/// Error names, see https://dbus.freedesktop.org/doc/dbus-specification.html#message-protocol-names-error
extension ErrorName {
  /// A generic error; "something went wrong" - see the error message for more.
  public static let failed = ErrorName(rawValue: DBUS_ERROR_FAILED)
  /// There was not enough memory to complete an operation.
  public static let noMemory = ErrorName(rawValue: DBUS_ERROR_NO_MEMORY)
  /// The bus doesn't know how to launch a service to supply the bus name you wanted.
  public static let serviceUnknown = ErrorName(rawValue: DBUS_ERROR_SERVICE_UNKNOWN)
  /// The bus name you referenced doesn't exist (i.e. no application owns it).
  public static let nameHasNoOwner = ErrorName(rawValue: DBUS_ERROR_NAME_HAS_NO_OWNER)
  /// No reply to a message expecting one, usually means a timeout occurred.
  public static let noReply = ErrorName(rawValue: DBUS_ERROR_NO_REPLY)
  /// Something went wrong reading or writing to a socket, for example.
  public static let ioError = ErrorName(rawValue: DBUS_ERROR_IO_ERROR)
  /// A D-Bus bus address was malformed.
  public static let badAddress = ErrorName(rawValue: DBUS_ERROR_BAD_ADDRESS)
  /// Requested operation isn't supported (like ENOSYS on UNIX).
  public static let notSupported = ErrorName(rawValue: DBUS_ERROR_NOT_SUPPORTED)
  /// Some limited resource is exhausted.
  public static let limitsExceeded = ErrorName(rawValue: DBUS_ERROR_LIMITS_EXCEEDED)
  /// Security restrictions don't allow doing what you're trying to do.
  public static let accessDenied = ErrorName(rawValue: DBUS_ERROR_ACCESS_DENIED)
  /// Authentication didn't work.
  public static let authFailed = ErrorName(rawValue: DBUS_ERROR_AUTH_FAILED)
  /// Unable to connect to server (probably caused by ECONNREFUSED on a socket).
  public static let noServer = ErrorName(rawValue: DBUS_ERROR_NO_SERVER)
  /// Certain timeout errors, possibly ETIMEDOUT on a socket.
  /// Note that `DBUS_ERROR_NO_REPLY` is used for message reply timeouts.
  /// @warning this is confusingly-named given that `DBUS_ERROR_TIMED_OUT` also exists. We can't fix
  /// it for compatibility reasons so just be careful.
  public static let timeout = ErrorName(rawValue: DBUS_ERROR_TIMEOUT)
  /// No network access (probably ENETUNREACH on a socket).
  public static let noNetwork = ErrorName(rawValue: DBUS_ERROR_NO_NETWORK)
  /// Can't bind a socket since its address is in use (i.e. EADDRINUSE).
  public static let addressInUse = ErrorName(rawValue: DBUS_ERROR_ADDRESS_IN_USE)
  /// The connection is disconnected and you're trying to use it.
  public static let disconnected = ErrorName(rawValue: DBUS_ERROR_DISCONNECTED)
  /// Invalid arguments passed to a method call.
  public static let invalidArgs = ErrorName(rawValue: DBUS_ERROR_INVALID_ARGS)
  /// Missing file.
  public static let fileNotFound = ErrorName(rawValue: DBUS_ERROR_FILE_NOT_FOUND)
  /// Existing file and the operation you're using does not silently overwrite.
  public static let fileExists = ErrorName(rawValue: DBUS_ERROR_FILE_EXISTS)
  /// Method name you invoked isn't known by the object you invoked it on.
  public static let unknownMethod = ErrorName(rawValue: DBUS_ERROR_UNKNOWN_METHOD)
  /// Object you invoked a method on isn't known.
  public static let unknownObject = ErrorName(rawValue: DBUS_ERROR_UNKNOWN_OBJECT)
  /// Interface you invoked a method on isn't known by the object.
  public static let unknownInterface = ErrorName(rawValue: DBUS_ERROR_UNKNOWN_INTERFACE)
  /// Property you tried to access isn't known by the object.
  public static let unknownProperty = ErrorName(rawValue: DBUS_ERROR_UNKNOWN_PROPERTY)
  /// Property you tried to set is read-only.
  public static let propertyReadOnly = ErrorName(rawValue: DBUS_ERROR_PROPERTY_READ_ONLY)
  /// Certain timeout errors, e.g. while starting a service.
  /// @warning this is confusingly-named given that #DBUS_ERROR_TIMEOUT also exists. We can't fix
  /// it for compatibility reasons so just be careful.
  public static let timedOut = ErrorName(rawValue: DBUS_ERROR_TIMED_OUT)
  /// Tried to remove or modify a match rule that didn't exist.
  public static let matchRuleNotFound = ErrorName(rawValue: DBUS_ERROR_MATCH_RULE_NOT_FOUND)
  /// The match rule isn't syntactically valid.
  public static let matchRuleInvalid = ErrorName(rawValue: DBUS_ERROR_MATCH_RULE_INVALID)
  /// While starting a new process, the exec() call failed.
  public static let spawnExecFailed = ErrorName(rawValue: DBUS_ERROR_SPAWN_EXEC_FAILED)
  /// While starting a new process, the fork() call failed.
  public static let spawnForkFailed = ErrorName(rawValue: DBUS_ERROR_SPAWN_FORK_FAILED)
  /// While starting a new process, the child exited with a status code.
  public static let spawnChildExited = ErrorName(rawValue: DBUS_ERROR_SPAWN_CHILD_EXITED)
  /// While starting a new process, the child exited on a signal.
  public static let spawnChildSignaled = ErrorName(rawValue: DBUS_ERROR_SPAWN_CHILD_SIGNALED)
  /// While starting a new process, something went wrong.
  public static let spawnFailed = ErrorName(rawValue: DBUS_ERROR_SPAWN_FAILED)
  /// We failed to setup the environment correctly.
  public static let spawnSetupFailed = ErrorName(rawValue: DBUS_ERROR_SPAWN_SETUP_FAILED)
  /// We failed to setup the config parser correctly.
  public static let spawnConfigInvalid = ErrorName(rawValue: DBUS_ERROR_SPAWN_CONFIG_INVALID)
  /// Bus name was not valid.
  public static let spawnServiceInvalid = ErrorName(rawValue: DBUS_ERROR_SPAWN_SERVICE_INVALID)
  /// Service file not found in system-services directory.
  public static let spawnServiceNotFound = ErrorName(
    rawValue: DBUS_ERROR_SPAWN_SERVICE_NOT_FOUND)
  /// Permissions are incorrect on the setuid helper.
  public static let spawnPermissionsInvalid = ErrorName(
    rawValue: DBUS_ERROR_SPAWN_PERMISSIONS_INVALID)
  /// Service file invalid (Name, User or Exec missing).
  public static let spawnFileInvalid = ErrorName(rawValue: DBUS_ERROR_SPAWN_FILE_INVALID)
  /// There was not enough memory to complete the operation.
  public static let spawnNoMemory = ErrorName(rawValue: DBUS_ERROR_SPAWN_NO_MEMORY)
  /// Tried to get a UNIX process ID and it wasn't available.
  public static let unixProcessIdUnknown = ErrorName(
    rawValue: DBUS_ERROR_UNIX_PROCESS_ID_UNKNOWN)
  /// A type signature is not valid.
  public static let invalidSignature = ErrorName(rawValue: DBUS_ERROR_INVALID_SIGNATURE)
  /// A file contains invalid syntax or is otherwise broken.
  public static let invalidFileContent = ErrorName(rawValue: DBUS_ERROR_INVALID_FILE_CONTENT)
  /// Asked for SELinux security context and it wasn't available.
  public static let selinuxSecurityContextUnknown = ErrorName(
    rawValue: DBUS_ERROR_SELINUX_SECURITY_CONTEXT_UNKNOWN)
  /// Asked for ADT audit data and it wasn't available.
  public static let adtAuditDataUnknown = ErrorName(
    rawValue: DBUS_ERROR_ADT_AUDIT_DATA_UNKNOWN)
  /// There's already an object with the requested object path.
  public static let objectPathInUse = ErrorName(rawValue: DBUS_ERROR_OBJECT_PATH_IN_USE)
  /// The message meta data does not match the payload. e.g. expected
  /// number of file descriptors were not sent over the socket this message was received on.
  public static let inconsistentMessage = ErrorName(rawValue: DBUS_ERROR_INCONSISTENT_MESSAGE)
  /// The message is not allowed without performing interactive authorization,
  /// but could have succeeded if an interactive authorization step was
  /// allowed.
  public static let interactiveAuthorizationRequired = ErrorName(
    rawValue: DBUS_ERROR_INTERACTIVE_AUTHORIZATION_REQUIRED)
  /// The connection is not from a container, or the specified container instance
  /// does not exist.
  public static let notContainer = ErrorName(rawValue: DBUS_ERROR_NOT_CONTAINER)
}

class RawError {
  var raw: DBusError

  init() {
    raw = DBusError()
    dbus_error_init(&raw)
  }

  deinit {
    dbus_error_free(&raw)
  }

  var name: String {
    String(cString: raw.name)
  }

  var message: String {
    String(cString: raw.message)
  }

  var isSet: Bool {
    dbus_error_is_set(&raw) != 0
  }

  func hasName(_ name: String) -> Bool {
    dbus_error_has_name(&raw, name) != 0
  }
}

extension Error {
  init?(_ error: RawError) {
    guard error.isSet else { return nil }
    name = ErrorName(rawValue: error.name)
    message = error.message
  }
}
