//
//  GatingViews.swift
//  CytegeistCore
//
//  Created by Adam Treister on 8/29/24.
//

import Foundation
import SwiftUI
import CytegeistLibrary



//public protocol ChartViewable {
//    func chartView(chart:ChartDef) -> AnnotationView?
//}

public struct ChartAnnotation : Identifiable {
    public let id:String
    public let view:(FCSMetadata, CGSize) -> any View
}

public struct AnnotationView : View, Identifiable {
//    public let editing:Bool = false
//    public let annotation: () -> Text
//    public let position:CGPoint
//    public let color:Color
//    public let chartGeometry:GeometryProxy
    public let id: String
//    @Binding var editing
    
    public let content:() -> any View

    public var body: some View {
        AnyView {
            content()
//            content(editing, chartGeometry)
//                .foregroundColor(color)
            // represent inversion
        }
    }
}


struct RangeGateView : View {
    let gate:RangeGateDef
    @State var isDragging:Bool = false
    let normalizer:AxisNormalizer
    let chartSize:CGSize
//    @Binding var editing:Bool
    
    var body: some View {
        let (min, max) = sort(gate.min, gate.max)
        let viewMin = normalizer.normalize(min) * chartSize.width
        let viewMax = normalizer.normalize(max) * chartSize.width
        let viewWidth = viewMax - viewMin
        
        return ZStack {
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
//                .fill(.green.opacity(0.2))
                .foregroundColor(.green)
                .opacity(isDragging ? 0.8 : 0.5)
                .position(x: viewMin, y: 0)
                .offset(x: viewWidth / 2, y: chartSize.height / 2 )
                .frame(width: viewWidth,  height: chartSize.height, alignment: Alignment.topLeading)
                .allowsHitTesting(false)
        }
    }
}


struct RectGateView : View {
    let gate:RectGateDef
    @State var isDragging:Bool = false
    let normalizers:Tuple2<AxisNormalizer>
    let chartSize:CGSize
        //    @Binding var editing:Bool
    
    var body: some View {
        let viewMin = gate.min.normalize(normalizers) * chartSize
        let viewMax = gate.max.normalize(normalizers) * chartSize
//        let viewMin = normalizer.normalize(min) * chartSize.width
//        let viewMax = normalizer.normalize(max) * chartSize.width
        let viewSize = viewMax - viewMin
        
        return ZStack {
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
                //                .fill(.green.opacity(0.2))
                .foregroundColor(.green)
                .opacity(isDragging ? 0.8 : 0.5)
                .position(viewMin)
                .offset(viewSize / 2)
                .frame(width: viewSize.width,  height: viewSize.height, alignment: Alignment.topLeading)
                .allowsHitTesting(false)
        }
    }
}
