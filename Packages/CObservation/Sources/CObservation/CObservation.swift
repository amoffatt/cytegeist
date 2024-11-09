//
//  CObservation.swift
//  CObservation
//
//  Created by Aaron Moffatt on 10/12/24.
//

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

@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro CObservationTracked() =
  #externalMacro(module: "CObservationMacros", type: "CObservationTrackedMacro")



@MainActor
public class CObjectContext {
    public private(set) static var currentContext:CObjectContext? = nil
    public internal(set) static var ignoreUndoableActions = false

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
    
    public func registerUndo<TargetType:AnyObject>(withTarget target:TargetType, _ action:@escaping @Sendable (TargetType) -> Void) {
//        undoManager?.registerUndo(withTarget: self, selector: #selector(undoAction), object: nil)
        if Self.ignoreUndoableActions {
            return
        }
        undoManager?.registerUndo(withTarget: target, handler: action)
    }
    
}

/// Registers all undoable actions registers within this closure to the same Undo group
/// Must be called within a CObject context
@MainActor
public func undoable<T>(_ actionName:String? = nil, _ body: () throws -> T) rethrows -> T {
    let context = CObjectContext.currentContext
    guard let context else {
        fatalError("undoable() must be invoked within a CObject Context. See CObject.withContext { }")
    }
    let undoManager = context.undoManager
    undoManager?.beginUndoGrouping()
    undoManager?.setActionName(actionName ?? "")
    defer { undoManager?.endUndoGrouping() }
    
    return try body()
    
}

@MainActor
public func notUndoable<T>(_ body: () throws -> T) rethrows -> T {
    let context = CObjectContext.currentContext
    CObjectContext.ignoreUndoableActions = true
    defer { CObjectContext.ignoreUndoableActions = false }
    return try body()
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
    
    public init() {
        self.id = UUID()
        
        self._context = CObjectContext.currentContext
        if self._context == nil {
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

    open func serialize() throws -> Any? {
        let container = NSMutableDictionary()
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let label = child.label else { continue }
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
}


public protocol CObservable: Observation.Observable, AnyObject {
    @MainActor
    var _context:CObjectContext? { get }
}

extension CObject: Transferable {
    // AM DEBUGGING
    nonisolated public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .cObject) { o in
//            Self(o)
            fatalError()
        }
        DataRepresentation(exportedContentType: .cObject) { o in
            fatalError()
            try await Task.sleep(nanoseconds:1000)
            return try Data(contentsOf: URL("https://google.com")!)
//            await o.serialize()
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
