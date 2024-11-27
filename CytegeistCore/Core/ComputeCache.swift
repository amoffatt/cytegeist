//
//  ComputeGraph.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/18/24.
//

import Foundation
import SwiftUI
import SwiftData
import CytegeistLibrary


fileprivate class ComputeHandle<Request, Data> {
    var done = false
    var lastRequested:Date = Date()
    var task:Task<Data, Error>!
}


public actor ComputeCache<Request:Hashable, Data> : Identifiable {
    
    // TODO: Naive cache pruning system. Improve
    public var maxCacheItems = 10000
    
    public typealias ComputeFunction = (Request) async throws -> Data

    private var _cache:[Request:ComputeHandle<Request, Data>] = [:]
    
    private let _compute:ComputeFunction
    
    public init(compute:@escaping ComputeFunction) {
        self._compute = compute
    }
    
    public func get(_ request:Request) async throws -> Data {
//        print("   <<< Cache get()")
        try Task.checkCancellation()
        
        var handle = _cache[request]
//        print ("Cache get() hit (hashValue: \(request.hashValue): \(handle != nil): \(request)")

        if handle == nil {
            handle = ComputeHandle<Request, Data>()
            handle!.task = Task {  // Note: don't use Task.detached, otherwise cancellation will not be passed through
                    do {
                        try Task.checkCancellation()
                        defer { handle!.done = true }
                        return try await self._compute(request)
                    } catch {
                        print("Error computing request \(request): \(error)")
                        throw error
                    }
                }
            
            
            _cache[request] = handle
            pruneOldHandles()
        }
        handle!.lastRequested = Date()
        
        return try await handle!.task.value
    }
    
    
    private func pruneOldHandles() {
        // Only remove handles that have already finished
        let finishedHandles = _cache.filter { $0.value.done }
        if finishedHandles.count < maxCacheItems {
            return
        }
        
        for _ in maxCacheItems...finishedHandles.count {
            let oldest = finishedHandles.min {
                $0.value.lastRequested > $1.value.lastRequested
            }
            
            if let removed = _cache.removeValue(forKey: oldest!.key) {
                print("  => Removed data from cache: \(removed)")
            }
        }
    }
    
    
    // TODO How/and when to destroy these on view closed...?
}
