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

@MainActor
public struct RealityKitChart3DView: View {
    
    public static let volumePadding:SIMD3<Float> = .one * 0.5
    public static let axisAttachments:[(id:String, axisName:String, position:SIMD3<Float>)] = [
        ("xAxis", "x", [0.0, -0.5, 0.5]),
        ("yAxis", "y", [-0.5, 0.0, 0.5]),
        ("zAxis", "z", [-0.5, -0.5, 0.0])
    ]

    @Environment(CytegeistCoreAPI.self) var core: CytegeistCoreAPI

    let population: AnalysisNode
//    let chartDef: 
//    var config: Binding<ChartDef>
    let dataPoints:[SIMD3<Float>]
    
    // start with default data points
    // add 3D cube
    // add axes, with selector dropdowns
    // add panel to select size and color axes
    
    
    @State var sampleQuery: APIQuery<FCSFile>? = nil
    @State var dataQuery: APIQuery<EventDataTable>? = nil
    
    @State var chartEntity: ScatterChart3DEntity! = nil


    public var body: some View {
        RealityView { content, attachments in
            // Create the chart entity
            
            chartEntity = ScatterChart3DEntity()
            
            chartEntity.setDataPoints(dataPoints)
            
            // Add the chart entity to the content
            content.add(chartEntity)
            
            // Add AxisView attachments
            for attachment in Self.axisAttachments {
                if let view = attachments.entity(for: attachment.id) {
                    view.position = attachment.position
                    chartEntity.addChild(view)
                }
            }
            
        } update: { content, attachments in
//            await chartEntity.setDataPoints(dataPoints)

        } attachments: {
            ForEach(Self.axisAttachments, id: \.id) { attachment in
                Attachment(id: attachment.id) {
                    ChartAxisView()
                        .padding()
                        .glassBackgroundEffect()
                }
            }
        }
        .frame(width: 500, height: 500)
        .updateSampleQuery(core, population, query: $sampleQuery)
        
        .onChange(of: population, initial: true, updateDataQuery)
//        .onChange(of: config.wrappedValue, updateDataQuery)
        .onChange(of: sampleQuery?.data?.meta, updateDataQuery)
        .onChange(of: dataPoints, initial: true) {
            chartEntity?.setDataPoints(dataPoints)
        }
    }
    
    
    func updateDataQuery() {
        
    }
}

public struct Chart3DViewTest: View {
    public init() {}
    
    public var body: some View {
        let sample = DemoData.facsDivaSample0!
        let population:PopulationRequest = .sample(.init(url:sample))
        
        return ZStack {
            RealityKitChart3DView(population: population, dataPoints: [
                SIMD3(0.1, 0.2, 0.3),
                SIMD3(0.4, 0.5, 0.6),
                SIMD3(0.7, 0.8, 0.9),
                SIMD3(0.2, 0.4, 0.6),
                SIMD3(0.5, 0.7, 0.9),
                SIMD3(0.3, 0.6, 0.9),
                SIMD3(0.1, 0.5, 0.9),
                SIMD3(0.8, 0.6, 0.4),
                SIMD3(0.2, 0.7, 0.3),
                SIMD3(0.9, 0.1, 0.5),
                SIMD3(0.4, 0.8, 0.2),
                SIMD3(0.6, 0.3, 0.7),
                SIMD3(0.1, 0.9, 0.5),
                SIMD3(0.7, 0.2, 0.8),
                SIMD3(0.3, 0.8, 0.1),
                SIMD3(0.5, 0.2, 0.9),
                SIMD3(0.8, 0.4, 0.1),
                SIMD3(0.2, 0.9, 0.6),
                SIMD3(0.6, 0.1, 0.7),
                SIMD3(0.9, 0.5, 0.3),
                SIMD3(0.4, 0.7, 0.1),
                SIMD3(0.7, 0.3, 0.5),
                SIMD3(0.1, 0.6, 0.2),
                SIMD3(0.8, 0.2, 0.7),
                SIMD3(0.3, 0.9, 0.4),
                SIMD3(0.5, 0.1, 0.8),
                SIMD3(0.9, 0.7, 0.2),
                SIMD3(0.2, 0.5, 0.1),
                SIMD3(0.6, 0.8, 0.3),
                SIMD3(0.4, 0.3, 0.9)
            ])
            VStack {
                Text("3D Chart Test")
            }
            .padding()
            .glassBackgroundEffect()
        }
    }
}

#Preview {
    Chart3DViewTest()
}


#endif
