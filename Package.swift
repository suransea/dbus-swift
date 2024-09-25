// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DBus",
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "DBus",
      targets: ["DBus"]),
    .library(
      name: "CDBus",
      targets: ["CDBus"]),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "DBus", dependencies: ["CDBus"]),
    .target(
      name: "CDBus", dependencies: ["CDBusVendored", "CDBusSystem"]),
    .target(
      name: "CDBusVendored",
      path: "Sources/CDBusVendored",
      sources: CDBusVendored.sources.map { "dbus/dbus/\($0)" },
      cSettings: [
        .headerSearchPath("dbus")
      ] + CDBusVendored.defines),
    .systemLibrary(
      name: "CDBusSystem",
      pkgConfig: "dbus-1",
      providers: [
        .apt(["libdbus-1-dev"]),
        .yum(["dbus-devel"]),
        .brew(["dbus"]),
      ]),
    .testTarget(
      name: "DBusTests",
      dependencies: ["DBus"]
    ),
  ]
)

struct CDBusVendored {
  static let version = "1.14.10"
  static let versionMajor = 1
  static let versionMinor = 14
  static let versionMicro = 10

  static let commonSources = [
    // library sources
    "dbus-address.c",
    "dbus-auth.c",
    "dbus-bus.c",
    "dbus-connection.c",
    "dbus-credentials.c",
    "dbus-errors.c",
    "dbus-keyring.c",
    "dbus-marshal-header.c",
    "dbus-marshal-byteswap.c",
    "dbus-marshal-recursive.c",
    "dbus-marshal-validate.c",
    "dbus-message.c",
    "dbus-misc.c",
    "dbus-nonce.c",
    "dbus-object-tree.c",
    "dbus-pending-call.c",
    "dbus-resources.c",
    "dbus-server.c",
    "dbus-server-socket.c",
    "dbus-server-debug-pipe.c",
    "dbus-sha.c",
    "dbus-signature.c",
    "dbus-syntax.c",
    "dbus-timeout.c",
    "dbus-threads.c",
    "dbus-transport.c",
    "dbus-transport-socket.c",
    "dbus-watch.c",
    "dbus-dataslot.c",
    // shared sources
    "dbus-file.c",
    "dbus-hash.c",
    "dbus-internals.c",
    "dbus-list.c",
    "dbus-marshal-basic.c",
    "dbus-memory.c",
    "dbus-mempool.c",
    "dbus-string.c",
    "dbus-sysdeps.c",
    "dbus-pipe.c",
    // util sources
    "dbus-asv-util.c",
    "dbus-mainloop.c",
    "dbus-message-util.c",
    "dbus-shell.c",
    "dbus-pollable-set.c",
    "dbus-pollable-set-poll.c",
    "dbus-string-util.c",
    "dbus-sysdeps-util.c",
  ]

  static let unixSources = [
    "dbus-uuidgen.c",
    "dbus-transport-unix.c",
    "dbus-server-unix.c",
    "dbus-file-unix.c",
    "dbus-pipe-unix.c",
    "dbus-sysdeps-unix.c",
    "dbus-sysdeps-pthread.c",
    "dbus-userdb.c",
    "dbus-userdb-util.c",
    "dbus-sysdeps-util-unix.c",
  ]

  static let winSources = [
    "dbus-transport-win.c",
    "dbus-server-win.c",
    "dbus-file-win.c",
    "dbus-init-win.cpp",
    "dbus-sysdeps-win.c",
    "dbus-pipe-win.c",
    "dbus-sysdeps-thread-win.c",
    "dbus-spawn-win.c",
    "dbus-sysdeps-util-win.c",
    "dbus-sysdeps-wince-glue.c",
  ]

  static let linuxSources = [
    "dbus-pollable-set-epoll.c"
  ]

  static let macSources = [
    "dbus-server-launchd.c"
  ]

  static var sources: [String] {
    #if os(Linux)
      commonSources + unixSources + linuxSources
    #elseif os(macOS)
      commonSources + unixSources + macSources
    #elseif os(Windows)
      commonSources + winSources
    #else
      commonSources + unixSources
    #endif
  }

  // TODO: Generate configurations dynamically
  static let defines: [CSetting] = [
    .define("VERSION", to: "\"\(version)\""),
    .define("DBUS_MAJOR_VERSION", to: "\(versionMajor)"),
    .define("DBUS_MINOR_VERSION", to: "\(versionMinor)"),
    .define("DBUS_MICRO_VERSION", to: "\(versionMicro)"),
    .define(
      "DBUS_VERSION",
      to: "((DBUS_MAJOR_VERSION << 16) | (DBUS_MINOR_VERSION << 8) | DBUS_MICRO_VERSION)"),
    .define("DBUS_VERSION_STRING", to: "\"\(version)\""),
    .define("DBUS_COMPILATION"),
    .define("DBUS_UNIX", to: "1", .when(platforms: [.linux, .macOS, .openbsd])),
    .define("DBUS_WIN", to: "1", .when(platforms: [.windows])),
    .define("DBUS_EXEEXT", to: "\"\"", .when(platforms: [.linux, .macOS, .openbsd])),
    .define("DBUS_EXEEXT", to: "\".exe\"", .when(platforms: [.windows])),
    .define("DBUS_ENABLE_LAUNCHD", to: "1", .when(platforms: [.macOS])),
    .define("DBUS_ENABLE_VERBOSE_MODE", to: "1"),
    .define("DBUS_ENABLE_ASSERT", to: "1"),
    .define("DBUS_ENABLE_CHECKS", to: "1"),
    .define("DBUS_SIZEOF_VOID_P", to: "\(MemoryLayout<Int>.size)"),
    .define("DBUS_HAVE_LINUX_EPOLL", to: "1", .when(platforms: [.linux])),
    .define("HAVE_STDIO_H", to: "1"),
    .define("HAVE_ERRNO_H", to: "1"),
    .define("HAVE_DIRENT_H", to: "1"),
    .define("HAVE_STDINT_H", to: "1"),
    .define("HAVE_INTTYPES_H", to: "1"),
    .define("HAVE_STDLIB_H", to: "1"),
    .define("HAVE_STRING_H", to: "1"),
    .define("HAVE_STRINGS_H", to: "1"),
    .define("HAVE_ALLOCA_H", to: "1"),
    .define("HAVE_SOCKLEN_T", to: "1"),
    .define("HAVE_SOCKETPAIR", to: "1"),
    .define("HAVE_GETPWNAM_R", to: "1"),
    .define("HAVE_UNISTD_H", to: "1"),
    .define("HAVE_USLEEP", to: "1"),
    .define("HAVE_DECL_MSG_NOSIGNAL", to: "1"),
    .define("HAVE_UNIX_FD_PASSING", to: "1"),
    .define("DBUS_USE_SYNC", to: "1"),
    .define("DBUS_SESSION_BUS_CONNECT_ADDRESS", to: "\"autolaunch:\""),
    .define("DBUS_SYSTEM_BUS_DEFAULT_ADDRESS", to: "\"unix:path=/var/run/dbus/system_bus_socket\""),
    .define("DBUS_DATADIR", to: "\"/usr/share\""),
    .define("DBUS_SYSTEM_CONFIG_FILE", to: "\"/usr/share/dbus-1/system.conf\""),
    .define("DBUS_SESSION_CONFIG_FILE", to: "\"/usr/share/dbus-1/session.conf\""),
    .define("DBUS_MACHINE_UUID_FILE", to: "\"/etc/machine-id\""),
    .define("DBUS_SESSION_SOCKET_DIR", to: "\"/tmp\""),
  ]
}
