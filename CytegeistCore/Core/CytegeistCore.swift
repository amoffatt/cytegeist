//
//  CytegeistCore.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/28/24.
//

import Foundation
import SwiftUI
import CytegeistLibrary

public enum APIError : Error {
    var message: String {
        switch self {
            case .creatingChart(let cause):
                "Error creating chart: \(cause)"
            case .parameterNotFound(let name):
                "Parameter '\(name) not found"
            case .creatingImage:
                "Could not create 2D image"
            case .noDataComputed:
                "No data computed"
            case .noSampleDataLoaded:
                "No sample data loaded"
            case .noDataAvailable:
                "No population data available"
        }
    }
    case creatingChart(_ cause:Error)
    case parameterNotFound(_ name:String)
    case creatingImage
    case noDataComputed
    case noSampleDataLoaded
    case noDataAvailable
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
    
    func error(_ error:APIError) {
        isLoading = false
        self.error = error
        print("APIQuery error: \(error.message)")
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
    
    
    // AM TODO: store all caches in a dictionary, add BaseComputeCache class, and
    // lazily create them via a cached<DataType>() method
    private var sampleCache:ComputeCache<SampleRequest, FCSFile>! = nil;
    private var populationCache:ComputeCache<PopulationRequest, CPopulationData>! = nil
    private var histogram1DCache:ComputeCache<HistogramRequest<X>, CachedHistogram<X>>! = nil
    private var histogram2DCache:ComputeCache<HistogramRequest<XY>, CachedHistogram<XY>>! = nil

    nonisolated public init() {
    }
    
    public func ensureCachesCreated() {
        if sampleCache != nil {
            return
        }
        
        sampleCache = .init(compute:_loadSample)
//        { r in
//            try self._loadSample(r)
//        }
        
        populationCache = .init(compute:_population)
//        { r in
//            try await self._population(r)
//        }
        
        histogram1DCache = .init(compute:_histogram)
//        { r in
//            return try await self._histogram(r)
//        }
        
        histogram2DCache = .init(compute:_histogram2D)
//            return try await self._histogram2D(r)
//        }
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
                    result.error(.creatingChart(error))
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
    
    nonisolated private func _getParameters(from population:CPopulationData, parameterNames:[String]) throws -> [FCSParameterData] {
        try parameterNames.map { name in
            guard let parameter = population.parameter(named: name) else {
                print(population.meta.parameterLookup.debugDescription)
                throw APIError.parameterNotFound(name)
            }
            return parameter
        }
    }
    
    nonisolated private func _population(_ request: PopulationRequest) async throws -> CPopulationData {
        switch request {
        case .sample(let sample):
            let data = try await self.sampleCache.get(.init(sample))
            return data
        case .gated(let parent, let gate, let invert, _):
            let parentData = try await self.populationCache.get(parent)
                if let gate {
                    let f:(EventData) -> PValue = invert
                    ? { gate.probability(of:$0).inverted }
                    : gate.probability
                    
                    return try parentData.multiply(filterDims: gate.dims, filter: f)
                }
                return parentData
                
            case .union(_, _):
            fatalError("Union gates not implemented")
        }
    }
    
    nonisolated private func _histogram(_ request:HistogramRequest<X>) async throws -> CachedHistogram<X> {
        let population = try await self.populationCache.get(request.population)
        let parameters = try _getParameters(from: population, parameterNames: request.dims.values)
        
        let x = parameters[0]
//        // AM DEBUGGING
//        let select = x.data.enumerated().filter { i, x in
//            population.probability(of: i).p > 0.5
//        }.map { $0.element }
        
        let h = HistogramData<X>(data: .init(x.data),
                                 probabilities: population.probabilities,
                                 size: request.size ?? .init(defaultHistogramResolution),
                                 axes: .init(x.meta.normalizer))
        let smoothed = h.convolute(kernel: request.smoothing.kernel)
        return CachedHistogram(h, smoothed, view: nil)
    }
    
    nonisolated private func _histogram2D(_ request:HistogramRequest<XY>) async throws -> CachedHistogram<XY> {
        let population = try await self.populationCache.get(request.population)
        let parameters = try _getParameters(from: population, parameterNames: request.dims.values)
        let x = parameters[0]
        let y = parameters[1]

        let h = HistogramData<XY>(
            data: .init(x.data, y.data),
            probabilities: population.probabilities,
            size: request.size ?? .init(defaultHistogramResolution, defaultHistogramResolution),
            axes: .init(x.meta.normalizer, y.meta.normalizer))
        
        guard let image = h.toImage(colormap: .jet) else {
            throw APIError.creatingImage
        }
        
        let smoothed = h.convolute(kernel: request.smoothing.kernel)
        return CachedHistogram(h, smoothed, view: AnyView(image.resizable().scaleEffect(y: -1)))
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

//public struct GateRequest : Hashable {
//    public static func == (lhs: GateRequest, rhs: GateRequest) -> Bool {
//        lhs.repr == rhs.repr
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(repr)
//    }
//    
//    public let repr: String
//    let dimNames: [String]
//    let filter: (EventData) -> PValue
//    
//    public init(repr:String, dimNames: [String], filter: @escaping (EventData) -> PValue) {
//        self.repr = repr
//        self.dimNames = dimNames
//        self.filter = filter
//    }
//}


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
    public static func == (lhs: PopulationRequest, rhs: PopulationRequest) -> Bool {
        switch (lhs, rhs) {
            case (.sample(let lhsSample), .sample(let rhsSample)):
                return lhsSample == rhsSample
            case (.gated(let lhsParent, let lhsGate, let lhsInvert, _), .gated(let rhsParent, let rhsGate, let rhsInvert, _)):
                return lhsParent == rhsParent && lhsGate?.isEqualTo(rhsGate) ?? false && lhsInvert == rhsInvert
            case (.union(let lhsParents), .union(let rhsParents)):
//                return lhsParents.sorted() == rhsParents.sorted() // Compare sorted parents for order independence
                fatalError()
            default:
                return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
            case .sample(let sample):
                sample.hash(into: &hasher)
            case .gated(let parent, let gate, let invert, _):
                parent.hash(into: &hasher)
                gate?.hash(into: &hasher)
                invert.hash(into: &hasher)
            case .union(_, union: let union):
                fatalError()
        }
    }
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
    
    public var name: String {
        switch self {
        case .sample(let sampleRef):
            sampleRef.url.absoluteString
        case .gated(_, _, _, let name):
            name
        case .union(let parents):
            "Union"
        }
    }

    case sample(_ sample: SampleRef)
    case gated(_ parent: PopulationRequest, gate:(any GateDef)?, invert:Bool, name:String)
    case union(_ parent: PopulationRequest, union: [PopulationRequest])
    
    func getSample() -> SampleRef {
        switch self {
        case .sample(let s): return s
        case .gated( let parent, _, _, _): return parent.getSample()
        case .union(let parent, _): return parent.getSample()
        }
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
    
    public let dims:D.Strings
    public let size:D.IntCoord?
    public let smoothing:HistogramSmoothing
    
    public init(_ population: PopulationRequest, _ dims: D.Strings, size:D.IntCoord? = nil, smoothing:HistogramSmoothing = .off) {
        self.population = population
        self.dims = dims
        self.size = size
        self.smoothing = smoothing
    }
}


public struct CachedHistogram<D:Dimensions> {
    public let histogram:HistogramData<D>
    public let smoothed:HistogramData<D>?
    public let view:AnyView?
    
    public init(_ histogram: HistogramData<D>, _ smoothed:HistogramData<D>?, view: AnyView? =  nil) {
        self.histogram = histogram
        self.smoothed = smoothed
        self.view = view
    }
}

public struct HistogramStatRequest {
    public let parent: HistogramRequest<X>
    
    public let name: String
}

