//
//  ChartView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI
import CytegeistLibrary

protocol ChartDataQuery {
    func dispose()
}

fileprivate enum ChartViewDataQuery : ChartDataQuery {
    
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

@Observable
class ChartStateData<Query:ChartDataQuery> {
    
//    let population: AnalysisNode?
//    let def: Binding<ChartDef?>
    
    var sampleQuery: APIQuery<PopulationData>? = nil
    var chartQuery: Query? = nil
    var errorMessage:String = ""

//    init(_ population:AnalysisNode?, _ def:Binding<ChartDef?>) {
//        self.population = population
//        self.def = def
//    }
    
    @MainActor
    func getPopulationRequest(_ population:AnalysisNode) -> (PopulationRequest?, error:String?) {
//        guard let population else {
//            return (nil, "No population")
//        }
        do {
            return (try population.createRequest(), nil)
        } catch {
            return (nil, "Error creating chart: \(error)")
        }
    }
    
    
    @MainActor
    func updateChartQuery(_ core:CytegeistCoreAPI, _ config:ChartConfig)  {
        chartQuery?.dispose()
        //        chartQuery = nil
        errorMessage = ""
        
        guard let def = config.def.wrappedValue, let population = config.population else {   return   }
        
        if let meta = sampleQuery?.data?.meta {
            let (populationRequest, error) = getPopulationRequest(population)
            guard let populationRequest else {
                errorMessage = error.nonNil
                return
            }
            
            updateChartQuery(core, def, meta, population, populationRequest)
        }
    }
    
    @MainActor
    func updateChartQuery(_ core:CytegeistCoreAPI, _ config:ChartDef, _ meta:FCSMetadata, _ population:AnalysisNode, _ populationRequest:PopulationRequest) {
        fatalError()
    }

}

fileprivate class ChartViewStateData : ChartStateData<ChartViewDataQuery> {
    var chartDims: Tuple2<CDimension?> = .init(nil, nil)
    
    override func updateChartQuery(_ core:CytegeistCoreAPI, _ config:ChartDef, _ meta:FCSMetadata, _ population:AnalysisNode, _ populationRequest:PopulationRequest) {
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


public struct ChartConfig {
    public var population:AnalysisNode?
    public var def:Binding<ChartDef?>
    
    public init(_ population: AnalysisNode?, _ def: Binding<ChartDef?>) {
        self.population = population
        self.def = def
    }
}


public struct ChartView<Overlay>: View where Overlay:View {
    @Environment(CytegeistCoreAPI.self) var core: CytegeistCoreAPI
    
    @State private var state: ChartViewStateData
    let config: ChartConfig
    let editable:Bool
    let _chartOverlay:(CGSize) -> Overlay
    
    @State var chartSize:CGSize = CGSize(1)
    
    
    public init(population: AnalysisNode?, def:Binding<ChartDef?>, editable:Bool = true, overlay:@escaping (CGSize) -> Overlay = { _ in EmptyView() }){
        self.config = ChartConfig(population, def)
        self.state = ChartViewStateData()
        self.editable = editable
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
        let sampleMeta = state.sampleQuery?.data?.meta
        let def = config.def.wrappedValue
        
        VStack {
            if !state.errorMessage.isEmpty {
                Text("\(state.errorMessage)")
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    ZStack {
                        GeometryReader { proxy in
                            VStack {
                                switch state.chartQuery {
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
                        ChartAxisView(def: yAxis, normalizer: state.chartDims.y?.normalizer,
                                      sampleMeta: sampleMeta,
                                      width: axisWidth,
                                      update: editable ? { config.def.wrappedValue?.yAxis = $0 } : nil)
                            .rotationEffect(.degrees(-90), anchor: .center)
                    }
                    .frame(width: axisHeight, height: axisWidth)
                    .frame(minHeight: 10)        // Avoid conflicts with the GeometryReader preventing resizing
                }
                
                ChartAxisView(def: def?.xAxis, normalizer: state.chartDims.x?.normalizer,
                              sampleMeta: sampleMeta,
                              width: chartSize.width,
                              update: editable ? { config.def.wrappedValue?.xAxis = $0 } : nil)
                        .frame(minWidth: 10)        // Avoid conflicts with the GeometryReader preventing resizing
            }
            .fillAvailableSpace()
        }
    }
    
//    @ViewBuilder
    private var chartOverlay: some View {
        VStack {
            GeometryReader { proxy in
                let size = proxy.size
                ZStack(alignment:.topLeading) {
                    if let population = config.population, let chartDef = config.def.wrappedValue {
                        ForEach(population.visibleChildren(chartDef), id:\.self) { child in
                            // AM DEBUGGING
                            let editing = false //child == focusedItem
                            AnyView(child.view(size, editing))
                                .environment(\.isEditing, editing)
                                .onTapGesture {}       //    focusedItem = child
                        }
                    }
                    _chartOverlay(size)
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
    
}

extension View {
//    var population: PopulationRequest { get }
//    var chartDef: Binding<ChartDef> { get }
//    @MainActor
//    func updateSampleQuery(_ core:CytegeistCoreAPI, _ population:AnalysisNode?, query:Binding<APIQuery<FCSFile>?>) -> some View {
//    }
    
    
    @MainActor
    func updateChartQuery<T>(_ core:CytegeistCoreAPI, _ config: ChartConfig, state:ChartStateData<T>) -> some View {
        let sampleRef = config.population?.getSample()?.ref
        
        return self
            .onChange(of: config.population, initial: true, { state.updateChartQuery(core, config) })
            .onChange(of: config.def.wrappedValue, { state.updateChartQuery(core, config) })
            .onChange(of: state.sampleQuery?.data?.meta, { state.updateChartQuery(core, config) })
            
            .onChange(of: sampleRef, initial: true) {
                state.sampleQuery?.dispose()
                state.sampleQuery = nil
                if let sampleRef {
                    let r = SampleRequest(sampleRef, includeData: false)
                    state.sampleQuery = core.loadSample(r)
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
