//
//  ThreeDChart.swift
//  CytegeistApp
//
//  Created by Aaron Moffatt on 9/19/24.
//
#if os(visionOS)

import SwiftUI
import RealityKit
import RealityKitContent
import CytegeistLibrary


extension APIQuery<SampledPopulationData> : ChartDataQuery {}

class Chart3DStateData : ChartStateData<APIQuery<SampledPopulationData>> {
    static let axisKeys:[KeyPath<ChartDef, AxisDef?>] = [\.xAxis, \.yAxis, \.zAxis, \.sizeAxis, \.colorAxis]
//    var chartDims: Tuple3<CDimension?> = .init(nil, nil, nil)

    override func updateChartQuery(_ core: CytegeistCoreAPI, _ config: ChartDef, _ meta: FCSMetadata, _ population: AnalysisNode, _ populationRequest: PopulationRequest) {
        var dims = [CDimension?](repeating:nil, count:Self.axisKeys.count)
        
        for (i, keyPath) in Self.axisKeys.enumerated() {
            if let axis = config[keyPath: keyPath], !axis.dim.isEmpty {
                dims[i] = meta.parameter(named: axis.dim)
            }
        }
        
//        chartDims = .init(dims[0], dims[1], dims[2])
        
//        print("Creating chart for \(population.name)")
        chartQuery = core.sampledPopulationData(
            SampledPopulationRequest(populationRequest, dims.map { $0?.name ?? "" }, 500, PValue(0.8)))

    }
}

public typealias AxisAttachmentInfo = (id:String, axisName:String, keyPath:WritableKeyPath<ChartDef, AxisDef?>, position:SIMD3<Float>, right:SIMD3<Float>)

@MainActor
public struct Chart3DView: View {
    public static let VolumeSize = Size3D(width:1, height:1, depth:1)
    public static let ChartScale:Float = 0.85
    
    public static let volumePadding:SIMD3<Float> = .one * 0.5
    public static let axisAttachments:[AxisAttachmentInfo] = [
        ("xAxis", "x", \.xAxis, [0.0, -0.5, 0.5], [1, 0, 0]),
        ("yAxis", "y", \.yAxis, [-0.5, 0.0, 0.5], [0, -1, 0]),
        ("zAxis", "z", \.zAxis, [-0.5, -0.5, 0.0], [0, 0, 1])
    ]

    @Environment(CytegeistCoreAPI.self) var core: CytegeistCoreAPI

//    let chartDef: 
//    var config: Binding<ChartDef>
//    let dataPoints:[SIMD3<Float>]
    
    // start with default data points
    // add 3D cube
    // add axes, with selector dropdowns
    // add panel to select size and color axes
    
    
    @State var state:Chart3DStateData
    
    @State var chartEntity: ScatterChart3DEntity! = nil
    
    public init(_ population:AnalysisNode?, _ def:Binding<ChartDef?>) {//, dataPoints:[SIMD3<Float>]) {
        self.state = .init(population, def)
//        self.dataPoints = dataPoints
    }


    public var body: some View {
        let data = state.chartQuery?.data
        let sampleMeta = data?.allEvents.meta
        
        GeometryReader3D { proxy in
            Print("View size: \(proxy.size)")
            let chartSize = proxy.size.width
            
            ZStack(alignment: .top) {
                RealityView { content, attachments in
                    // Create the chart entity
                    
                    chartEntity = ScatterChart3DEntity()
                    chartEntity.scale = .one * Self.ChartScale
                    
                    //            chartEntity.setDataPoints(dataPoints)
                    
                    // Add the chart entity to the content
                    content.add(chartEntity)
                    
                    // Add AxisView attachments
                    for axis in Self.axisAttachments {
                        if let view = attachments.entity(for: axis.id) {
                            
//                            let height = Float(ChartAxisView.height(of: axisDef(axis)))
                            let height = Float(0.05)    // Guess for now
                            
                            
                            // Compute orientation to align along specified axis and face outward
                            let up = simd_normalize(-axis.position) // Point outward from center
                            let right = simd_normalize(axis.right)
                            let forward = simd_cross(right, up)
                            let rotationMatrix = simd_float3x3(columns: (right, up, forward))
                            view.orientation = simd_quaternion(rotationMatrix)
                            view.position = axis.position - up * height * 0.5

                            chartEntity.addChild(view)
                        }
                    }
                    
                } update: { content, attachments in
                    //            await chartEntity.setDataPoints(dataPoints)
                    
                } attachments: {
                    ForEach(Self.axisAttachments, id: \.id) { axis in
                        Attachment(id: axis.id) {
                            VStack {
                                let def = axisDef(axis)
                                ChartAxisView(
                                    def:def,
                                    normalizer: sampleMeta?.parameter(named: def?.dim)?.normalizer,
                                    sampleMeta: sampleMeta,
                                    width: chartSize,
                                    immersive: true) { updatedAxis in
                                        self.updateAxisDef(axis, updatedAxis)
                                    }
                                //                            Text("\(axis.axisName) axis")
                            }
                            .frame(width: chartSize)
//                            .background(.blue.opacity(0.5))
//                            .glassBackgroundEffect()
                        }
                    }
                }
                .updateChartQuery(core, state: state)
                .onChange(of: data, initial: true) {
                    let chartData = getChartData()
                    chartEntity?.setDataPoints((chartData, .jet))
                }
                
                VStack {
                    Text(state.population?.fullDisplayName() ?? "<No Population Selected>")
                        .padding()
                        .font(.title3)
                        .glassBackgroundEffect()
                }
            }
        }
    }
    
