#if canImport(XPC)

import Foundation
import XPC

/// `XPCDecoder` facilitates the decoding of XPC object into semantic `Decodable` types.
open class XPCDecoder {
    
    /// The strategy to use for unwrap XPC message.
    public enum XPCMessageUnwrappingStrategy {
        
        /// Do not unwrap.
        case none
        
        /// Unwrap if only 1. The XPC object to decode from is a dictionary. 2. The specified key presents in the dictionary. 3. The dictionary contains exactly one key.
        case unwrapIfPresent(singleValueDictionaryKey: String)
        
        /// Just like `unwrapIfPresent`, but throws if cannot unwrap.
        case forceUnwrap(singleValueDictionaryKey: String)
    }
    
    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey: Any] = [:]
    
    /// The strategy to use in unwrapping XPC message. Defaults to `.none`.
    open var xpcMessageUnwrappingStrategy: XPCMessageUnwrappingStrategy = .none
    
    public init() {}

    // MARK: - Decoding Values
    /// Decodes a top-level value of the given type from the given XPC representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter xpcObject: The XPC object to decode from.
    /// - returns: A value of the requested type.
    /// - throws: An error if any value throws an error during decoding.
    open func decode<T: Decodable>(_ type: T.Type, from xpcObject: xpc_object_t) throws -> T {
        let unwrapedObject: xpc_object_t
        switch xpcMessageUnwrappingStrategy {
        case .none:
            unwrapedObject = xpcObject
        case let .unwrapIfPresent(singleValueDictionaryKey: key):
            if xpcObject.xpcType == .dictionary, xpcObject.dictionaryCount == 1, let unwrapped = xpcObject[key] {
                unwrapedObject = unwrapped
            } else {
                unwrapedObject = xpcObject
            }
        case let .forceUnwrap(singleValueDictionaryKey: key):
            if xpcObject.xpcType == .dictionary, xpcObject.dictionaryCount == 1, let unwrapped = xpcObject[key] {
                unwrapedObject = unwrapped
            } else {
                // TODO: error message
                throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
            }
        }
        let decoder = _XPCDecoder(referencing: unwrapedObject, userInfo: self.userInfo)
        guard let value = try decoder.unbox(unwrapedObject, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }
        return value
    }
}

// MARK: - _XPCDecoder

private class _XPCDecoder: Decoder {
    
    var storage: _XPCDecodingStorage
    
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey: Any]
    
    init(referencing container: xpc_object_t, at codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any]) {
        self.storage = _XPCDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let topContainer = self.storage.topContainer
        let topType = topContainer.xpcType
        guard topType != .null else {
            throw DecodingError.xpcNullValue(at: self.codingPath, expectation: KeyedDecodingContainer<Key>.self)
        }
        let container = try _XPCKeyedDecodingContainer<Key>(referencing: self, checkAndWrapping: topContainer, errorPath: self.codingPath)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let topContainer = self.storage.topContainer
        let topType = topContainer.xpcType
        guard topType != .null else {
            throw DecodingError.xpcNullValue(at: self.codingPath, expectation: UnkeyedDecodingContainer.self)
        }
        return try _XPCUnkeyedDecodingContainer(referencing: self, checkAndWrapping: topContainer, errorPath: self.codingPath)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

// MARK: - Decoding Storage

private struct _XPCDecodingStorage {
    
    private(set) var containers: [xpc_object_t] = []
    
    init() {}
    
    var count: Int {
        return self.containers.count
    }
    
    var topContainer: xpc_object_t {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.last!
    }
    
    mutating func push(container: xpc_object_t) {
        self.containers.append(container)
    }
    
    mutating func popContainer() {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        self.containers.removeLast()
    }
}

// MARK: Decoding Containers

private struct _XPCKeyedDecodingContainer<Key: CodingKey>: KeyedPrimitiveDecodingContainerProtocol {
    
    private let decoder: _XPCDecoder
    
    private let container: xpc_object_t
    
    private(set) var codingPath: [CodingKey]
    
    init(referencing decoder: _XPCDecoder, checkAndWrapping container: xpc_object_t, errorPath: [CodingKey]) throws {
        let type = container.xpcType
        guard type == .dictionary else {
            throw DecodingError.xpcTypeMismatch(at: errorPath, expectation: .dictionary, reality: type)
        }
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }
    
    var allKeys: [Key] {
        let count = xpc_dictionary_get_count(container)
        var keys: [Key] = []
        keys.reserveCapacity(count)
        xpc_dictionary_apply(container) { key, _ -> Bool in
            if let k = Key(stringValue: String(cString: key)) {
                keys.append(k)
            }
            return true
        }
        return keys
    }
    
    func contains(_ key: Key) -> Bool {
        return container[key.stringValue] != nil
    }
    
    private func decodeXPC(key: Key) throws -> xpc_object_t {
        guard let value = container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key)."))
        }
        return value
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        return try decodeXPC(key: key).xpcType == .null
    }
    
    func decodePrimitive<T: PrimitiveCodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let entry = try decodeXPC(key: key)
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard entry.xpcType != .null else {
            throw DecodingError.xpcNullValue(at: self.decoder.codingPath, expectation: type)
        }
        guard entry.xpcType == T.primitiveXPCType else {
            throw DecodingError.xpcTypeMismatch(at: self.codingPath, expectation: T.primitiveXPCType, reality: entry.xpcType)
        }
        guard let value = T(docedeXPC: entry) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed XPC object <\(entry)> does not fit in \(T.primitiveXPCType)."))
        }
        return value
    }
    
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let entry = try decodeXPC(key: key)
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard entry.xpcType != .null else {
            throw DecodingError.xpcNullValue(at: self.decoder.codingPath, expectation: type)
        }
        guard let value = try self.decoder.unbox(entry, as: type) else {
            throw DecodingError.valueNotFound(type, .init(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        
        return value
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = container[key.stringValue] else {
            let ctx = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \(key)")
            throw DecodingError.keyNotFound(key, ctx)
        }
        
        let container = try _XPCKeyedDecodingContainer<NestedKey>(referencing: self.decoder, checkAndWrapping: value, errorPath: self.codingPath)
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = container[key.stringValue] else {
            let ctx = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \(key)")
            throw DecodingError.keyNotFound(key, ctx)
        }
        return try _XPCUnkeyedDecodingContainer(referencing: self.decoder, checkAndWrapping: value, errorPath: self.codingPath)
    }
    
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        let value = container[key.stringValue] ?? xpc_null_create()
        return _XPCDecoder(referencing: value, at: self.decoder.codingPath, userInfo: self.decoder.userInfo)
    }
    
    func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: XPCCodingKey.super)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

