//
//  ChartView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI
import CytegeistLibrary

fileprivate enum ChartDataRequest {
    
    case histogram1D(APIQuery<CachedHistogram<X>>)
    case histogram2D(APIQuery<CachedHistogram<XY>>)
    
    @MainActor
    func dispose() {
        switch self {
        case .histogram1D(let q): q.dispose()
        case .histogram2D(let q): q.dispose()
        }
    }
}

public struct ChartView<Overlay>: View where Overlay:View {
    @Environment(CytegeistCoreAPI.self) var core: CytegeistCoreAPI
    
    let population: PopulationRequest
    let config: Binding<ChartDef>
    let lockAspect: Bool = true
    let chartOverlay:() -> Overlay
    
    @State var sampleQuery: APIQuery<FCSFile>? = nil
    @State fileprivate var chartQuery: ChartDataRequest? = nil
    @State var chartDims: Tuple2<CDimension?> = .init(nil, nil)
    @State var errorMessage:String = ""
    
    
    public init(population: PopulationRequest, config:Binding<ChartDef>, overlay:@escaping () -> Overlay = { EmptyView() }){
        self.population = population
        self.config = config
        self.chartOverlay = overlay
    }
    
    @MainActor
    func axisBinding(_ chartDef:Binding<ChartDef>, _ axis:WritableKeyPath<ChartDef, AxisDef?>) -> Binding<String> {
        Binding(get: {
            let axisDef = chartDef.wrappedValue[keyPath:axis]
            return axisDef?.name ?? ""
        }, set: {
            var value = chartDef.wrappedValue
            value[keyPath:axis] = AxisDef(dim: $0)
            chartDef.wrappedValue = value
        })
    }
    
    public var body: some View {
        let sampleMeta = sampleQuery?.data?.meta

        VStack {
            if !errorMessage.isEmpty {
                Text("\(errorMessage)")
                    .foregroundColor(.red)
            }
            
                VStack(spacing: 0) {
                    HStack {
                        switch chartQuery {
                            case nil:
                                VStack {}
                                    .fillAvailableSpace()
                            case .histogram1D(let query):
                                HistogramView(query: query)
                                    .overlay(chartOverlay())
                                    .fillAvailableSpace()
                            case .histogram2D(let query):
                                Histogram2DView(query: query)
                                    .overlay(chartOverlay())
                                    .fillAvailableSpace()
                        }

                        GeometryReader { proxy in
                            let axisWidth = proxy.size.height
                            ChartAxisView(dim: axisBinding(config, \.yAxis), normalizer: chartDims.y?.normalizer, sampleMeta: sampleMeta)
                                .frame(width: axisWidth, height: 80)
                                .rotationEffect(.degrees(-90), anchor: .topLeading)
                                .offset(y: axisWidth)
                        }
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                    }
                    
                    HStack(spacing: 0) {
                        ChartAxisView(dim:axisBinding(config, \.xAxis), normalizer: chartDims.x?.normalizer, sampleMeta: sampleMeta)
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 80, height: 80)
                    }
                }
                .scaledToFit()
                .fillAvailableSpace()
        }
        
        .onChange(of: population.getSample(), initial: true, updateSampleQuery)
        
        .onChange(of: population, initial: true, updateChartQuery)
        .onChange(of: config.wrappedValue, updateChartQuery)
        .onChange(of: sampleQuery?.data?.meta, updateChartQuery)
    }
    
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
            
    @MainActor func updateChartQuery()  {
        chartQuery?.dispose()
        chartQuery = nil
        errorMessage = ""
        let config = self.config.wrappedValue
        if let meta = sampleQuery?.data?.meta {
            if isEmpty(config.yAxis?.name),
               let axis = config.xAxis, !axis.name.isEmpty {
                
                if let dim = meta.parameter(named: axis.name) {
                    chartQuery = .histogram1D(core.histogram(.init(population, .init(axis.name))))
                    chartDims = .init(dim, nil)
                } else {
                    errorMessage = "X axis dimension not in dataset"
                }
            }
            else if let xAxis = config.xAxis, !xAxis.name.isEmpty,
                    let yAxis = config.yAxis, !yAxis.name.isEmpty {
                let xDim = meta.parameter(named: xAxis.name)
                let yDim = meta.parameter(named: yAxis.name)
                
                if xDim == nil {
                    errorMessage = "X axis dimension not in dataset"
                } else if yDim == nil {
                    errorMessage = "Y axis dimension not in dataset"
                } else {
                    print("Creating chart for \(population.name)")
                    chartQuery = .histogram2D(core.histogram2D(
                        HistogramRequest(population, .init(xAxis.name, yAxis.name))))
                    chartDims = .init(xDim, yDim)
                }
            }
            else {
                errorMessage = "Unsupported chart configuration"
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
