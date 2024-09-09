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
            case .computingQuery(let cause):
                "Error computing query result: \(cause)"
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
    case computingQuery(_ cause:Error)
    case parameterNotFound(_ name:String)
    case creatingImage
    case noDataComputed
    case noSampleDataLoaded
    case noDataAvailable
}

@Observable
@MainActor
public class BaseAPIQuery {
    public fileprivate(set) var isLoading:Bool = false
    public fileprivate(set) var error:APIError?
    public fileprivate(set) var viewPriority: Int = 1
    
    // TODO use to determine when related data should be uncached
    public private(set) var disposeTime: Date? = nil
    
    nonisolated init() {
    }

    public func dispose() {
        viewPriority = 0
        disposeTime = Date.now
    }
}

public typealias ComputeAction<Result> = () async throws -> Result

@Observable
@MainActor
public class APIQuery<T> : BaseAPIQuery {
    public private(set) var data:T? = nil
    private var _semaphore:CSemaphore? = nil
    
    // Accessed in constructor, destructor, and dispose()
    @ObservationIgnored
    private var taskHandle:Task<Void, Never>? = nil
    @ObservationIgnored
    private var pendingCompute:ComputeAction<T>? = nil

    override nonisolated public init() {}
    
    
    fileprivate func update(_ compute: @escaping ComputeAction<T>) {
//        let existingTask = taskHandle
        // Don't cancel the existing task - so we get incremental updates
        // along the way while user is adjusting parameters/gates
        pendingCompute = compute
        isLoading = true
        
        if let taskHandle {
            // If task is currently running, no need to start another
            return
        }
        
        taskHandle = Task { // AM: don't use Task.detached bc cancellation will not be propagated to this subtask
            do {
                // Await for the existing task to complete before continuing
//                if let existingTask {
//                    let _ = await existingTask.result
//                }
//                print("Query running on main thread: \(Thread.isMainThread)")
                
                var data:T? = nil
                while let compute = getPendingCompute() {
                    
                    // Store any progress/data that has been computed so far
                    if let data {
                        await MainActor.run {
                            self.progress(data)
                        }
                    }
                    
                    try Task.checkCancellation()
                    
                    //                print("Computing query \(request)")
                    data = try await compute()
                    //                print("  ==> Finished computing query \(request)")
                }
                
                self.taskHandle = nil

                if let data {
//                    await MainActor.run {
                        self.success(data)
//                    }
                }
                
            } catch {
                if error is CancellationError {
                } else {
//                    await MainActor.run {
                        self.error(.computingQuery(error))
//                    }
                }
            }
        }
    }
    
    private func getPendingCompute() -> ComputeAction<T>? {
        let action = pendingCompute
        pendingCompute = nil
        return action
    }
    
    // Using deinit() to cancel tasks does not seem to work properly
//    deinit {
////        Task.detached {
////            await MainActor.run {
//        print("Deinit() on task")
//        taskHandle?.cancel()
////            }
////        }
//    }
    
    
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
    
    override public func dispose() {
        super.dispose()
        taskHandle?.cancel()
        taskHandle = nil
        
        data = nil
    }
}

public extension View {
    @MainActor
    func update<Data>(query:APIQuery<Data>, onChangeOf value: some Equatable, with compute: @escaping ComputeAction<Data>) -> some View {
        self
            .onChange(of: value, initial: true) {
                query.update(compute)
            }
            .onDisappear {
                query.dispose()
            }
    }
}


public let defaultHistogramResolution:Int = 256


@MainActor
@Observable
public class CytegeistCoreAPI {
    private let fcsReader:FCSReader = .init()
    
    
    private var sampleCache:ComputeCache<SampleRequest, FCSFile> { cache(_loadSample) }
    private var populationCache:ComputeCache<PopulationRequest, CPopulationData> { cache(_population) }
    private var histogram1DCache:ComputeCache<HistogramRequest<X>, CachedHistogram<X>> { cache(_histogram) }
//    private var histogram2DCache:ComputeCache<HistogramRequest<XY>, CachedHistogram<XY>>! = nil
    private var _caches:[ObjectIdentifier:Any] = [:]

    nonisolated public init() {
    }
    
    // Lazily creates caches when needed
    private func cache<Request, Data>(_ compute:@escaping (Request) async throws -> Data) -> ComputeCache<Request, Data> {
        if let cache = _caches[ObjectIdentifier(Request.self)] {
            return cache as! ComputeCache<Request, Data>
        }
        let cache = ComputeCache(compute: compute)
        _caches[ObjectIdentifier(Request.self)] = cache
        return cache
    }
    
