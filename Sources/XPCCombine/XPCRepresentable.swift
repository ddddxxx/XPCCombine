#if canImport(XPC)

import Foundation
import XPC

// XPC primitive types
public protocol XPCRepresentable {
    
    var xpcObject: xpc_object_t { get }
    
    // with type check
    func fromXPC(_ xpcObject: xpc_object_t) -> Self?
}

extension Bool: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        return xpc_bool_create(self)
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .bool else {
            return nil
        }
        return xpcObject.boolValue
    }
}

extension Int64: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        return xpc_int64_create(self)
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .int64 else {
            return nil
        }
        return xpcObject.int64Value
    }
}

extension UInt64: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        return xpc_uint64_create(self)
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .uint64 else {
            return nil
        }
        return xpcObject.uint64Value
    }
}

extension Double: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        return xpc_double_create(self)
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .double else {
            return nil
        }
        return xpcObject.doubleValue
    }
}

extension String: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        return xpc_string_create(self)
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .string else {
            return nil
        }
        return xpcObject.stringValue
    }
}

extension Date: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        return xpc_date_create(Int64(timeIntervalSince1970))
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .date else {
            return nil
        }
        return xpcObject.dateValue
    }
}

extension UUID: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        var arr = [UInt8](repeating: 0, count: 16)
        (self as NSUUID).getBytes(&arr)
        return xpc_uuid_create(&arr)
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .uuid else {
            return nil
        }
        return xpcObject.uuidValue
    }
}

extension Data: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        return self.withUnsafeBytes { ptr in
            return xpc_data_create(ptr.baseAddress, ptr.count)
        }
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .data else {
            return nil
        }
        return xpcObject.dataValue
    }
}

extension FileHandle: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        return xpc_fd_create(fileDescriptor) ?? xpc_null_create()
    }
    
    public func fromXPC(_ xpcObject: xpc_object_t) -> Self? {
        guard xpcObject.xpcType == .fileHandle else {
            return nil
        }
        let fd = xpc_fd_dup(xpcObject)
        guard fd != -1 else {
            return nil
        }
        return Self.init(fileDescriptor: fd)
    }
}

#endif
