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

public struct ChartAnnotation : Identifiable, Equatable {
    public static func == (lhs: ChartAnnotation, rhs: ChartAnnotation) -> Bool { lhs.id == rhs.id }
    public let id:String
    public let name:String
    public let view:(CGSize, Bool) -> any View
    public let remove:Action?
}


struct GateHandle : View, Identifiable {
    @Environment(\.handleSize) var size
    @Environment(\.controlSize) var controlSize
    
    let id: String
    let color:Color
    let solid:Bool
    let scale:ControlSize = .regular
    let position:CGPoint
    let move:(CGPoint) -> Void
    
    @State var isHovered:Bool = false
    @State var isPressed:Bool = false
    
    init(id: String, _ color: Color, _ position: CGPoint, solid: Bool = false, move: @escaping (CGPoint) -> Void) {
        self.id = id
        self.color = color
        self.position = position
        self.solid = solid
        self.move = move
        self.isHovered = isHovered
        self.isPressed = isPressed
    }
    
    var body: some View {
        let size = (size * controlSize.scaling) * (isHovered ? 1.15 : 1) * (isPressed ? 0.8 : 1)
        let p = position
        let color = color.opacity(isHovered ? 1 : 0.7)
        
        ZStack {
            if solid {
                Circle()
                    .fill(color)
            }
            else {
                Circle()
                    .fill(color.opacity(isHovered ? 0.6 : 0.3))
                    .stroke(color, lineWidth: isPressed ? 3 : 2)
            }
        }
        .id(id)

        .onHover { hovering in
            withAnimation(.spring) {
                isHovered = hovering
            }
        }

        .frame(width:size, height: size)
        .position(x: p.x, y: p.y)
        
        .gesture(
            DragGesture()
                .onChanged { drag in
                    let p = drag.location
                    move(p)
                }
                .onEnded { drag in }
        )
        .onPress { pressed in
            withAnimation(.bouncy) {
                isPressed = pressed
            }
        }
    }
}


struct RangeGateView : View {
    @Environment(\.lineWidth) var lineWidth
//    @Environment(\.backgroundStyle) var style
    @Binding var gate:RangeGateDef?
    let normalizer:AxisNormalizer
    let chartSize:CGSize
    let editing:Bool
    let color:Color = .green
    
    var body: some View {
        
        
        return ZStack(alignment: .topLeading) {
            if let gate {
                let (min, max) = sort(gate.min, gate.max)
                let viewMin = normalizer.normalize(min) * chartSize.width
                let viewMax = normalizer.normalize(max) * chartSize.width
                let viewWidth = viewMax - viewMin
                let viewCenter = viewMin + viewWidth / 2
                let chartCenter = chartSize / 2
                
                let opacity = (editing ? 1.5 : 1) * 0.3
                
                Rectangle()
                    .fill(color.opacity(opacity))
//                    .stroke(color.opacity(0.8), lineWidth: lineWidth)
                //                .opacity(isDragging ? 0.8 : 0.5)
                    .position(x: viewMin, y: 0)
                    .offset(x: viewWidth / 2, y:chartCenter.height)
                    .frame(width: viewWidth,  height: chartSize.height, alignment: .topLeading)
                
                ForEach([(0, viewMin), (1, viewMax)], id:\.0) { _, x in
                    Rectangle()
                        .fill(color.opacity(0.8))
                        .position(x: x, y: 0)
                        .offset(y: chartCenter.height)
                        .frame(width: lineWidth, height: chartSize.height, alignment: .topLeading)
                }

                if editing {
                    Group {
                        GateHandle(id:"center-handle", color, .init(viewCenter, chartCenter.height), solid: true) { p in
                            var gate = gate
                            gate.min = normalizer.unnormalize((p.x - viewWidth / 2) / chartSize.width)
                            gate.max = normalizer.unnormalize((p.x + viewWidth / 2)  / chartSize.width)
                            $gate.wrappedValue = gate
                        }
                        
                        GateHandle(id:"min-handle", color, .init(viewMin, chartCenter.height)) { p in
                            $gate.wrappedValue?.min = normalizer.unnormalize(p.x / chartSize.width)
                        }
                        
                        GateHandle(id:"max-handle",  color, .init(viewMax, chartCenter.height)) { p in
                            $gate.wrappedValue?.max = normalizer.unnormalize(p.x / chartSize.width)
                        }
                    }
                    .transition(.opacity)

                    
//                    fix()
                    // Crossing min/max
                    // Min/max becoming equal via center drag to edge
                    // Add delete support
                    // Add rect and ellipse gates
                }
            }
        }
        .animation(.smooth, value:editing)
//        .onChange(of: editing, initial: true) {
//            withAnimation { showEditor = editing }
//        }
    }
}

struct RectGateView : View {
    @Binding var gate:RectGateDef?
    @State var isDragging:Bool = false
    let normalizers:Tuple2<AxisNormalizer?>
    let chartSize:CGSize
        //    @Binding var editing:Bool
    
    var body: some View {
        
        return ZStack {
            if let gate {
                let rect = gate.rect
                    .normalize(normalizers)
                    .invertedY(maxY: 1)
                    .scaled(chartSize)
        //        let viewMin = normalizer.normalize(min) * chartSize.width
        //        let viewMax = normalizer.normalize(max) * chartSize.width
                let size = rect.size
                
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
                    .fill(.green.opacity(0.2))
                    .foregroundColor(.green)
                    .opacity(isDragging ? 0.8 : 0.5)
                    .position(rect.min)
                    .offset(size / 2.0)
                    .frame(width: size.width,  height: size.width, alignment: Alignment.topLeading)
                //                .allowsHitTesting(false)
                
                
            }
        }
    }
}


struct LineWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 2.0
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
