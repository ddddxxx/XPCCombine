#if canImport(XPC)

import Foundation
import XPC

public enum XPCError: Error {
    case connectionInterrupted
    case connectionInvalid
    case terminationImminent
}

extension XPCError: XPCRepresentable {
    
    public var xpcObject: xpc_object_t {
        switch self {
        case .connectionInterrupted: return XPC_ERROR_CONNECTION_INTERRUPTED
        case .connectionInvalid: return XPC_ERROR_CONNECTION_INVALID
        case .terminationImminent: return XPC_ERROR_TERMINATION_IMMINENT
        }
    }
    
    public static func fromXPC(_ xpcObject: xpc_object_t) -> XPCError? {
        switch xpcObject {
        case XPC_ERROR_CONNECTION_INTERRUPTED: return .connectionInterrupted
        case XPC_ERROR_CONNECTION_INVALID: return .connectionInvalid
        case XPC_ERROR_TERMINATION_IMMINENT: return .terminationImminent
        default: fatalError("unexpected XPC error \(xpcObject)")
        }
    }
}

#endif
