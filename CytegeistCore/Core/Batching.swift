//
//  Batching.swift
//  CytegeistCore
//
//  Created by Adam Treister on 10/26/24.
//

import Foundation
import SwiftUI

@Observable
public class BatchContext {
    public static let empty = BatchContext(allSamples: [])
    
    public let allSamples:[Sample]
    
    public init(allSamples: [Sample]) {
        self.allSamples = allSamples
    }
    
    public func getSample(_ id:Sample.ID) -> Sample? {
        allSamples.first { $0.id == id }
    }
    
    public func getSample(keyword: String, value: String) -> Sample? {
        allSamples.first { $0.meta?.keywordLookup[keyword] == value }
    }
 
    public func getSample(keyword: String, value: String, keyword2: String, value2: String) -> Sample? {
        allSamples.first { $0.meta?.keywordLookup[keyword] == value  &&  $0.meta?.keywordLookup[keyword2] == value2 }
    }

}


//struct BatchContextEnvironmentKey: EnvironmentKey {
//    static let defaultValue:BatchContext = .empty
//}
//
//public extension EnvironmentValues {
//    var batchContext: BatchContext {
//        get { self[BatchContextEnvironmentKey.self] }
//        set { self[BatchContextEnvironmentKey.self] = newValue }
//    }
//}
