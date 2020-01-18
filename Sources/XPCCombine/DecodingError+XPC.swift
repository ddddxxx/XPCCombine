#if canImport(XPC)

import XPC

extension DecodingError {
    
    static func xpcTypeMismatch(at path: [CodingKey], expectation: XPCType, reality: XPCType) -> DecodingError {
        let description = "Expected to decode XPC type \(expectation) but found \(reality) instead."
        return .typeMismatch(xpc_type_t.self, Context(codingPath: path, debugDescription: description))
    }
    
    static func xpcNullValue(at path: [CodingKey], expectation: Any.Type) -> DecodingError {
        return .valueNotFound(expectation, DecodingError.Context(codingPath: path, debugDescription: "Expected \(expectation) value but found xpc null instead."))
    }
}

#endif
