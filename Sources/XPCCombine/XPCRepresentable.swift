#if canImport(XPC)

import Foundation
import XPC

// XPC primitive types
public protocol XPCRepresentable {
    
    var xpcObject: xpc_object_t { get }
}

extension Optional: XPCRepresentable where Wrapped: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        switch self {
        case let .some(obj): return obj.xpcObject
        case .none: return xpc_null_create()
        }
    }
}

extension Array: XPCRepresentable where Element: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        var values = map { $0.xpcObject }
        return xpc_array_create(&values, count)
    }
}

extension Dictionary: XPCRepresentable where Key == String, Value: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        let dict = xpc_dictionary_create(nil, nil, 0)
        for (key, value) in self {
            xpc_dictionary_set_value(dict, key, value.xpcObject)
        }
        return dict
    }
}

extension Bool: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        return xpc_bool_create(self)
    }
}

extension Int64: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        return xpc_int64_create(self)
    }
}

extension UInt64: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        return xpc_uint64_create(self)
    }
}

extension Double: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        return xpc_double_create(self)
    }
}

extension String: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        return xpc_string_create(self)
    }
}

extension Date: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        return xpc_date_create(Int64(timeIntervalSince1970))
    }
}

extension UUID: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        var arr = [UInt8](repeating: 0, count: 16)
        (self as NSUUID).getBytes(&arr)
        return xpc_uuid_create(&arr)
    }
}

extension Data: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        return self.withUnsafeBytes { ptr in
            return xpc_data_create(ptr.baseAddress, ptr.count)
        }
    }
}

extension FileHandle: XPCRepresentable {
    public var xpcObject: xpc_object_t {
        return xpc_fd_create(fileDescriptor) ?? xpc_null_create()
    }
}

#endif
