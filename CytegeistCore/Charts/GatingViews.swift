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

struct GateHandle : View {
    @Environment(\.handleSize) var size
    @Environment(\.controlSize) var controlSize
    
    let color:Color
    let solid:Bool
    let scale:ControlSize
    
    var body: some View {
        let size = size * controlSize.scaling
        
        ZStack {
            if solid {
                Circle()
                    .fill(color)
            }
            else {
                Circle()
                    .stroke(color, lineWidth: 2)
            }
        }
        
        .frame(width:size, height: size)
    }
}


struct RangeGateView : View {
    @Environment(\.lineWidth) var lineWidth
//    @Environment(\.backgroundStyle) var style
    let gate:RangeGateDef
    @State var isDragging:Bool = false
    let normalizer:AxisNormalizer
    let chartSize:CGSize
//    let fillOpacity
//    @Binding var editing:Bool
    
    var body: some View {
        let (min, max) = sort(gate.min, gate.max)
        let viewMin = normalizer.normalize(min) * chartSize.width
        let viewMax = normalizer.normalize(max) * chartSize.width
        let viewWidth = viewMax - viewMin
        
        return ZStack {
            Rectangle()
                .fill(.green.opacity(0.2))
//                .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
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
        let rect = gate.rect
            .normalize(normalizers)
            .invertedY(maxY: 1)
            .scaled(chartSize)
//        let viewMin = normalizer.normalize(min) * chartSize.width
//        let viewMax = normalizer.normalize(max) * chartSize.width
        let size = rect.size
        
        return ZStack {
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
                                .fill(.green.opacity(0.2))
                .foregroundColor(.green)
                .opacity(isDragging ? 0.8 : 0.5)
                .position(rect.min)
                .offset(size / 2.0)
                .frame(width: size.width,  height: size.width, alignment: Alignment.topLeading)
                .allowsHitTesting(false)
        }
    }
}


struct LineWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

public extension EnvironmentValues {
    var lineWidth: Double {
        get { self[LineWidthEnvironmentKey.self] }
        set { self[LineWidthEnvironmentKey.self] = newValue }
    }
}

struct HandleSizeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 20
}

public extension EnvironmentValues {
    var handleSize: Double {
        get { self[HandleSizeEnvironmentKey.self] }
        set { self[HandleSizeEnvironmentKey.self] = newValue }
    }
}
