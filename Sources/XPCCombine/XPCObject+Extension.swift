#if canImport(XPC)

import Foundation
import XPC

// MARK: - Object

func ==(lhs: xpc_object_t, rhs: xpc_object_t) -> Bool {
    return xpc_equal(lhs, rhs)
}

func ~=(pattern: xpc_object_t, value: xpc_object_t) -> Bool {
    return pattern == value
}

func ~=(pattern: xpc_type_t, value: xpc_object_t) -> Bool {
    return value.rawXPCType == pattern
}

extension xpc_object_t {
    
    var rawXPCType: xpc_type_t {
        return xpc_get_type(self)
    }
    
    var xpcType: XPCType {
        return XPCType(rawValue: rawXPCType)!
    }
    
    func isEqual(to obj: xpc_object_t) -> Bool {
        return xpc_equal(self, obj)
    }
    
    var hash: Int {
        return xpc_hash(self)
    }
    
    var isNull: Bool {
        return xpcType == .null
    }
    
    var arrayCount: Int {
        return xpc_array_get_count(self)
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
    
    subscript(xpcArrayIdx: Int) -> xpc_object_t {
        get {
            xpc_array_get_value(self, xpcArrayIdx)
        }
        set {
            xpc_array_set_value(self, xpcArrayIdx, newValue)
        }
    }
    
    var dictionaryCount: Int {
        return xpc_dictionary_get_count(self)
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
    
    subscript(xpcDictionaryKey: String) -> xpc_object_t? {
        get {
            xpc_dictionary_get_value(self, xpcDictionaryKey)
        }
        set {
            xpc_dictionary_set_value(self, xpcDictionaryKey, newValue)
        }
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
}

// MARK: Connection

extension xpc_connection_t {
    
    func connectionSuspend() {
        xpc_connection_suspend(self)
    }
    
    func connectionResume() {
        xpc_connection_resume(self)
    }
    
    func connectionCancel() {
        xpc_connection_cancel(self)
    }
    
    func connectionSend(_ message: xpc_object_t) {
        xpc_connection_send_message(self, message)
    }
    
    var connectionContext: UnsafeMutableRawPointer? {
        get {
            xpc_connection_get_context(self)
        }
        set {
            xpc_connection_set_context(self, newValue)
        }
    }
}

#endif
