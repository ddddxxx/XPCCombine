#if canImport(XPC)

import Foundation
import XPC
import CXShim

/// `XPCEncoder` facilitates the encoding of `Encodable` values into XPC object.
open class XPCEncoder: TopLevelEncoder {
    
    /// The strategy to use for non-XPC-message-conforming object values (XPC message must be a dictionary object).
    public enum XPCMessageWrapingStrategy {
        
        /// Throw upon encountering non-conforming values. This is the default strategy.
        case `throw`
        
        /// Wrap the object in a dictionary with specified key.
        case wrap(singleValueDictionaryKey: String)
        
        /// Wrap the non-dictionary object in a dictionary with specified key.
        case wrapIfNeeded(singleValueDictionaryKey: String)
        
        /// return the fragile object that not ready for XPC transmission.
        case `return`
    }
    
    /// Contextual user-provided information for use during encoding.
    open var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// The strategy to use in wrapping invalid XPC message. Defaults to `.throw`.
    open var xpcMessageWrapingStrategy: XPCMessageWrapingStrategy = .`throw`
    
    public init() {}
    
    /// Encodes the given top-level value and returns its XPC representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `xpc_object_t` value containing the encoded XPC data.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T: Encodable>(_ value: T) throws -> xpc_object_t {
        let encoder = _XPCEncoder(userInfo: userInfo)
        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }
        switch (xpcMessageWrapingStrategy, topLevel.xpcType == .dictionary) {
        case (.throw, false):
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) not encoded as dictionary XPC object."))
        case let (.wrapIfNeeded(singleValueDictionaryKey: key), false),
             let (.wrap(singleValueDictionaryKey: key), _):
            let wrapper = xpc_dictionary_create(nil, nil, 0)
            wrapper[key] = topLevel
            return wrapper
        default:
            return topLevel
        }
    }
}

// MARK: - _XPCEncoder

private class _XPCEncoder: Encoder {
    
    var storage: _XPCEncodingStorage
    
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey: Any]
    
    init(codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.storage = _XPCEncodingStorage()
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    var canEncodeNewValue: Bool {
        return self.storage.count == self.codingPath.count
    }
    
    func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        // If an existing keyed container was already requested, return that one.
        let topContainer: xpc_object_t
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushKeyedContainer()
        } else {
            guard let container = self.storage.containers.last, container.xpcType == .dictionary else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }
            topContainer = container
        }
        let container = _XPCKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: xpc_object_t
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushUnkeyedContainer()
        } else {
            guard let container = self.storage.containers.last, container.xpcType == .array else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }
            topContainer = container
        }
        return _XPCUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

// MARK: - Encoding Storage

private struct _XPCEncodingStorage {
    
    private(set) var containers: [xpc_object_t] = []
    
    init() {}
    
    var count: Int {
        return self.containers.count
    }
    
    mutating func pushKeyedContainer() -> xpc_object_t {
        let dictionary = xpc_dictionary_create(nil, nil, 0)
        self.containers.append(dictionary)
        return dictionary
    }
    
    mutating func pushUnkeyedContainer() -> xpc_object_t {
        let array = xpc_array_create(nil, 0)
        self.containers.append(array)
        return array
    }
    
    mutating func push(container: xpc_object_t) {
        self.containers.append(container)
    }
    
    mutating func popContainer() -> xpc_object_t {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.popLast()!
    }
}

// MARK: - Encoding Containers

private struct _XPCKeyedEncodingContainer<Key: CodingKey>: KeyedPrimitiveEncodingContainerProtocol {
    
    private let encoder: _XPCEncoder
    
    private let container: xpc_object_t
    
    private(set) var codingPath: [CodingKey]
    
    fileprivate init(referencing encoder: _XPCEncoder, codingPath: [CodingKey], wrapping container: xpc_object_t) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    func encodeNil(forKey key: Key) {
        xpc_dictionary_set_value(container, key.stringValue, xpc_null_create())
    }
    
