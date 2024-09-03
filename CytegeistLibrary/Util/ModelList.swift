//
//  ModelList.swift
//  CytegeistLibrary
//
//  Created by Adam Treister on 9/2/24.
//

import Foundation

public protocol Usable : Identifiable, Equatable, Codable {
    
}

//@Observable
//public struct ModelList<Model> : Codable where Model:Usable {
////    public static func == (lhs: ModelList<Model>, rhs: ModelList<Model>) -> Bool {
//////        lhs.items == rhs.items
////    }
//    
//    public var items:[Model] = []
//    public var selected:Model? = nil
//    
//    public var recent:[Model] { items }
//    
//    @ObservationIgnored
//    @CodableIgnored
//    private var create:((ModelList<Model>) -> Model)?
//    
//    public init(create:@escaping (ModelList<Model>) -> Model) {
//        self.create = create
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        hasher.combineMany(items, selected)
//    }
////    
////    public required init(from decoder: any Decoder) throws {
////        fatalError()
////    }
//    
//    @discardableResult
//    func getSelectedExperiment(autoselect:Bool = false, createIfNil:Bool = false) -> Model?
//    {
//        if let selected {
//            if let m = items.first(where: { $0.id == selected.id}) {
//                return m
//            }
//        }
//        if autoselect, let recent = recent.first {
//            selected = recent
//            return recent
//        }
//        if createIfNil {
//            let m = recent.first ?? create(self)
//            selected = m
//            return m
//        }
//        return nil
//    }
//
//}
