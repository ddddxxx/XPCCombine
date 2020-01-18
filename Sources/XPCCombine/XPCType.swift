#if canImport(XPC)

import Foundation
import XPC

public enum XPCType {
    
    case null, array, dictionary, bool, int64, uint64, double, string, date, uuid, data, fileHandle, shmem, connection, endpoint, activity
}

extension XPCType: RawRepresentable {
    
    public var rawValue: xpc_type_t {
        switch self {
        case .null: return XPC_TYPE_NULL
        case .array: return XPC_TYPE_ARRAY
        case .dictionary: return XPC_TYPE_DICTIONARY
        case .bool: return XPC_TYPE_BOOL
        case .int64: return XPC_TYPE_INT64
        case .uint64: return XPC_TYPE_UINT64
        case .double: return XPC_TYPE_DOUBLE
        case .string: return XPC_TYPE_STRING
        case .date: return XPC_TYPE_DATE
        case .uuid: return XPC_TYPE_UUID
        case .data: return XPC_TYPE_DATA
        case .fileHandle: return XPC_TYPE_FD
        case .shmem: return XPC_TYPE_SHMEM
        case .connection: return XPC_TYPE_CONNECTION
        case .endpoint: return XPC_TYPE_ENDPOINT
        case .activity: return XPC_TYPE_ACTIVITY
        }
    }
    
    public init?(rawValue: xpc_type_t) {
        switch rawValue {
        case XPC_TYPE_NULL: self = .null
        case XPC_TYPE_ARRAY: self = .array
        case XPC_TYPE_DICTIONARY: self = .dictionary
        case XPC_TYPE_BOOL: self = .bool
        case XPC_TYPE_INT64: self = .int64
        case XPC_TYPE_UINT64: self = .uint64
        case XPC_TYPE_DOUBLE: self = .double
        case XPC_TYPE_STRING: self = .string
        case XPC_TYPE_DATE: self = .date
        case XPC_TYPE_UUID: self = .uuid
        case XPC_TYPE_DATA: self = .data
        case XPC_TYPE_FD: self = .fileHandle
        case XPC_TYPE_SHMEM: self = .shmem
        case XPC_TYPE_CONNECTION: self = .connection
        case XPC_TYPE_ENDPOINT: self = .endpoint
        case XPC_TYPE_ACTIVITY: self = .activity
        default: return nil
        }
    }
}

public extension xpc_object_t {
    
    var xpcType: XPCType {
        return XPCType(rawValue: xpc_get_type(self))!
    }
    
    var isNull: Bool {
        return xpcType == .null
    }
    
    var arrayValue: [xpc_object_t] {
        let count = xpc_array_get_count(self)
        var arr = [xpc_object_t]()
        arr.reserveCapacity(count)
        xpc_array_apply(self) { idx, obj -> Bool in
            arr[idx] = obj
            return true
        }
        return arr
    }
    
    var dictionaryValue: [String: xpc_object_t] {
        let count = xpc_dictionary_get_count(self)
        var dict = [String: xpc_object_t](minimumCapacity: count)
        xpc_dictionary_apply(self) { key, obj -> Bool in
            dict[String(cString: key)] = obj
            return true
        }
        return dict
    }
    
    var boolValue: Bool {
        return xpc_bool_get_value(self)
    }
    
    var int64Value: Int64 {
        return xpc_int64_get_value(self)
    }
    
    var uint64Value: UInt64 {
        return xpc_uint64_get_value(self)
    }
    
    var doubleValue: Double {
        return xpc_double_get_value(self)
    }
    
    var stringValue: String? {
        guard let ptr = xpc_string_get_string_ptr(self) else {
            return nil
        }
        return String(cString: ptr)
    }
    
    var dateValue: Date {
        let ti = xpc_date_get_value(self)
        return Date(timeIntervalSince1970: TimeInterval(ti))
    }
    
    var uuidValue: UUID? {
        guard let bytes = xpc_uuid_get_bytes(self) else {
            return nil
        }
        return NSUUID(uuidBytes: bytes) as UUID
    }
    
    var dataValue: Data? {
        let len = xpc_data_get_length(self)
        if let bytes = xpc_data_get_bytes_ptr(self) {
            return Data(bytes: bytes, count: len)
        } else if len == 0 {
            return Data()
        } else {
            return nil
        }
    }
    
    var fileHandleValue: FileHandle? {
        let fd = xpc_fd_dup(self)
        guard fd != -1 else {
            return nil
        }
        return FileHandle(fileDescriptor: fd)
    }
    
    var asConnection: xpc_connection_t? {
        guard xpcType == .connection else {
            return nil
        }
        return self
    }
    
    var asEndpoint: xpc_endpoint_t? {
        guard xpcType == .endpoint else {
            return nil
        }
        return self
    }
    
    var asActivity: xpc_activity_t? {
        guard xpcType == .activity else {
            return nil
        }
        return self
    }
    
    var arrayCount: Int {
        return xpc_array_get_count(self)
    }
    
    var dictionaryCount: Int {
        return xpc_dictionary_get_count(self)
    }
    
    subscript(xpcArrayIdx: Int) -> xpc_object_t {
        get {
            xpc_array_get_value(self, xpcArrayIdx)
        }
        set {
            xpc_array_set_value(self, xpcArrayIdx, newValue)
        }
    }
    
    subscript(xpcDictionaryKey: String) -> xpc_object_t? {
        get {
            xpc_dictionary_get_value(self, xpcDictionaryKey)
        }
        set {
            xpc_dictionary_set_value(self, xpcDictionaryKey, newValue)
        }
    }
}

#endif
