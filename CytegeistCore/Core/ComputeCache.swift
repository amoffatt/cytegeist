//
//  ComputeGraph.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/18/24.
//

import Foundation
import SwiftUI
import CytegeistLibrary


fileprivate class ComputeHandle<Request, Data> {
    let request:Request

    var done = false
    var data:Data? = nil
    var error:Error? = nil
    var lastRequested:Date = Date()
    
    let semaphore:CSemaphore = .init()

    init(_ request: Request) {
        self.request = request
//        self.data = data
//        self.error = error
//        self.requested = requested
    }
    
}


public actor ComputeCache<Request:Hashable, Data> : Identifiable {
    
    // TODO: Naive cache pruning system. Improve
    public var maxCacheItems = 10
    
    public typealias ComputeFunction = (Request) async throws -> Data

    private var _cache:[Request:ComputeHandle<Request, Data>] = [:]
    
    private let _compute:ComputeFunction
    
    public init(compute:@escaping ComputeFunction) {
        self._compute = compute
    }
    
    public func get(_ request:Request) async throws -> Data {
//        // AM DEBUGGING
//        return try await self._compute(request)
        
        var handle = _cache[request]
        
        if handle == nil {
            handle = ComputeHandle<Request, Data>(request)
            _cache[request] = handle
            pruneOldHandles()
            
            Task.detached {
                do {
                    print ("Request beginning compute: \(request)")
                    let result = try await self._compute(request)
                    print ("  ==> Request finished compute: \(request)")

                    await self.handleSuccess(request, data:result)
                } catch {
                    await self.handleError(request, error:error)
                }
            }
            
        }
        
        return try await awaiter(handle!)
    }
    
    
    private func pruneOldHandles() {
        
        // Only remove handles that have already finished
        let finishedHandles = _cache.values.filter { $0.done }
        if finishedHandles.count < maxCacheItems {
            return
        }
        
        for _ in maxCacheItems...finishedHandles.count {
            let oldest = finishedHandles.min {
                $0.lastRequested > $1.lastRequested
            }
            
            _cache.removeValue(forKey: oldest!.request)
        }
    }
    
    private func awaiter(_ handle:ComputeHandle<Request, Data>) async throws -> Data {
        handle.lastRequested = Date()
        
        if !handle.done {
            await handle.semaphore.wait()
        }
        
        if let error = handle.error {
            throw error
        }
        
        guard let data = handle.data else {
            throw APIError.noDataComputed
        }
        
        return data
    }
    
    private func handleSuccess(_ request:Request, data:Data) async {
        guard let handle = _cache[request] else {
            print("Error: ComputeHandle no longer exists")
            return
        }
        handle.data = data
        handle.done = true
        await handle.semaphore.release()
    }
    
    private func handleError(_ request:Request, error:Error) async {
        guard let handle = _cache[request] else {
            print("Error: ComputeHandle no longer exists")
            return
        }
        handle.error = error
        handle.done = true
        await handle.semaphore.release()
    }

    
    // TODO How/and when to destroy these on view closed...?
}
