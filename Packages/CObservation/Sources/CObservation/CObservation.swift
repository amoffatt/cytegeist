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


/// Similar to @Observable, but adds UndoManager support to the object.
/// It is recommended that any object with this macro also inherit from CObject
@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation))
@attached(memberAttribute)
@attached(extension, conformances: CObservable, Observable)
public macro CObservable() =
  #externalMacro(module: "CObservationMacros", type: "CObservableMacro")



public protocol CObservable: Observation.Observable, AnyObject {
    // AM DEBUGGING
    @MainActor
    var _context:CObjectContext? { get }
}


//@MainActor
public class CObjectContext {
    // AM DEBUGGING. Remove the nonisolated(unsafe) and make models MainActor
    nonisolated(unsafe) public private(set) static var currentContext:CObjectContext? = nil
    
    public let undoManager:UndoManager?
    
    public init(undoManager:UndoManager?) {
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

@MainActor
open class CObject : CObservable, Identifiable, Hashable, Equatable {
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

    
}

//extension CObjectContext {
//    func registerMemberChange(_ o:CObservable, KeyPath<j
//}