    public func statistics(_ population:PopulationRequest?, _ dim:String, _ statistics:Statistic...) -> ComputeAction<StatisticBatch> {
        return {
            guard let population else {
                return [:]
            }
            var stats = StatisticBatch()
            for s in statistics {
                let r = StatisticRequest(population, dim, s)
                stats[s] = try await self.cache(self._statistic).get(r)
            }
            return stats
        }
    }
    
    public func histogram(_ request:HistogramRequest<X>) -> APIQuery<CachedHistogram<X>> {
        // AM DEBUGGING
        let query = APIQuery<CachedHistogram<X>>()
        query.update {
            try await self.cache(self._histogram).get(request)
        }
        return query
    }
    
    public func histogram2D( _ request:HistogramRequest<XY>) -> APIQuery<CachedHistogram<XY>> {
        // AM DEBUGGING
        let query = APIQuery<CachedHistogram<XY>>()
        query.update {
            try await self.cache(self._histogram2D).get(request)
        }
        return query
    }
    
    public func loadSample(_ request:SampleRequest) -> APIQuery<FCSFile> {
        // AM DEBUGGING
        let query = APIQuery<FCSFile>()
        query.update {
            try await self.cache(self._loadSample).get(request)
        }
        return query
    }

    
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
        try Task.checkCancellation()
        
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
        
        try Task.checkCancellation()
        
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

        try Task.checkCancellation()
        
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
    
    nonisolated private func _statistic(_ r:StatisticRequest) async throws -> Double {
        
//        switch r.statistic {

            //            let parentHistogram = try await _statisticHistogram(r.population.parent, r.dim)
            //            return histogram.totalCount / parentHistogram.totalCount
//            let rootHistogram = try await _statisticHistogram(r.population.parent, r.dim)
//            return histogram.totalCount / parentHistogram.totalCount

        
        // Stats not based on a histogram
        switch r.statistic {
            case.freqOfParent, .freqOfTotal:
                let population = try await self.populationCache.get(r.population)
                
                let ancestorRequest = r.statistic == .freqOfTotal ? r.population.getRoot() : r.population.getParent()
                if let ancestorRequest {
                    let ancestor = try await self.populationCache.get(ancestorRequest)
                    return population.count / ancestor.count
                }
                return .nan
            default:
                break
        }
        
        let histogram = try await _statisticHistogram(r.population, r.dim)
        // Stats based on a histogram
        switch r.statistic {
            case .percentile(let p):
                return histogram.percentile(p)
            case .median:
                return histogram.percentile(0.5)
            case .cv:
                break       // not implemented
            case .mean:
                return histogram.mean()
                
            default: break
        }
        
        print("Unsupported statistic \(r.statistic)")
        return .nan
    }
    
    nonisolated private func _statisticHistogram(_ population: PopulationRequest, _ dim:String) async throws -> HistogramData<X> {
        let histogramRequest = HistogramRequest<X>(population, Tuple1(dim), smoothing: .off)
        let histogram = try await self.histogram1DCache.get(histogramRequest)
        return histogram.histogram
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

public enum Statistic : Hashable {
    case freqOfParent, freqOfTotal
    case percentile(Double)
    case mean, median, cv
}

public struct StatisticRequest : Hashable {
    public let population:PopulationRequest
    public let statistic:Statistic
    public let dim:String

    public init(_ population: PopulationRequest, _ dimName:String, _ statistic: Statistic) {
        self.population = population
        self.dim = dimName
        self.statistic = statistic
    }
}

public typealias StatisticBatch = [Statistic:Double]



public indirect enum PopulationRequest: Hashable, CustomStringConvertible {
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
            case .union(_, _):
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
                sampleRef.url.lastPathComponent
        case .gated(_, _, _, let name):
            name
        case .union(_, _):
            "Union"
        }
    }

    case sample(_ sample: SampleRef)
    case gated(_ parent: PopulationRequest, gate:(any GateDef)?, invert:Bool, name:String)
    case union(_ parent: PopulationRequest, union: [PopulationRequest])
    
    func getSample() -> SampleRef? {
        switch getRoot() {
            case .sample(let s):
                return s
            default:
                return nil
        }
    }
    
    func getParent() -> PopulationRequest? {
        switch self {
            case .sample: return nil
            case .gated(let parent, _, _, _), .union(let parent, _):
                return parent
        }
    }
    
    func getRoot() -> PopulationRequest {
        if let parent = getParent() {
            return parent.getRoot()
        }
        return self
    }
    
    public var description: String {
        var s = name
        var current = self
        while let parent = current.getParent() {
            s = "\(parent.name)/\(s)"
            current = parent
        }
        
        return s
    }
    
}


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

