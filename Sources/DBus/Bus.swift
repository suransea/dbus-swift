import CDBus

public enum BusType: UInt32 {
  case session
  case system
  case starter
}

extension DBusBusType {
  init(_ type: BusType) {
    self.init(rawValue: type.rawValue)
  }
}

public typealias BusName = String

public typealias Interface = String

public typealias Member = String
