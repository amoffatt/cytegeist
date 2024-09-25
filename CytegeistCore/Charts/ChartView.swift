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
    var config: Binding<ChartDef?>
    let chartOverlay:() -> Overlay
    
    @State var sampleQuery: APIQuery<FCSFile>? = nil
    @State fileprivate var chartQuery: ChartDataRequest? = nil
    @State var chartDims: Tuple2<CDimension?> = .init(nil, nil)
    @State var errorMessage:String = ""
    
    
    public init(population: PopulationRequest, config:Binding<ChartDef?>, overlay:@escaping () -> Overlay = { EmptyView() }){
        self.population = population
        self.config = config
        self.chartOverlay = overlay
    }
    
    @MainActor
    func axisBinding(_ chartDef:Binding<ChartDef?>, _ axis:WritableKeyPath<ChartDef, AxisDef?>) -> Binding<String> {
        Binding(get: {
            let axisDef = chartDef.wrappedValue?[keyPath:axis]
            return axisDef?.name ?? ""
        }, set: {
            var value = chartDef.wrappedValue
            value?[keyPath:axis] = AxisDef(dim: $0)
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
            
//                let columns = [
//                    GridItem(.flexible(minimum: 20)),
//                    GridItem(.fixed(80)),
//                ]
//                LazyVGrid(columns:columns, spacing: 0) {
                VStack(spacing: 0) {
//                Grid {
//                    GridRow {
                    HStack {
                        ZStack {
                            switch chartQuery {
                                case nil:                          VStack {}
                                        .fillAvailableSpace()
                                case .histogram1D(let query):      HistogramView(query: query)
                                        .overlay(chartOverlay())
                                        .border(.black)
                                        .background(.white)
                                        .fillAvailableSpace()
                                case .histogram2D(let query):      Histogram2DView(query: query)
                                        .border(.black)
                                        .background(.white)
                                        .overlay(chartOverlay())
                                        .fillAvailableSpace()
                            }
                        } .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fill)

                        GeometryReader { proxy in
                            let axisWidth = proxy.size.height
                            ChartAxisView(dim: axisBinding(config, \.yAxis), normalizer: chartDims.y?.normalizer, sampleMeta: sampleMeta)
                                .frame(width: axisWidth, height: 80)
                                .rotationEffect(.degrees(-90), anchor: .topLeading)
                                .offset(x: -8, y: axisWidth-1)   // AT?
                        }
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                    }
                   

//                    }
//                    .fillAvailableSpace()
                    
                    HStack(spacing: 0) {
                        ChartAxisView(dim:axisBinding(config, \.xAxis), normalizer: chartDims.x?.normalizer, sampleMeta: sampleMeta)
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
        .updateSampleQuery(core, population, query: $sampleQuery)
        
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
    
            
    @MainActor func updateChartQuery()  {
        chartQuery?.dispose()
        chartQuery = nil
        errorMessage = ""
        let config = self.config.wrappedValue
        
        guard let config else {    return   }
        
        if let meta = sampleQuery?.data?.meta {
            if isEmpty(config.yAxis?.name),
               let axis = config.xAxis, !axis.name.isEmpty {
                
                if let dim = meta.parameter(named: axis.name) {
                    chartQuery = .histogram1D(core.histogram(.init(population, .init(axis.name), chartDef: config)))
                    chartDims = .init(dim, nil)
                } else {
                    errorMessage = "X axis dimension not in dataset"
                }
            }
            else if let xAxis = config.xAxis, !xAxis.name.isEmpty,
                    let yAxis = config.yAxis, !yAxis.name.isEmpty {
                let xDim = meta.parameter(named: xAxis.name)
                let yDim = meta.parameter(named: yAxis.name)
                
                if xDim == nil {        errorMessage = "X axis dimension not in dataset"  }
               else if yDim == nil {    errorMessage = "Y axis dimension not in dataset"  }
               else {
                    print("Creating chart for \(population.name)")
                    chartQuery = .histogram2D(core.histogram2D(
                        HistogramRequest(population, .init(xAxis.name, yAxis.name), chartDef: config)))
                    chartDims = .init(xDim, yDim)
                }
            }
            else {
                errorMessage = "Unsupported chart configuration"
            }
                    
            
            
            
        }
    }
}

extension View {
//    var population: PopulationRequest { get }
//    var chartDef: Binding<ChartDef> { get }
    @MainActor
    func updateSampleQuery(_ core:CytegeistCoreAPI, _ population:PopulationRequest, query:Binding<APIQuery<FCSFile>?>) -> some View {
        self.onChange(of: population.getSample(), initial: true) {
            query.wrappedValue?.dispose()
            query.wrappedValue = nil
            if let sample = population.getSample() {
                let r = SampleRequest(sample, includeData: false)
                query.wrappedValue = core.loadSample(r)
            }
        }
    }
    
    
}

//extension View {
//    func updateSampleQuery
//}

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
