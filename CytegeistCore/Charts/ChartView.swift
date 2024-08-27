//
//  ChartView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI

fileprivate enum ChartDataRequest {
    
    case histogram1D(query:APIQuery<CachedHistogram<X>>, axis:AxisDef, dim: CDimension)
    case histogram2D(query:APIQuery<CachedHistogram<XY>>, axes:Tuple2<AxisDef>, dims:Tuple2<CDimension>)
    
    @MainActor
    func dispose() {
        switch self {
        case .histogram1D(query: let q): q.query.dispose()
        case .histogram2D(query: let q): q.query.dispose()
        }
    }
}

public struct ChartView<Overlay>: View where Overlay:View {
    @Environment(CytegeistCoreAPI.self) var core: CytegeistCoreAPI
    
    let population: PopulationRequest
    var config: Binding<ChartDef>
    let chartOverlay:() -> Overlay
    
    @State var sampleQuery: APIQuery<FCSFile>? = nil
    @State fileprivate var chartQuery: ChartDataRequest? = nil
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
//        let xAxis = sampleQuery?.data?.meta.parameter(named: config.xAxis?.name)
//        let yAxis = sampleQuery?.data?.meta.parameter(named: config.yAxis?.name)
        let sampleMeta = sampleQuery?.data?.meta

        VStack {
            if !errorMessage.isEmpty {
                Text("\(errorMessage)")
                    .foregroundColor(.red)
            }
            
            switch chartQuery {
            case nil:
                EmptyView()
            case .histogram1D(let query, let axis, let dim):
                    VStack {
                        HistogramView(query: query)
                            .overlay(chartOverlay())
                        ChartAxisView(dim:axisBinding(config, \.xAxis), normalizer: dim.normalizer, sampleMeta: sampleMeta)
                    }
            case .histogram2D(let query, let axes, let dims):
//                let columns = [
//                    GridItem(.flexible(minimum: 20)),
//                    GridItem(.fixed(80)),
//                ]
//                LazyVGrid(columns:columns, spacing: 0) {
                VStack(spacing: 0) {
//                Grid {
//                    GridRow {
                    HStack(spacing: 0) {
                        Histogram2DView(query: query)
                            .overlay(chartOverlay())
                            .fillAvailableSpace()
//                        Rectangle()
//                            .fill(.blue)
//                            .fillAvailableSpace()
                        
                        GeometryReader { proxy in
                            let axisWidth = proxy.size.height
                            ChartAxisView(dim: axisBinding(config, \.yAxis), normalizer: dims.y.normalizer, sampleMeta: sampleMeta)
                                .frame(width: axisWidth, height: 80)
                                .rotationEffect(.degrees(-90), anchor: .topLeading)
                                .offset(y: axisWidth)
                        }
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                    }
//                    }
//                    .fillAvailableSpace()
                    
                    HStack(spacing: 0) {
                        ChartAxisView(dim:axisBinding(config, \.xAxis), normalizer: dims.x.normalizer, sampleMeta: sampleMeta)
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 80, height: 80)
//                            .gridCellUnsizedAxes([.vertical, .horizontal])
                    }
                }
                .fillAvailableSpace()
//                .border(.yellow)
            }
        }
        
        .onChange(of: population.getSample(), initial: true, updateSampleQuery)
        
        .onChange(of: population, initial: true, updateChartQuery)
        .onChange(of: config.wrappedValue, updateChartQuery)
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
            
    @MainActor func updateChartQuery()  {
        chartQuery?.dispose()
        errorMessage = ""
        let config = self.config.wrappedValue
        if let meta = sampleQuery?.data?.meta {
            if config.yAxis == nil,
               let axis = config.xAxis {
                
                if let dim = meta.parameter(named: axis.name) {
                    chartQuery = .histogram1D(
                        query: core.histogram(.init(population, .init(axis.name))),
                        axis: axis,
                        dim: dim
                    )
                } else {
                    errorMessage = "X axis dimension not in dataset"
                }
            }
            else if let xAxis = config.xAxis,
                    let yAxis = config.yAxis {
                let xDim = meta.parameter(named: xAxis.name)
                let yDim = meta.parameter(named: yAxis.name)
                
                if xDim == nil {
                    errorMessage = "X axis dimension not in dataset"
                } else if yDim == nil {
                    errorMessage = "Y axis dimension not in dataset"
                } else {
                    print("Creating chart for \(population.name)")
                    chartQuery = .histogram2D(
                        query: core.histogram2D(.init(population,
                                                      .init(xAxis.name, yAxis.name))),
                        axes: .init(xAxis, yAxis),
                        dims: .init(xDim!, yDim!))
                }
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
