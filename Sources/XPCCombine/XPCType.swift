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

#endif