    func axisDef(_ axis:AxisAttachmentInfo) -> AxisDef? {
        state.def.wrappedValue?[keyPath: axis.keyPath]
    }
    
    func getChartData() -> SampledPopulationData? {
        if let chartDef = state.def.wrappedValue,
           let data = state.chartQuery?.data {
            
            // Data with dimensions mapped based on the ChartDef
            let filteredData = data.allEvents.filter(dimensions:[
                chartDef.xAxis?.dim,
                chartDef.yAxis?.dim,
                chartDef.zAxis?.dim,
                chartDef.sizeAxis?.dim,
                chartDef.colorAxis?.dim,
            ])
            
            return SampledPopulationData(allEvents: filteredData, eventIndices: data.eventIndices)
        }
        return nil
    }
    
    func updateAxisDef(_ axis:AxisAttachmentInfo, _ axisDef:AxisDef) {
        state.def.wrappedValue?[keyPath: axis.keyPath] = axisDef
    }
}

public struct Chart3DViewTest: View {
    public init() {}
    
    public var body: some View {
        let sample = Sample(ref: SampleRef(url:DemoData.facsDivaSample0!))
        let population = AnalysisNode(sample: sample)
//        let population:PopulationRequest = .sample(.init(url:sample))
        var chart:ChartDef? = .init()
        chart?.xAxis = .init(dim:"FSC-A")
        chart?.yAxis = .init(dim:"SSC-A")
        let chartBinding = readOnlyBinding(chart)
        
        return ZStack {
            Chart3DView(population, chartBinding)
//                                  , dataPoints: [
//                SIMD3(0.1, 0.2, 0.3),
//                SIMD3(0.4, 0.5, 0.6),
//                SIMD3(0.7, 0.8, 0.9),
//                SIMD3(0.2, 0.4, 0.6),
//                SIMD3(0.5, 0.7, 0.9),
//                SIMD3(0.3, 0.6, 0.9),
//                SIMD3(0.1, 0.5, 0.9),
//                SIMD3(0.8, 0.6, 0.4),
//                SIMD3(0.2, 0.7, 0.3),
//                SIMD3(0.9, 0.1, 0.5),
//                SIMD3(0.4, 0.8, 0.2),
//                SIMD3(0.6, 0.3, 0.7),
//                SIMD3(0.1, 0.9, 0.5),
//                SIMD3(0.7, 0.2, 0.8),
//                SIMD3(0.3, 0.8, 0.1),
//                SIMD3(0.5, 0.2, 0.9),
//                SIMD3(0.8, 0.4, 0.1),
//                SIMD3(0.2, 0.9, 0.6),
//                SIMD3(0.6, 0.1, 0.7),
//                SIMD3(0.9, 0.5, 0.3),
//                SIMD3(0.4, 0.7, 0.1),
//                SIMD3(0.7, 0.3, 0.5),
//                SIMD3(0.1, 0.6, 0.2),
//                SIMD3(0.8, 0.2, 0.7),
//                SIMD3(0.3, 0.9, 0.4),
//                SIMD3(0.5, 0.1, 0.8),
//                SIMD3(0.9, 0.7, 0.2),
//                SIMD3(0.2, 0.5, 0.1),
//                SIMD3(0.6, 0.8, 0.3),
//                SIMD3(0.4, 0.3, 0.9)
//            ])
//            VStack {
//                Text("3D Chart Test")
//            }
//            .padding()
//            .glassBackgroundEffect()
        }
    }
}

#Preview {
    Chart3DViewTest()
}


#endif