    func encodePrimitive<T: PrimitiveCodable>(_ value: T, forKey key: Key) throws {
        xpc_dictionary_set_value(container, key.stringValue, value.encodedXPC)
    }
    
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        xpc_dictionary_set_value(container, key.stringValue, try self.encoder.box(value))
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let dictionary = xpc_dictionary_create(nil, nil, 0)
        xpc_dictionary_set_value(container, key.stringValue, dictionary)
        
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        let container = _XPCKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let array = xpc_array_create(nil, 0)
        xpc_dictionary_set_value(container, key.stringValue, array)
        
        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        
        return _XPCUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }
    
    func superEncoder() -> Encoder {
        return _XPCReferencingEncoder(referencing: self.encoder, at: XPCCodingKey.super, wrapping: self.container)
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        return _XPCReferencingEncoder(referencing: self.encoder, at: key, wrapping: self.container)
    }
}

private struct _XPCUnkeyedEncodingContainer: UnkeyedPrimitiveEncodingContainer {
    
    private let encoder: _XPCEncoder
    
    private let container: xpc_object_t
    
    private(set) var codingPath: [CodingKey]
    
    var count: Int {
        return xpc_array_get_count(container)
    }
    
    init(referencing encoder: _XPCEncoder, codingPath: [CodingKey], wrapping container: xpc_object_t) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }
    
    func encodeNil() {
        xpc_array_set_value(container, XPC_ARRAY_APPEND, xpc_null_create())
    }
    
    func encodePrimitive<T: PrimitiveCodable>(_ value: T) throws {
        xpc_array_set_value(container, XPC_ARRAY_APPEND, value.encodedXPC)
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        self.encoder.codingPath.append(XPCCodingKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        xpc_array_set_value(container, XPC_ARRAY_APPEND, try self.encoder.box(value))
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append(XPCCodingKey(index: self.count))
        defer { self.codingPath.removeLast() }
        
        let dictionary = xpc_dictionary_create(nil, nil, 0)
        xpc_array_set_value(container, XPC_ARRAY_APPEND, dictionary)
        
        let container = _XPCKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append(XPCCodingKey(index: self.count))
        defer { self.codingPath.removeLast() }
        
        let array = xpc_array_create(nil, 0)
        xpc_array_set_value(container, XPC_ARRAY_APPEND, array)
        return _XPCUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
    }
    
    func superEncoder() -> Encoder {
        return _XPCReferencingEncoder(referencing: self.encoder, at: self.count, wrapping: self.container)
    }
}

extension _XPCEncoder: SingleValuePrimitiveEncodingContainer {
    
    private func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }
    
    func encodeNil() throws {
        assertCanEncodeNewValue()
        self.storage.push(container: xpc_null_create())
    }
    
    func encodePrimitive<T: PrimitiveCodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: value.encodedXPC)
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }
}

// MARK: - Concrete Value Representations

private extension _XPCEncoder {
    
    func box(_ value: Encodable) throws -> xpc_object_t {
        return try box_(value) ?? xpc_dictionary_create(nil, nil, 0)
    }
    
    func box_(_ value: Encodable) throws -> xpc_object_t? {
        if let v = value as? XPCRepresentable {
            return v.xpcObject
        }
        
        // The value should request a container from the _XPCEncoder.
        let depth = self.storage.count
        do {
            try value.encode(to: self)
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }
            throw error
        }
        
        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }
        
        return self.storage.popContainer()
    }
}

// MARK: - _XPCReferencingEncoder

fileprivate class _XPCReferencingEncoder: _XPCEncoder {
    
    private enum Reference {
        case array(xpc_object_t, Int)
        case dictionary(xpc_object_t, String)
    }
    
    let encoder: _XPCEncoder
    
    private let reference: Reference
    
    init(referencing encoder: _XPCEncoder, at index: Int, wrapping array: xpc_object_t) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init(codingPath: encoder.codingPath)
        self.codingPath.append(XPCCodingKey(index: index))
    }
    
    init(referencing encoder: _XPCEncoder, at key: CodingKey, wrapping dictionary: xpc_object_t) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        super.init(codingPath: encoder.codingPath)
        self.codingPath.append(key)
    }
    
    override var canEncodeNewValue: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }
    
    deinit {
        let value: xpc_object_t
        switch self.storage.count {
        case 0: value = xpc_dictionary_create(nil, nil, 0)
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }
        
        switch self.reference {
        case .array(let array, let index):
            xpc_array_set_value(array, index, value)
        case .dictionary(let dictionary, let key):
            xpc_dictionary_set_value(dictionary, key, value)
        }
    }
}

#endif
