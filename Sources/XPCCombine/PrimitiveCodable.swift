#if canImport(XPC)

// We need to use other primitive codable protocol methods in the concrete
// implementation like `encodePrimitive(_:)`. Therefore `PrimitiveCodable`
// need to refine these protocols.
protocol PrimitiveCodable: PrimitiveXPCCodable /* insert primitive codable protocol here */ {}

extension Bool  : PrimitiveCodable {}
extension Int   : PrimitiveCodable {}
extension Int8  : PrimitiveCodable {}
extension Int16 : PrimitiveCodable {}
extension Int32 : PrimitiveCodable {}
extension Int64 : PrimitiveCodable {}
extension UInt  : PrimitiveCodable {}
extension UInt8 : PrimitiveCodable {}
extension UInt16: PrimitiveCodable {}
extension UInt32: PrimitiveCodable {}
extension UInt64: PrimitiveCodable {}
extension Float : PrimitiveCodable {}
extension Double: PrimitiveCodable {}
extension String: PrimitiveCodable {}

// MARK: - Encoding

protocol SingleValuePrimitiveEncodingContainer: SingleValueEncodingContainer {
    mutating func encodePrimitive<T: PrimitiveCodable>(_ value: T) throws
}

extension SingleValuePrimitiveEncodingContainer {
    mutating func encode(_ value: Bool  ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int   ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int8  ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int16 ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int32 ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int64 ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt  ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt8 ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt16) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt32) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt64) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Float ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Double) throws { try encodePrimitive(value) }
    mutating func encode(_ value: String) throws { try encodePrimitive(value) }
}

protocol KeyedPrimitiveEncodingContainerProtocol: KeyedEncodingContainerProtocol {
    mutating func encodePrimitive<T: PrimitiveCodable>(_ value: T, forKey key: Key) throws
}

extension KeyedPrimitiveEncodingContainerProtocol {
    mutating func encode(_ value: Bool  , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: Int   , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: Int8  , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: Int16 , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: Int32 , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: Int64 , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: UInt  , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: UInt8 , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: UInt16, forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: UInt32, forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: UInt64, forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: Float , forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: Double, forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
    mutating func encode(_ value: String, forKey key: Key) throws { try encodePrimitive(value, forKey: key) }
}

protocol UnkeyedPrimitiveEncodingContainer: UnkeyedEncodingContainer {
    mutating func encodePrimitive<T: PrimitiveCodable>(_ value: T) throws
}

extension UnkeyedPrimitiveEncodingContainer {
    mutating func encode(_ value: Bool  ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int   ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int8  ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int16 ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int32 ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Int64 ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt  ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt8 ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt16) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt32) throws { try encodePrimitive(value) }
    mutating func encode(_ value: UInt64) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Float ) throws { try encodePrimitive(value) }
    mutating func encode(_ value: Double) throws { try encodePrimitive(value) }
    mutating func encode(_ value: String) throws { try encodePrimitive(value) }
}

// MARK: - Decoding

protocol SingleValuePrimitiveDecodingContainer: SingleValueDecodingContainer {
    func decodePrimitive<T: PrimitiveCodable>(_ type: T.Type) throws -> T
}

extension SingleValuePrimitiveDecodingContainer {
    func decode(_ type: Bool  .Type) throws -> Bool   { return try decodePrimitive(type) }
    func decode(_ type: Int   .Type) throws -> Int    { return try decodePrimitive(type) }
    func decode(_ type: Int8  .Type) throws -> Int8   { return try decodePrimitive(type) }
    func decode(_ type: Int16 .Type) throws -> Int16  { return try decodePrimitive(type) }
    func decode(_ type: Int32 .Type) throws -> Int32  { return try decodePrimitive(type) }
    func decode(_ type: Int64 .Type) throws -> Int64  { return try decodePrimitive(type) }
    func decode(_ type: UInt  .Type) throws -> UInt   { return try decodePrimitive(type) }
    func decode(_ type: UInt8 .Type) throws -> UInt8  { return try decodePrimitive(type) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return try decodePrimitive(type) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return try decodePrimitive(type) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return try decodePrimitive(type) }
    func decode(_ type: Float .Type) throws -> Float  { return try decodePrimitive(type) }
    func decode(_ type: Double.Type) throws -> Double { return try decodePrimitive(type) }
    func decode(_ type: String.Type) throws -> String { return try decodePrimitive(type) }
}

protocol KeyedPrimitiveDecodingContainerProtocol: KeyedDecodingContainerProtocol {
    func decodePrimitive<T: PrimitiveCodable>(_ type: T.Type, forKey key: Key) throws -> T
}

extension KeyedPrimitiveDecodingContainerProtocol {
    func decode(_ type: Bool.Type  , forKey key: Key) throws -> Bool   { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: Int.Type   , forKey key: Key) throws -> Int    { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: Int8.Type  , forKey key: Key) throws -> Int8   { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: Int16.Type , forKey key: Key) throws -> Int16  { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: Int32.Type , forKey key: Key) throws -> Int32  { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: Int64.Type , forKey key: Key) throws -> Int64  { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: UInt.Type  , forKey key: Key) throws -> UInt   { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: UInt8.Type , forKey key: Key) throws -> UInt8  { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: Float.Type , forKey key: Key) throws -> Float  { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return try decodePrimitive(type, forKey: key) }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { return try decodePrimitive(type, forKey: key) }
}

protocol UnkeyedPrimitiveDecodingContainer: UnkeyedDecodingContainer {
    mutating func decodePrimitive<T: PrimitiveCodable>(_ type: T.Type) throws -> T
}

extension UnkeyedPrimitiveDecodingContainer {
    mutating func decode(_ type: Bool.Type  ) throws -> Bool   { return try decodePrimitive(type) }
    mutating func decode(_ type: Int.Type   ) throws -> Int    { return try decodePrimitive(type) }
    mutating func decode(_ type: Int8.Type  ) throws -> Int8   { return try decodePrimitive(type) }
    mutating func decode(_ type: Int16.Type ) throws -> Int16  { return try decodePrimitive(type) }
    mutating func decode(_ type: Int32.Type ) throws -> Int32  { return try decodePrimitive(type) }
    mutating func decode(_ type: Int64.Type ) throws -> Int64  { return try decodePrimitive(type) }
    mutating func decode(_ type: UInt.Type  ) throws -> UInt   { return try decodePrimitive(type) }
    mutating func decode(_ type: UInt8.Type ) throws -> UInt8  { return try decodePrimitive(type) }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { return try decodePrimitive(type) }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { return try decodePrimitive(type) }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { return try decodePrimitive(type) }
    mutating func decode(_ type: Float.Type ) throws -> Float  { return try decodePrimitive(type) }
    mutating func decode(_ type: Double.Type) throws -> Double { return try decodePrimitive(type) }
    mutating func decode(_ type: String.Type) throws -> String { return try decodePrimitive(type) }
}

#endif
