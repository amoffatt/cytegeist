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
    @Environment(BatchContext.self) var batchContext
    
    let population: AnalysisNode?
    let config: Binding<ChartDef?>
    let editable:Bool
    let _chartOverlay:(CGSize) -> Overlay
    
    let focusedItem:Binding<ChartAnnotation?>?
    
    
    @State var sampleQuery: APIQuery<FCSFile>? = nil
    @State fileprivate var chartQuery: ChartDataRequest? = nil
    @State var chartDims: Tuple2<CDimension?> = .init(nil, nil)
    @State var errorMessage:String = ""
    @State var chartSize:CGSize = CGSize(1)
    
    
    public init(population: AnalysisNode?, config:Binding<ChartDef?>, editable:Bool = true, focusedItem:Binding<ChartAnnotation?>?, overlay:@escaping (CGSize) -> Overlay = { _ in EmptyView() }){
        self.population = population
        self.config = config
        self.editable = editable
        self.focusedItem = focusedItem
        self._chartOverlay = overlay
    }
    
//    public init(population: AnalysisNode, overlay:@escaping (CGSize) -> Overlay = { _ in EmptyView() }){
//        self.init(population:  population, config: population.graphDef,editable: false, overlay: overlay)
//    }

    @MainActor
    func axisBinding(_ chartDef:Binding<ChartDef?>, _ axis:WritableKeyPath<ChartDef, AxisDef?>) -> Binding<String> {
        Binding(get: {
            let axisDef = chartDef.wrappedValue?[keyPath:axis]
            return axisDef?.dim ?? ""
        }, set: {
            var value = chartDef.wrappedValue
            value?[keyPath:axis] = AxisDef(dim: $0)
            chartDef.wrappedValue = value
        })
    }
//    struct ErrorText : Text
//    {
//        var body : some View {
//        if !errorMessage.isEmpty {Text("\(errorMessage)").foregroundColor(.red)
//        }
//    }
    public var body: some View {
        let sampleMeta = sampleQuery?.data?.meta
        let def = config.wrappedValue
        
        VStack {
            if !errorMessage.isEmpty {
                Text("\(errorMessage)")
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    ZStack {
                        GeometryReader { proxy in
                            VStack {
                                switch chartQuery {
                                    case nil:                          VStack {}
                                            .fillAvailableSpace()
                                    case .histogram1D(let query):      HistogramView(query: query)
                                            .border(.black)
                                            .background(.white)
                                            .overlay(chartOverlay)
                                            .fillAvailableSpace()
                                    case .histogram2D(let query):      Histogram2DView(query: query)
                                            .border(.black)
                                            .background(.white)
                                            .overlay(chartOverlay)
                                            .fillAvailableSpace()
                                }
                            }
                            .onChange(of: proxy.size, initial: true) {
                                chartSize = proxy.size
                            }
                        }
                    }
                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                    .environment(\.annotationScale, min(1, min(chartSize.width, chartSize.height) / 700))
                    
                    let yAxis = def?.yAxis
                    let axisWidth = chartSize.height
                    let axisHeight = ChartAxisView.height(of: yAxis)
                    ZStack(alignment: .topLeading) {
                        ChartAxisView(def: yAxis, normalizer: chartDims.y?.normalizer,
                                      sampleMeta: sampleMeta,
                                      width: axisWidth,
                                      update: editable ? { config.wrappedValue?.yAxis = $0 } : nil)
                            .rotationEffect(.degrees(-90), anchor: .center)
                    }
                    .frame(width: axisHeight, height: axisWidth)
                    .frame(minHeight: 10)        // Avoid conflicts with the GeometryReader preventing resizing
                }
                
                ChartAxisView(def: def?.xAxis, normalizer: chartDims.x?.normalizer,
                                  sampleMeta: sampleMeta,
                                  width: chartSize.width,
                              update: editable ? {
                    config.wrappedValue?.xAxis = $0
                } : nil)
                        .frame(minWidth: 10)        // Avoid conflicts with the GeometryReader preventing resizing
            }
            .fillAvailableSpace()
        }
        .updateSampleQuery(core, batchContext, population, query: $sampleQuery)
        
        .onChange(of: population, initial: true, updateChartQuery)
        .onChange(of: config.wrappedValue, updateChartQuery)
        .onChange(of: sampleQuery?.data?.meta, updateChartQuery)
    }
    
//    @ViewBuilder
    private var chartOverlay: some View {
        VStack {
            GeometryReader { proxy in
                let size = proxy.size
                ZStack(alignment:.topLeading) {
                    _chartOverlay(size)
                    if let population, let chartDef = config.wrappedValue {
                        ForEach(population.visibleChildren(batchContext, chartDef), id:\.self) { child in
                            let editing = child == focusedItem?.wrappedValue
                            AnyView(child.view(size, editing))
                                .environment(\.isEditing, editing)
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded {
                                            focusedItem?.wrappedValue = child
                                        }
                                    )
                        }
                    }
                }
            }
        }
        .fillAvailableSpace()
    }
    
//    var stateHash: Int {
//        var stateHash = Hasher()
//        stateHash.combine(sampleRef)
//        stateHash.combine(population)
//        stateHash.combine(config)
//        return stateHash.finalize()
//    }
    
    @MainActor func getPopulationRequest() -> (PopulationRequest?, error:String?) {
        guard let population else {
            return (nil, "No population")
        }
        do {
            return (try population.createRequest(batchContext), nil)
        } catch {
            return (nil, "Error creating chart: \(error)")
        }
    }
    
            
    @MainActor func updateChartQuery()  {
        chartQuery?.dispose()
//        chartQuery = nil
        errorMessage = ""
        let config = self.config.wrappedValue
        
        guard let config, let population else {   return   }
        
          if let meta = sampleQuery?.data?.meta {
            let (populationRequest, error) = getPopulationRequest()
            guard let populationRequest else {
                errorMessage = error.nonNil
                return
            }
            
            if isEmpty(config.yAxis?.dim),
               let axis = config.xAxis, !axis.dim.isEmpty {
                
                if let dim = meta.parameter(named: axis.dim) {
                    chartQuery = .histogram1D(core.histogram(.init(populationRequest, .init(axis.dim), chartDef: config)))
                    chartDims = .init(dim, nil)
                } else {
                    errorMessage = "X axis dimension not in dataset"
                }
            }
            else if let xAxis = config.xAxis, !xAxis.dim.isEmpty,
                    let yAxis = config.yAxis, !yAxis.dim.isEmpty {
                let xDim = meta.parameter(named: xAxis.dim)
                let yDim = meta.parameter(named: yAxis.dim)
                
                if xDim == nil {        errorMessage = "X axis dimension not in dataset"  }
               else if yDim == nil {    errorMessage = "Y axis dimension not in dataset"  }
               else {
                    print("Creating chart for \(population.name)")
                    chartQuery = .histogram2D(core.histogram2D(
                        HistogramRequest(populationRequest, .init(xAxis.dim, yAxis.dim), chartDef: config)))
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
    func updateSampleQuery(_ core:CytegeistCoreAPI, _ batchContext:BatchContext, _ population:AnalysisNode?, query:Binding<APIQuery<FCSFile>?>) -> some View {
        let sampleRef = population?.getSample(batchContext)?.ref
        return self.onChange(of: sampleRef, initial: true) {
            query.wrappedValue?.dispose()
            query.wrappedValue = nil
            if let sampleRef {
                let r = SampleRequest(sampleRef, includeData: false)
                query.wrappedValue = core.loadSample(r)
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
