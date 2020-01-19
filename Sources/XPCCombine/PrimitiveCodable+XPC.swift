#if canImport(XPC)

import XPC

protocol PrimitiveXPCCodable {
    
    static var primitiveXPCType: XPCType { get }
    
    var encodedXPC: xpc_object_t { get }
    
    // without type check
    init?(docedeXPC xpcObject: xpc_object_t)
}

extension PrimitiveXPCCodable where Self: FixedWidthInteger & SignedInteger {
    
    static var primitiveXPCType: XPCType {
        return .int64
    }
    
    var encodedXPC: xpc_object_t {
        return Int64(self).xpcObject
    }
    
    init?(docedeXPC xpcObject: xpc_object_t) {
        self.init(exactly: xpcObject.int64Value)
    }
}

extension PrimitiveXPCCodable where Self: FixedWidthInteger & UnsignedInteger {
    
    static var primitiveXPCType: XPCType {
        return .uint64
    }
    
    var encodedXPC: xpc_object_t {
        return UInt64(self).xpcObject
    }
    
    init?(docedeXPC xpcObject: xpc_object_t) {
        self.init(exactly: xpcObject.uint64Value)
    }
}

extension PrimitiveCodable where Self: BinaryFloatingPoint {
    
    static var primitiveXPCType: XPCType {
        return .double
    }
    
    var encodedXPC: xpc_object_t {
        return Double(self).xpcObject
    }
    
    init?(docedeXPC xpcObject: xpc_object_t) {
        self.init(xpcObject.doubleValue)
    }
}

extension Int   : PrimitiveXPCCodable {}
extension Int8  : PrimitiveXPCCodable {}
extension Int16 : PrimitiveXPCCodable {}
extension Int32 : PrimitiveXPCCodable {}
extension Int64 : PrimitiveXPCCodable {}
extension UInt  : PrimitiveXPCCodable {}
extension UInt8 : PrimitiveXPCCodable {}
extension UInt16: PrimitiveXPCCodable {}
extension UInt32: PrimitiveXPCCodable {}
extension UInt64: PrimitiveXPCCodable {}
extension Float : PrimitiveXPCCodable {}
extension Double: PrimitiveXPCCodable {}

extension Bool: PrimitiveXPCCodable {
    
    static var primitiveXPCType = XPCType.bool
    
    var encodedXPC: xpc_object_t {
        return xpcObject
    }
    
    init?(docedeXPC xpcObject: xpc_object_t) {
        self = xpcObject.boolValue
    }
}

extension String: PrimitiveXPCCodable {
    
    static var primitiveXPCType = XPCType.string
    
    var encodedXPC: xpc_object_t {
        return xpcObject
    }
    
    init?(docedeXPC xpcObject: xpc_object_t) {
        guard let v = xpcObject.stringValue else {
            return nil
        }
        self = v
    }
}

#endif
