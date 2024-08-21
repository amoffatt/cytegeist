//
//  CytegeistCore.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/28/24.
//

import Foundation
import SwiftUI

public struct APIError : Error {
    public let message: String
    public let internalError: Error?
    
    init(_ message: String, _ internalError: Error? = nil) {
        self.message = message
        self.internalError = internalError
    }
}

@Observable
public class APIQuery<T> {
    public private(set) var isLoading:Bool = true
    public private(set) var data:T? = nil
    public private(set) var error:APIError?
    public private(set) var viewPriority: Int = 1
    
    init() {
        
    }
    
    public func dispose() {
        viewPriority = 0
    }
    
    @MainActor
    func progress(_ result:T) {
        data = result
    }

    @MainActor
    func success(_ result:T) {
        data = result
        isLoading = false
    }
    
    @MainActor
    func error(_ message:String, _ internalError:Error) {
        isLoading = false
        error = .init(message, internalError)
        print("APIQuery error: \(message): \(internalError)")
    }
}

//func resultOf<T>(_ closure:() throws -> T) -> T? {
//    do {
//        return try closure()
//    } catch {
//        print("Error")
//    }
//}

//public class TaskUtil {
//    @discardableResult
//    static func safeDetached<Success>(
//        priority: TaskPriority? = nil,
//        operation: @escaping () async -> Success
//    ) -> Task<Success, Failure> {
//        
//    }
//}

public let defaultHistogramResolution:Int = 256

@MainActor
public class CytegeistCoreAPI : ObservableObject {
    private let fcsReader:FCSReader = .init()
    
    
    private var sampleCache:ComputeCache<SampleRequest, FCSFile>! = nil;
    private var histogram1DCache:ComputeCache<HistogramRequest<_1D>, CachedHistogram<_1D>>! = nil
    private var histogram2DCache:ComputeCache<HistogramRequest<_2D>, CachedHistogram<_2D>>! = nil

    public init() {
        sampleCache = .init { r in
            try self._loadSample(r)
        }
        
        histogram1DCache = .init { r in
            let sample = try await self.sampleCache.get(r.population.sample)
            // TODO add population request here
            return try self._histogram(r, sample:sample)
        }
        
        histogram2DCache = .init { r in
            let sample = try await self.sampleCache.get(r.population.sample)
            return try self._histogram2D(r, sample:sample)
        }

    }
    
    public func histogram(_ request:HistogramRequest<_1D>) -> APIQuery<CachedHistogram<_1D>> {
        query(request) { r in
            try await self.histogram1DCache.get(r)
        }
    }
    
    public func histogram2D(_ request:HistogramRequest<_2D>) -> APIQuery<CachedHistogram<_2D>> {
        query(request) { r in
            try await self.histogram2DCache.get(request)
        }

//        return sampleDataQuery(sampleRef: sampleRef, parameterNames: parameterNames.values) { parameters in
//            let data = HistogramData<_2D>(
//                data: .init(
//                    parameters[0].data,
//                    parameters[1].data
//                ),
//                size: .init(resolution, resolution),
//                axes: .init(
//                    parameters[0].meta.normalizer,
//                    parameters[1].meta.normalizer
//                )
//            )
//            
//            guard let image = data.toImage(colormap: .jet) else {
//                throw APIError("Could not create 2D image")
//            }
//            
//            return CachedHistogram(histogram: data, view: AnyView(image.resizable()))
//        }
    }
    
    private func query<Request, Data>(_ request:Request, compute: @escaping (Request) async throws -> Data) -> APIQuery<Data> {
        let result:APIQuery<Data> = APIQuery()

        Task.detached {
            do {
                print("Computing query \(request)")
                let data = try await compute(request)
                print("  ==> Finished computing query \(request)")

                await MainActor.run {
                    result.success(data)
                }
                
            } catch {
                print("Error creating histogram: \(error)")
                await MainActor.run {
                    result.error("Error creating chart", error)
                }
            }
        }
        
        return result
    }

//    private func sampleDataQuery<Data>(sampleRef:SampleRef, parameterNames:[String], compute: @escaping ([FCSParameterData]) throws -> Data) -> APIQuery<Data> {
//        let result:APIQuery<Data> = APIQuery()
////        let resolution = self.histogramResolution
//
//        Task.detached {
//            do {
//                print("Loading data for '\(sampleRef.filename)'")
//                let sample = try self._loadSample(ref: sampleRef)
//                let meta = sample.meta
//                
//                print("  ==> Data loaded. \(meta.eventCount) events, \(String(describing: meta.parameters?.count)) parameters")
//                
//                let parameters = try self._getParameters(from: sample, parameterNames: parameterNames)
//                
//                print("  ==> Parameter loaded")
//
//                let data = try compute(parameters)
//                
//                await MainActor.run {
//                    result.success(data)
//                }
//                
//            } catch {
//                print("Error creating histogram: \(error)")
//                await MainActor.run {
//                    result.error("Error creating chart", error)
//                }
//            }
//        }
//        
//        return result
//    }
    
