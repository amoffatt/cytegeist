//
//  ChartView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI

fileprivate enum ChartDataRequest {
    
    case histogram1D(query:APIQuery<CachedHistogram<X>>, axis:AxisDef, variable: CDimension)
    case histogram2D(query:APIQuery<CachedHistogram<XY>>, axes:Tuple2<AxisDef>, variables:Tuple2<CDimension>)
    
    @MainActor
    func dispose() {
        switch self {
        case .histogram1D(query: let q): q.query.dispose()
        case .histogram2D(query: let q): q.query.dispose()
        }
    }
}

public struct ChartView: View {
    @Environment(CytegeistCoreAPI.self) var core: CytegeistCoreAPI
    
    let population: PopulationRequest
    let config: ChartDef
    
    @State var sampleQuery: APIQuery<FCSFile>? = nil
    @State fileprivate var chartQuery: ChartDataRequest? = nil
//    @State var parameterNames: Tuple2<String>
    
    public init(population: PopulationRequest, config:ChartDef) {
//        self.sample = sample
        self.population = population
        self.config = config
//        self.parameterNames = parameterNames
    }
    
    public var body: some View {
        
        VStack {
            switch chartQuery {
            case nil:
                EmptyView()
            case .histogram1D(let query, let axis, let variable):
                    VStack {
                        HistogramView(query: query)
                        ChartAxisView(label: axis.label, normalizer: variable.normalizer)
                    }
                    .background(.blue)
            default:
                EmptyView()
//                }
                //            Histogram2DView(data: core.histogram2D(sampleRef: sample, parameterNames: parameterNames))
                //            Selector()
            }
        }
        
        .onChange(of: population.getSample(), initial: true, updateSampleQuery)
        
        .onChange(of: population, initial: true, updateChartQuery)
        .onChange(of: config, updateChartQuery)
        .onChange(of: sampleQuery?.data?.meta, updateChartQuery)
    }
    
//    var sampleRef: SampleRef? { population.getSample() }
    
//    var stateHash: Int {
//        var stateHash = Hasher()
//        stateHash.combine(sampleRef)
//        stateHash.combine(population)
//        stateHash.combine(config)
//        return stateHash.finalize()
//    }
    
    @MainActor func updateSampleQuery() {
        sampleQuery?.dispose()
        let sample = SampleRequest(population.getSample(), includeData: false)
        sampleQuery = core.loadSample(sample)
    }
    
//    todo()
    // Do we
    // 1) update the query's data when parent populations change?
        // No. because the chart view will be the one requesting the updated populations,
        // so it already knows about the change and is the one sending the query
    // 2) So
        //      a) what to store in the cache
        //      b) who is checking for population change?
        //      c) where/how do we track who depends on what evaluated population, so we know when it can be thrown away
        //      d) when a parent changes, does the populations own hash/repr value change?
        //      e) if it does, how do we avoid deleting unchanged parents of the changed parent
        //      f)
    
        // a cached population should be stored under the repr/hash of it and all it's ancestors
        //  That way, when a population changes, the children will all start recomputations on
        // everything *up to* the one that changed
            
    @MainActor func updateChartQuery()  {
        chartQuery?.dispose()
        if let meta = sampleQuery?.data?.meta {
            if config.yAxis == nil,
               let axis = config.xAxis,
               let variable = meta.parameter(named: axis.name) {
                chartQuery = .histogram1D(
                    query: core.histogram(.init(population, .init(axis.name))),
                    axis: axis,
                    variable: variable
                )
            }
            
            
        }
    }
}

//#Preview {
//    let core = CytegeistCoreAPI()
////    return VStack { Text("Test world")}
//    let sample = SampleRef(url: DemoData.facsDivaSample0!)
//    let population = PopulationRequest(sample)
//    let parameters = Tuple2("FSC-A", "PacificBlue-A")
///
//    return ChartView(population: population, parameterNames: parameters)
//        .environment(core)
//}