private struct _XPCUnkeyedDecodingContainer: UnkeyedPrimitiveDecodingContainer {
    
    private let decoder: _XPCDecoder
    
    private let container: xpc_object_t
    
    private(set) var codingPath: [CodingKey]
    
    private(set) var currentIndex: Int
    
    init(referencing decoder: _XPCDecoder, checkAndWrapping container: xpc_object_t, errorPath: [CodingKey]) throws {
        let type = container.xpcType
        guard type == .array else {
            throw DecodingError.xpcTypeMismatch(at: errorPath, expectation: .array, reality: type)
        }
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }
    
    var count: Int? {
        return xpc_array_get_count(container)
    }
    
    var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }
    
    private func expectNotAtEnd(_ type: Any.Type, withCurrentPath: Bool) throws {
        guard !self.isAtEnd else {
            let path: [CodingKey] = withCurrentPath ? [XPCCodingKey(index: self.currentIndex)] : []
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + path, debugDescription: "Unkeyed container is at end."))
        }
    }
    
    mutating func decodeNil() throws -> Bool {
        try self.expectNotAtEnd(Any.self, withCurrentPath: true)
        
        if container[currentIndex].xpcType == .null {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }
    
    mutating func decodePrimitive<T: PrimitiveCodable>(_ type: T.Type) throws -> T {
        try self.expectNotAtEnd(Any.self, withCurrentPath: true)
        
        self.decoder.codingPath.append(XPCCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        let xpcObj = container[currentIndex]
        guard xpcObj.xpcType != .null else {
            throw DecodingError.xpcNullValue(at: self.decoder.codingPath, expectation: type)
        }
        guard let value = T(docedeXPC: xpcObj) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed XPC object <\(xpcObj)> does not fit in \(T.primitiveXPCType)."))
        }
        
        return value
    }
    
    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try self.expectNotAtEnd(Any.self, withCurrentPath: true)
        
        self.decoder.codingPath.append(XPCCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[currentIndex], as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [XPCCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(XPCCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        try self.expectNotAtEnd(KeyedDecodingContainer<NestedKey>.self, withCurrentPath: false)
        
        let value = self.container[currentIndex]
        guard value.xpcType != .null else {
            throw DecodingError.xpcNullValue(at: self.decoder.codingPath, expectation: type)
        }
        let container = try _XPCKeyedDecodingContainer<NestedKey>(referencing: self.decoder, checkAndWrapping: value, errorPath: self.codingPath)
        self.currentIndex += 1
        return KeyedDecodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(XPCCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        try self.expectNotAtEnd(UnkeyedDecodingContainer.self.self, withCurrentPath: false)
        
        let value = self.container[currentIndex]
        guard value.xpcType != .null else {
            throw DecodingError.xpcNullValue(at: self.decoder.codingPath, expectation: UnkeyedDecodingContainer.self)
        }
        let container = try _XPCUnkeyedDecodingContainer(referencing: self.decoder, checkAndWrapping: value, errorPath: self.codingPath)
        self.currentIndex += 1
        return container
    }
    
    mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(XPCCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        try self.expectNotAtEnd(UnkeyedDecodingContainer.self, withCurrentPath: false)
        
        let value = self.container[currentIndex]
        self.currentIndex += 1
        return _XPCDecoder(referencing: value, at: self.decoder.codingPath, userInfo: self.decoder.userInfo)
    }
}

extension _XPCDecoder: SingleValuePrimitiveDecodingContainer {
    
    func decodeNil() -> Bool {
        return self.storage.topContainer.isNull
    }
    
    func decodePrimitive<T: PrimitiveCodable>(_ type: T.Type) throws -> T {
        guard !self.decodeNil() else {
            throw DecodingError.xpcNullValue(at: self.codingPath, expectation: type)
        }
        let xpcObj = self.storage.topContainer
        guard let value = T(docedeXPC: xpcObj) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed XPC object <\(xpcObj)> does not fit in \(T.primitiveXPCType)."))
        }
        return value
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        return try self.unbox(self.storage.topContainer, as: type)!
    }
    
    func unbox<T: Decodable>(_ value: xpc_object_t, as type: T.Type) throws -> T? {
        guard !(value is NSNull) else { return nil }
        self.storage.push(container: value)
        defer { self.storage.popContainer() }
        return try type.init(from: self)
    }
}

#endif