    public func loadSample(_ request:SampleRequest) -> APIQuery<FCSFile> {
        query(request) { r in
            try await self.sampleCache.get(r)
        }
    }

//    public func loadSample(sampleRef:SampleRef, includeData:Bool = true) -> APIQuery<FCSFile> {
//        let result = APIQuery<FCSFile>()
//        print("Begin load data...")
//        todo() // use query()
//
//        Task.detached {
//            do {
//                print("Loading data for '\(sampleRef.filename)'")
//                let sample = try self._loadSample(ref: sampleRef, includeData: includeData)
//
//                await MainActor.run {
//                    print("Sample loaded...")
//                    result.success(sample)
//                }
//
//            } catch {
//                await MainActor.run {
//                    result.error("Error creating chart", error)
//                }
//            }
//        }
//
//        return result
//    }
//
        
    
    
    nonisolated private func _loadSample(_ request: SampleRequest) throws -> FCSFile {
        try self.fcsReader.readFCSFile(at: request.sampleRef.url, includeData: request.includeData)
    }
    
    nonisolated private func _getParameters(from sample:FCSFile, parameterNames:[String]) throws -> [FCSParameterData] {
        try parameterNames.map { name in
            guard let parameter = sample.parameter(named: name) else {
                print(sample.meta.parameterLookup.debugDescription)
                throw APIError("Parameter '\(name) not found")
            }
            return parameter
        }
    }
    
    nonisolated private func _histogram(_ request:HistogramRequest<_1D>, sample:FCSFile) throws -> CachedHistogram<_1D> {
        let parameters = try _getParameters(from: sample, parameterNames: request.axisNames.values)
        let x = parameters[0]
        let h = HistogramData<_1D>(data: .init(x.data), size: request.size ?? .init(defaultHistogramResolution), axes: .init(x.meta.normalizer))
        return CachedHistogram(h, view: nil)
    }
    
    nonisolated private func _histogram2D(_ request:HistogramRequest<_2D>, sample:FCSFile) throws -> CachedHistogram<_2D> {
        let parameters = try _getParameters(from: sample, parameterNames: request.axisNames.values)
        let x = parameters[0]
        let y = parameters[1]
        let h = HistogramData<_2D>(
            data: .init(x.data, y.data),
            size: request.size ?? .init(defaultHistogramResolution, defaultHistogramResolution),
            axes: .init(x.meta.normalizer, y.meta.normalizer))
        
        guard let image = h.toImage(colormap: .jet) else {
            throw APIError("Could not create 2D image")
        }
        
        return CachedHistogram(h, view: AnyView(image.resizable()))
    }

}

public struct SampleRequest : Hashable {
    let sampleRef:SampleRef
    let includeData:Bool
    
    public init(sampleRef:SampleRef, includeData:Bool) {
        self.sampleRef = sampleRef
        self.includeData = includeData
    }
}

public struct PopulationRequest : Hashable {
    let sample: SampleRequest
    
    // TODO add gate lineage
    
    // Each PopulationRequest as one gate with parent population?
    // How to handle OR gates?
    
    public init(_ sampleRef: SampleRef) {
        self.sample = .init(sampleRef:sampleRef, includeData:true)
    }
}


public struct HistogramRequest<D:Dim> : Hashable {
//    public static func == (lhs: HistogramRequest<D>, rhs: HistogramRequest<D>) -> Bool {
//        lhs.population == rhs.population && lhs.axisNames == rhs.axisNames
//    }
    let population:PopulationRequest
    
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(population)
//        hasher.combine(axisNames)
//        hasher.combine(size)
//    }
    
//    public let raw:String
    
    public let axisNames:D.Strings
    public let size:D.IntCoord?
    
    public init(_ population: PopulationRequest, _ axisNames: D.Strings, size:D.IntCoord? = nil) {
        self.population = population
        self.axisNames = axisNames
        self.size = size
    }
}


public struct CachedHistogram<D:Dim> {
    public let histogram:HistogramData<D>
    public let view:AnyView?
    
    public init(_ histogram: HistogramData<D>, view: AnyView? =  nil) {
        self.histogram = histogram
        self.view = view
    }
}


