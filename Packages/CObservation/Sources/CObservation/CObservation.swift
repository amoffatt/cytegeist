// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
//@freestanding(expression)
//public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "CObservationMacrosMacros", type: "StringifyMacro")

import Foundation
import UniformTypeIdentifiers
import SwiftUI


/// Similar to @Observable, but adds UndoManager support to the object.
/// It is recommended that any object with this macro also inherit from CObject
@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation))
@attached(memberAttribute)
@attached(extension, conformances: CObservable, Observable)
public macro CObservable() =
  #externalMacro(module: "CObservationMacros", type: "CObservableMacro")




@MainActor
public class CObjectContext {
    // AM DEBUGGING. Remove the nonisolated(unsafe) and make models MainActor
//    nonisolated(unsafe)
    public private(set) static var currentContext:CObjectContext? = nil
    
    public var undoManager:UndoManager?
    
    public init(_ undoManager:UndoManager?) {
        self.undoManager = undoManager
    }
    
    @MainActor
    public func withContext<T>(_ body: () throws -> T) rethrows -> T {
        guard Self.currentContext == nil else {
            fatalError("Already in a context. Cannot start new CObjectContext within an existing context")
        }
        
        Self.currentContext = self
        defer {
            Self.currentContext = nil
        }
        return try body()
    }
    
}

extension UTType {
    static var cObject:UTType {
        UTType(exportedAs: "com.cytegiest.cobject")
    }
}

@MainActor
open class CObject : CObservable, Identifiable, Hashable, Equatable, MainActorSerializable {
    nonisolated public static func == (lhs: CObject, rhs: CObject) -> Bool {
        lhs.id == rhs.id
    }
    
    nonisolated open func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
    public let id:UUID
    
    public let _context:CObjectContext?
    
//    @MainActor
    public init() {
        self.id = UUID()
        
        self._context = CObjectContext.currentContext
        if self._context == nil {
//            print("Error: CObject created without a context. Use CObjectContext.withContext { ... }")
            fatalError("CObject created without a context. Use CObjectContext.withContext { ... }")
        }
    }
    
    @MainActor
    public func withContext<T>(_ body: () throws -> T) rethrows -> T {
        if let _context {
            return try _context.withContext(body)
        }
        return try body()
    }

    // New initializer for decoding
//    public required init(from decoder: Decoder) async throws {
//        
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = try container.decode(UUID.self, forKey: .id)
//        self._context = CObjectContext.currentContext
//
//        if self._context == nil {
//            fatalError("CObject created without a context. Use CObjectContext.withContext { ... }")
//        }
//
////        try await decodeCodableProperties(from: decoder)
//    }
    
    
    open func serialize() throws -> Any? {
        let container = NSMutableDictionary()
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let label = child.label else { continue }
//            if let encodableProperty = child.value as? Codable {
//                try container.encode(encodableProperty, forKey: key)
//            }
            if let encodableProperty = child.value as? MainActorSerializable {
                if let encoded = try encodableProperty.serialize() {
                    container.setValue(encoded, forKey: label)
                }
            }
            else {
                print("Could not encode property \(label) in \(type(of: self)).")
            }
        }
        return container
    }

    // New encode method
//    open func encode(to encoder: Encoder) async throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//
//        try await encodeCodableProperties(to: encoder)
//    }
//    private func encodeCodableProperties(to encoder: Encoder) async throws {
//        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
//        let mirror = Mirror(reflecting: self)
//        for child in mirror.children {
//            guard let label = child.label else { continue }
//            let key = DynamicCodingKeys.init(stringValue: label)
//            if let encodableProperty = child.value as? Codable {
//                try container.encode(encodableProperty, forKey: key)
//            }
//            else if let encodableProperty = child.value as? MainActorSerializable {
////                try container.encode(encodableProperty, forKey: .init(stringValue: label))
//                let childEncoder = container.superEncoder(forKey: key)
//                try await encodableProperty.encode(to: childEncoder)
//            }
//            else {
//                print("Could not encode property \(label) in \(type(of: self)).")
//            }
//        }
//    }

//    // Helper method for decoding properties
//    private func decodeCodableProperties(from decoder: Decoder) async throws {
//        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
//        let mirror = Mirror(reflecting: self)
//        for child in mirror.children {
//            guard let label = child.label else { continue }
//            let key = DynamicCodingKeys.init(stringValue: label)
//            let decoder = try container.superDecoder(forKey: key)
//            do {
//                let value = try await decodeCodableProperty(child, from: decoder)
//                (self as AnyObject).setValue(value, forKey: label)
//            } catch {
//                print("Could not decode property \(label) in \(type(of: self)).")
//            }
//        }
//                
//    }
//
//    private func decodeCodableProperty(_ property: Mirror.Child, from decoder: Decoder) async throws -> Any {
//        switch property.value {
//            case let decodableProperty as Codable:
//                return try type(of: decodableProperty).init(from: decoder)
//            case let decodableProperty as MainActorSerializable:
//                return try await type(of: decodableProperty).init(from: decoder)
//            default:
//                throw DecodingError.typeMismatch(type(of: property.value), DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Non-decodable property type"))
//        }
//    }
//
//    // CodingKeys enum for the id property
//    private enum CodingKeys: String, CodingKey {
//        case id
//    }
//
//    // DynamicCodingKeys for dynamic property encoding/decoding
//    private struct DynamicCodingKeys: CodingKey {
//        var stringValue: String
//        init(stringValue: String) {
//            self.stringValue = stringValue
//        }
//        var intValue: Int?
//        init?(intValue: Int) {
//            return nil
//        }
//    }
}


public protocol CObservable: Observation.Observable, AnyObject {
    // AM DEBUGGING
    @MainActor
    var _context:CObjectContext? { get }
}

extension CObject: Transferable {
    nonisolated public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .cObject) { o in
        }
    }
}


public protocol MainActorSerializable {
    /// Result should be serializable via JSONSerialization
    @MainActor
    func serialize() throws -> Any?
//    @MainActor
//    init(from decoder: Decoder) async throws
}

@propertyWrapper
public struct NonSerialized<T>: MainActorSerializable {
    public var wrappedValue: T?
    
    public init(wrappedValue: T?) {    self.wrappedValue = wrappedValue   }
    public func serialize() throws -> Any? {
        nil
    }
}
    



public extension Collection where Element: MainActorSerializable {
//    @MainActor
//    func encode(to encoder: Encoder) async throws {
//        var container = encoder.unkeyedContainer()
//        for element in self {
//            try await element.encode(to: container.superEncoder())
//        }
//    }
    
    @MainActor
    func serialize() async throws -> Any? {
        try map { try $0.serialize() }  // TODO handle nil in special manor?
    }
    
//    @MainActor
//    static func decode(from decoder: Decoder) async throws -> Self {
//        var container = try decoder.unkeyedContainer()
//        var elements = [Element]()
//        while !container.isAtEnd {
//            let element = try await Element(from: container.superDecoder())
//            elements.append(element)
//        }
//        guard let result = elements as? Self else {
//            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Decoded elements don't match the expected type"))
//        }
//        return result
//    }
}

extension Collection where Element: MainActorSerializable {
    typealias AsyncCodableCollection = MainActorSerializable & Collection
}

//extension Array: MainActorSerializable where Element: MainActorSerializable {
//    @MainActor
//    public init(from decoder: Decoder) async throws {
//        self = try await Array<Element>.decode(from: decoder)
//    }
//}

extension String: MainActorSerializable {
    public func serialize() throws -> Any? {
        NSString(string:self)
    }
}

extension Int: MainActorSerializable {
    public func serialize() throws -> Any? {
        self
    }
}
