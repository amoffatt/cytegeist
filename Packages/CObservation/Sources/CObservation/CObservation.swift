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


@attached(member, names: named(_$observationRegistrar), named(access), named(withMutation))
@attached(memberAttribute)
@attached(extension, conformances: CObservable, Observable)
public macro CObservable() =
  #externalMacro(module: "CObservationMacros", type: "CObservableMacro")



public protocol CObservable: Observation.Observable {
    var _context:CObjectContext? { get }
}


public class CObjectContext {
    var undoManager:UndoManager?
}

open class CObject : CObservable, Identifiable, Hashable, Equatable {
    public static func == (lhs: CObject, rhs: CObject) -> Bool {
        lhs.id == rhs.id
    }
    
    open func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
    public private(set) var id:UUID
    
    public var _context:CObjectContext? = nil
    
    public init() {
        self.id = UUID()
    }
}

//extension CObjectContext {
//    func registerMemberChange(_ o:CObservable, KeyPath<j
//}
