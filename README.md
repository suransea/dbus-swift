# dbus-swift

![Github Release](https://flat.badgen.net/github/release/suransea/dbus-swift)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/suransea/dbus-swift/swift.yml?style=flat-square)](https://github.com/suransea/dbus-swift/actions)
![GitHub License](https://img.shields.io/github/license/suransea/dbus-swift?style=flat-square)
[![Swift Version Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsuransea%2Fdbus-swift%2Fbadge%3Ftype%3Dswift-versions&style=flat-square)](https://swiftpackageindex.com/suransea/dbus-swift)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsuransea%2Fdbus-swift%2Fbadge%3Ftype%3Dplatforms&style=flat-square)](https://swiftpackageindex.com/suransea/dbus-swift)

[D-Bus](https://www.freedesktop.org/wiki/Software/dbus/) bindings for Swift.

## Documentation

The [API Documentation](https://swiftpackageindex.com/suransea/dbus-swift/main/documentation/dbus) is available on Swift Package Index.

## Examples

### Client

```swift
let connection = try Connection(type: .session)
try connection.setupDispatch(with: DispatchQueue.main)
let object = ObjectProxy(
  connection: connection,
  destination: "com.example.Foo",
  path: "/com/example/Foo"
)

// Call methods
let methods = object.methods(interface: "com.example.Foo")
// Using `dynamic member lookup` and `callAsFunction`, this is equivalent to
// `try await methods[dynamicMember: "Foo"].callAsFunction("one", 2, 3.0) as Void`
try await methods.Foo("one", 2 as Int32, 3.0) as Void  // no return value
let foo: [String] = try await methods.Bar("one", 2 as Int32, 3.0)  // single return value
let (bar, baz): (String, Int32) = try await methods.Baz("one", 2 as Int32, 3.0)  // multiple return values

// Get properties
let properties = object.properties(interface: "com.example.Foo")
let foo: String = try await properties.Foo.get()

// Set properties
try await properties.Foo.set("bar")

// Observe property changes
let bus = Bus(connection: connection)
try await bus.addMatch(
  MatchRule(
    type: .signal,
    path: "/com/example/Foo",
    interface: .properties,
    member: "PropertiesChanged"
  )
)
_ = try properties.Foo.observe { (newValue: String) in
  // ...
}
```

### Server

```swift
let connection = try Connection(type: .session, private: true)
try connection.setupDispatch(with: DispatchQueue.main)
let bus = Bus(connection: connection)
_ = try await bus.requestName("com.example.Foo", .doNotQueue)
let object = ObjectProxy(connection: connection, path: "/com/example/Foo")

// Handle method calls
let methods = object.methods(interface: "com.example.Foo")
func foo(a: String, b: Int32, c: Double) throws(DBus.Error) {
  // ...
}
_ = try methods.Foo.delegate(to: foo)
// or use a closure
_ = try methods.Bar.delegate {
  (a: String, b: Int32, c: Double) throws(DBus.Error) -> [String] in
  return ["qux", "quux"]
}
_ = try methods.Baz.delegate {
  (a: String, b: Int32, c: Double) throws(DBus.Error) -> (String, Int32) in
  return ("qux", 0)
}

// Provide properties
let properties = object.properties(interface: "com.example.Interface")
var foo: String = "foo"
_ = try properties.Foo.delegate(
  get: { foo },
  set: { newValue in foo = newValue }
)

// Notify property changes
try properties.Foo.didChange("bar")
```

### Signals

```swift
let connection = try Connection(type: .session)
try connection.setupDispatch(with: DispatchQueue.main)
let object = ObjectProxy(connection: connection, path: "/com/example/Foo")

// Emit signals
let signals = object.signals(interface: "com.example.Foo")
try signals.Foo.emit("one", 2 as Int32)

// Connect to signals
let bus = Bus(connection: connection)
try await bus.addMatch(MatchRule(type: .signal, path: "/com/example/Foo"))
_ = try signals.Foo.connect { (a: String, b: Int32) in
  // ...
}
```

## Data Types

Conforming to `Argument` protocol, the following Swift types can be used as D-Bus arguments:

| Swift Type            | D-Bus Type            | D-Bus Signature | Notes                                   |
| --------------------- | --------------------- | --------------- | --------------------------------------- |
| `Swift.UInt8`         | `BYTE`                | `y`             |                                         |
| `Swift.Bool`          | `BOOLEAN`             | `b`             |                                         |
| `Swift.Int16`         | `INT16`               | `n`             |                                         |
| `Swift.UInt16`        | `UINT16`              | `q`             |                                         |
| `Swift.Int32`         | `INT32`               | `i`             |                                         |
| `Swift.UInt32`        | `UINT32`              | `u`             |                                         |
| `Swift.Int64`         | `INT64`               | `x`             |                                         |
| `Swift.UInt64`        | `UINT64`              | `t`             |                                         |
| `Swift.Double`        | `DOUBLE`              | `d`             |                                         |
| `Swift.String`        | `STRING`              | `s`             |                                         |
| `DBus.ObjectPath`     | `OBJECT_PATH`         | `o`             |                                         |
| `DBus.Signature`      | `SIGNATURE`           | `g`             |                                         |
| `Swift.Array`         | `ARRAY`               | `a`             | Array.Element is some `Argument`        |
| `DBus.DictEntry`      | `DICT_ENTRY`          | `{kv}`          |                                         |
| `Swift.Dictionary`    | `ARRAY of DICT_ENTRY` | `a{kv}`         | Dictionary.Key/Value is some `Argument` |
| `DBus.Struct`         | `STRUCT`              | `(...)`         |                                         |
| `DBus.AnyStruct`      | `STRUCT`              | `(...)`         |                                         |
| `DBus.Variant`        | `VARIANT`             | `v`             |                                         |
| `DBus.FileDescriptor` | `UNIX_FD`             | `h`             |                                         |

Custom types can be used as D-Bus arguments by conforming to `Argument` protocol.

Sometimes, we cannot know the argument type at compile-time, consider using `DBus.AnyArgument`.

## CDBus

The `CDBus` target is a C module for `libdbus`.
It is used by the `DBus` target to provide a Swift binding to D-Bus.

By default, `CDBus` uses the vendored `libdbus` source code.
You can also use the system `libdbus` by adding the `CDBUS_SYSTEM` define to the build settings:

```shell
swift build -Xswiftc -DCDBUS_SYSTEM
```

## License

[MIT license](LICENSE)
