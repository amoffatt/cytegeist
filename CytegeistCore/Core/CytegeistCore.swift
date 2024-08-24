//
//  CytegeistCore.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/28/24.
//

import Foundation
import SwiftUI
import CytegeistLibrary

public struct APIError : Error {
    public let message: String
    public let internalError: Error?
    
    init(_ message: String, _ internalError: Error? = nil) {
        self.message = message
        self.internalError = internalError
    }
}

@Observable
@MainActor
public class BaseAPIQuery {
    public fileprivate(set) var isLoading:Bool = true
    public fileprivate(set) var error:APIError?
    public fileprivate(set) var viewPriority: Int = 1
    
    // TODO use to determine when related data should be uncached
    public private(set) var disposeTime: Date? = nil
    
    init() {
    }

    public func dispose() {
        viewPriority = 0
        disposeTime = Date.now
    }
}


@Observable
@MainActor
public class APIQuery<T> : BaseAPIQuery {
    public private(set) var data:T? = nil
    private var _semaphore:CSemaphore? = nil
    
    
    func progress(_ result:T) {
        data = result
    }

    func success(_ result:T) {
        data = result
        isLoading = false
        releaseSemaphore()
    }
    
    func error(_ message:String, _ internalError:Error) {
        isLoading = false
        error = .init(message, internalError)
        print("APIQuery error: \(message): \(internalError)")
        releaseSemaphore()
    }
    
    private func releaseSemaphore() {
        Task {
            await _semaphore?.release()
        }
    }
    
    
    public func getResult() async throws -> T {
        if let error {
            throw error
        }
        
        if !isLoading {
            assert(data != nil)
            return data!        // Should not be null here
        }
        
        if _semaphore == nil {
            _semaphore = .init()
        }
        
        await _semaphore!.wait()
        
        if let error {
            throw error
        }
        
        assert(data != nil)
        return data!
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
@Observable
public class CytegeistCoreAPI {
    private let fcsReader:FCSReader = .init()
    
    
    private var sampleCache:ComputeCache<SampleRequest, FCSFile>! = nil;
    private var histogram1DCache:ComputeCache<HistogramRequest<X>, CachedHistogram<X>>! = nil
    private var histogram2DCache:ComputeCache<HistogramRequest<XY>, CachedHistogram<XY>>! = nil

    nonisolated public init() {
    }
    
    public func ensureCachesCreated() {
        if sampleCache != nil {
            return
        }
        
        sampleCache = .init { r in
            try self._loadSample(r)
        }
        
        histogram1DCache = .init { r in
            let sample = try await self.sampleCache.get(.init(r.population.sample))
            // TODO add population request here
            return try self._histogram(r, sample:sample)
        }
        
        histogram2DCache = .init { r in
            let sample = try await self.sampleCache.get(.init(r.population.sample))
            return try self._histogram2D(r, sample:sample)
        }
    }
    
    public func histogram(_ request:HistogramRequest<X>) -> APIQuery<CachedHistogram<X>> {
        query(request) { r in
            try await self.histogram1DCache.get(r)
        }
    }
    
    public func histogram2D(_ request:HistogramRequest<XY>) -> APIQuery<CachedHistogram<XY>> {
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
        ensureCachesCreated()
        
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
    
    nonisolated private func _histogram(_ request:HistogramRequest<X>, sample:FCSFile) throws -> CachedHistogram<X> {
        let parameters = try _getParameters(from: sample, parameterNames: request.variableNames.values)
        let x = parameters[0]
        let h = HistogramData<X>(data: .init(x.data), size: request.size ?? .init(defaultHistogramResolution), axes: .init(x.meta.normalizer))
        return CachedHistogram(h, view: nil)
    }
    
    nonisolated private func _histogram2D(_ request:HistogramRequest<XY>, sample:FCSFile) throws -> CachedHistogram<XY> {
        let parameters = try _getParameters(from: sample, parameterNames: request.variableNames.values)
        let x = parameters[0]
        let y = parameters[1]
        let h = HistogramData<XY>(
            data: .init(x.data, y.data),
            size: request.size ?? .init(defaultHistogramResolution, defaultHistogramResolution),
            axes: .init(x.meta.normalizer, y.meta.normalizer))
        
        guard let image = h.toImage(colormap: .jet) else {
            throw APIError("Could not create 2D image")
        }
        
        return CachedHistogram(h, view: AnyView(image.resizable()))
    }

}

public struct SampleRequest : Identifiable, Hashable {
    public let id: String
    let sampleRef:SampleRef
    let includeData:Bool
    
    public init(_ sampleRef:SampleRef, includeData:Bool = true) {
        self.id = "\(includeData) \(sampleRef.url.absoluteString)"
        self.sampleRef = sampleRef
        self.includeData = includeData
    }
}

public struct GateRequest : Hashable {
    public static func == (lhs: GateRequest, rhs: GateRequest) -> Bool {
        lhs.repr == rhs.repr
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(repr)
    }
    
    public let repr: String
    let variableNames: [String]
    let filter: (EventData) -> PValue
    
    public init(repr:String, variableNames: [String], filter: @escaping (EventData) -> PValue) {
        self.repr = repr
        self.variableNames = variableNames
        self.filter = filter
    }
}


//public indirect enum ParentPopulation: Identifiable, Hashable {
//    public var id: String {
//        switch self {
//        case .sample(let value):
//            return value.sampleRef.url.absoluteString
//        case .population(let value):
//            return value.id
//        }
//    }
//    
//    case sample(SampleRequest)
//    case population(PopulationRequest)
//}



public indirect enum PopulationRequest: Hashable {
//    public var id: String {
//        switch self {
//            
//        case .sample(let sample):
//            sample.id
//        case .gated(parent: let parent, gate: let gate):
//            
//        case .merge(parents: let parents):
//            
//        }
//    }
    
    case sample(_ sample: SampleRef)
    case gated(_ parent: PopulationRequest, gate:GateRequest)
    case merge(_ parents: [PopulationRequest])
    
    var sample: SampleRef {
        fatalError()
    }
}


//public struct PopulationRequest : Hashable {
//    public let id: String
//    public let info: PopulationType
////    let parent: ParentPopulation
//    let sample: SampleRequest
////    let parent: ParentPopulation
//    
//    // TODO add gate lineage
//    
//    // Each PopulationRequest as one gate with parent population?
//    // How to handle OR gates?
//    
//    public init(_ sampleRef: SampleRef) {
//        self.sample = .init(sampleRef)
//        self.id = sample.id
//        self.gates = []
//    }
//    
//    public init(id:String, sample: SampleRef, gates: [GateRequest]) {
//        self.id = id
//        self.sample = .init(sample)
//        self.gates = gates
//    }
//}


public struct HistogramRequest<D:Dimensions> : Hashable {
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
    
    public let variableNames:D.Strings
    public let size:D.IntCoord?
    
    public init(_ population: PopulationRequest, _ variableNames: D.Strings, size:D.IntCoord? = nil) {
        self.population = population
        self.variableNames = variableNames
        self.size = size
    }
}


public struct CachedHistogram<D:Dimensions> {
    public let histogram:HistogramData<D>
    public let view:AnyView?
    
    public init(_ histogram: HistogramData<D>, view: AnyView? =  nil) {
        self.histogram = histogram
        self.view = view
    }
}


