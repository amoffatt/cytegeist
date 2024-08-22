//
//  ChartView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI

fileprivate enum ChartDataRequest {
    case histogram1D(query:APIQuery<CachedHistogram<_1D>>, axis:AxisDef, variable: FCSParameter)
    case histogram2D(APIQuery<CachedHistogram<_2D>>)
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
//                        let variableName = axis.name
                        HistogramView(query: query)
                        ChartAxisView(label: axis.label, normalizer: variable.normalizer)
                    }
            default:
                EmptyView()
//                }
                //            Histogram2DView(data: core.histogram2D(sampleRef: sample, parameterNames: parameterNames))
                //            Selector()
            }
        }
        .frame(width: 400, height: 400)
        .onChange(of: stateHash) {
            updateChartQuery()
        }
        .onChange(of: sampleRef) {
            updateSampleQuery()
        }
    }
    
    var sampleRef: SampleRef { population.sample.sampleRef }
    
    var stateHash: Int {
        var stateHash = Hasher()
        stateHash.combine(sampleRef)
        stateHash.combine(population)
        stateHash.combine(config)
        return stateHash.finalize()
    }
    
    @MainActor func updateSampleQuery() {
        let sample = population.sample.sampleRef
        sampleQuery = core.loadSample(.init(sampleRef: sample, includeData: false))
    }
            
    @MainActor func updateChartQuery()  {
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
