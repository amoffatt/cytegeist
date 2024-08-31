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

public struct ChartAnnotation : Identifiable, Hashable {
    public static func == (lhs: ChartAnnotation, rhs: ChartAnnotation) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public let id:String
    public let name:String
    public let view:(CGSize, Bool) -> any View
    public let remove:Action?
}

protocol GateHandle : View {
}

struct CircleHandle: GateHandle {
    @Environment(\.gateColor) var color
    @Environment(\.controlState) var state
    
    
    let solid:Bool
    public init(solid: Bool = false) {
        self.solid = solid
    }
    
    var body: some View {
        let solidColor = color.opacity(state.hovered ? 1.0 : 0.7)
        ZStack {
            if solid {
                Circle()
                    .fill(solidColor)
            }
            else {
                Circle()
                    .fill(color.opacity(state.hovered ? 0.6 : 0.3))
                    .stroke(solidColor, lineWidth: state.pressed ? 3 : 2)
            }
        }
    }
}

extension GateHandle {
}

struct EmptyHandle: GateHandle {
    var body: some View {
        EmptyView()
    }
}


typealias ControlState = (hovered:Bool, pressed:Bool)

struct GateControlZone<Content, Handle> : View, Identifiable where Content:View, Handle:View {
    @Environment(\.handleSize) var size
    @Environment(\.controlSize) var controlSize
    @Environment(\.isEditing) var editing

    let id: String
//    let color:Color
//    let solid:Bool
//    let scale:ControlSize = .regular
    let content: (((ControlState) -> Content))
    let handle: ((ControlState) -> Handle)?
    let move:(CGPoint) -> Void
    
    @State var isHovered:Bool = false
    @State var isPressed:Bool = false
    
    init(id: String,
         content: @escaping ((ControlState) -> Content),
         handle: @escaping ((ControlState) -> Handle),
         move: @escaping (CGPoint) -> Void) {
        self.id = id
        self.content = content
        self.handle = handle
        self.move = move
    }
    
    var body: some View {
        let state = (isHovered, isPressed)
        
        ZStack(alignment: .topLeading) {
            content(state)
            
            if editing, let handle {
                let size = (size * controlSize.scaling) * (isHovered ? 1.15 : 1) * (isPressed ? 0.8 : 1)
                handle(state)
                    .frame(width:size, height: size)
            }
        }
        .transition(.opacity)
        .environment(\.controlState, state)
        .id(id)
        
        // If in edit mode, apply interation modifiers
        .if(editing) { view in
            view
                .onHover { hovering in
                    if !editing { return }
                    
                    withAnimation(.spring) {
                        isHovered = hovering
                    }
                }
                .gesture(
                    editing
                    ? DragGesture()
                        .onChanged { drag in
                            if !editing { return }
                            
                            let p = drag.location
                            move(p)
                        }
                        .onEnded { drag in }
                    : nil
                )
                .onPress { pressed in
                    if !editing { return }
                    
                    withAnimation(.bouncy) {
                        isPressed = pressed
                    }
                }
        }
    }
}


struct RangeGateView : View {
    @Environment(\.lineWidth) var lineWidth
    @Environment(\.isEditing) var editing
//    @Environment(\.backgroundStyle) var style
    @Binding var gate:RangeGateDef?
    let normalizer:AxisNormalizer
    let chartSize:CGSize
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
                
                GateControlZone(id:"main-area") { state in
                    Rectangle()
                        .fill(color.opacity(opacity))
                        .position(x: viewMin, y: 0)
                        .offset(x: viewWidth / 2, y:chartCenter.height)
                        .frame(width: viewWidth,  height: chartSize.height, alignment: .topLeading)
                } handle: { state in
                    CircleHandle(solid:true)
                        .position(x:viewCenter, y:chartCenter.height)
                    
                } move: { p in
                    var gate = gate
                    gate.min = normalizer.unnormalize((p.x - viewWidth / 2) / chartSize.width)
                    gate.max = normalizer.unnormalize((p.x + viewWidth / 2)  / chartSize.width)
                    $gate.wrappedValue = gate
                }
                
                edgeControlZone("min-edge", x: viewMin) { p in
                    $gate.wrappedValue?.min = normalizer.unnormalize(p.x / chartSize.width)
                }
                edgeControlZone("max-edge", x: viewMax) { p in
                    $gate.wrappedValue?.max = normalizer.unnormalize(p.x / chartSize.width)
                }
            }
        }
        .environment(\.isEditing, editing)
        .animation(.smooth, value:editing)
    }
    
    func edgeControlZone(_ id:String, x:Double, move:@escaping (CGPoint) -> Void) -> some View {
        GateControlZone(id:id) { state in
            Rectangle()
                .fill(color.opacity(0.8))
                .position(x: x, y: 0)
                .offset(y: chartSize.height / 2)
                .frame(width: lineWidth, height: chartSize.height, alignment: .topLeading)
        } handle: { state in
            CircleHandle()
                .position(x: x, y: chartSize.height / 2)
            
        } move: { move($0) }
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

struct GateColorEnvironmentKey: EnvironmentKey {
    static let defaultValue = Color.green
}

public extension EnvironmentValues {
    var gateColor: Color {
        get { self[GateColorEnvironmentKey.self] }
        set { self[GateColorEnvironmentKey.self] = newValue }
    }
}
struct ControlStateEnvironmentKey: EnvironmentKey {
    static let defaultValue:ControlState = (false, false)
}

public extension EnvironmentValues {
    internal var controlState: ControlState {
        get { self[ControlStateEnvironmentKey.self] }
        set { self[ControlStateEnvironmentKey.self] = newValue }
    }
}

struct IsEditingEnvironmentKey: EnvironmentKey {
    static let defaultValue:Bool = false
}

public extension EnvironmentValues {
    var isEditing: Bool {
        get { self[IsEditingEnvironmentKey.self] }
        set { self[IsEditingEnvironmentKey.self] = newValue }
    }
}
