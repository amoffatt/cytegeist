//
//  GatingViews.swift
//  CytegeistCore
//
//  Created by Adam Treister on 8/29/24.
//

import Foundation
import SwiftUI
import CytegeistLibrary


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
    let position: CGPoint
    let content: (((ControlState) -> Content))
    let handle: ((ControlState) -> Handle)
    let move:(CGPoint) -> Void
    
    @State var dragStart:(zonePosition:CGPoint, pressPosition:CGPoint)?

    @State var isHovered:Bool = false
    @State var isPressed:Bool = false
    
    init(_ id: String,
         position: CGPoint,
         move: @escaping (CGPoint) -> Void,
         content: @escaping ((ControlState) -> Content),
         handle: @escaping ((ControlState) -> Handle) = { _ in EmptyView() }
    ) {
        self.id = id
        self.position = position
        self.content = content
        self.handle = handle
        self.move = move
    }
    
    var body: some View {
        let state = (isHovered, isPressed)
        
        ZStack() {
            content(state)

            if editing, Handle.self != EmptyView.self {
                let size = (size * controlSize.scaling) * (isHovered ? 1.15 : 1) * (isPressed ? 0.8 : 1)
                handle(state)
                    .frame(width:size, height: size)
            }
        }
        .position(position)
        .fixedSize()
        .transition(.opacity)
        .environment(\.controlState, state)
        .id(id)
        
        // If in edit mode, apply interation modifiers
        .if(editing) { view in
            view
                .onHover { hovering in
                    withAnimation(.spring) {
                        isHovered = hovering
                    }
                }
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { drag in
                            guard let dragStart else {
                                print("dragStart not set in gate handle \(id)")
                                return
                            }
                            let delta = drag.location - dragStart.pressPosition
                            let p = dragStart.zonePosition + delta
                            move(p)
                        }
                        .onEnded { drag in
                            dragStart = nil
                        }
                )
                .onPress { pressed, pressPosition in
                    dragStart = (position, pressPosition)
                    withAnimation(.bouncy) {
                        isPressed = pressed
                    }
                }
        }
    }
}

struct GateView<GateType:GateDef> : View where GateType:ViewableGate {
    @Environment(\.lineWidth) var lineWidth
    @Environment(\.isEditing) var editing
    @Bindable var node: PopulationNode
    let normalizers:Tuple2<AxisNormalizer?>
    let chartSize:CGSize
    
    var gate:Binding<GateType?> {
        castBinding($node.gate)
    }
    
    public init(node: PopulationNode, axes: Tuple2<AxisNormalizer?>, chartSize: CGSize) {
        self.node = node
        self.normalizers = axes
        self.chartSize = chartSize
    }
    
    var body: some View {
        
        return ZStack(alignment: .topLeading) {
            if let gate = gate.wrappedValue {
                var viewCenter:CGPoint = .zero
                if let content = gate.viewContent(self, viewCenter: &viewCenter) {
                    AnyView(content)
                }
                
                let labelPosition = viewCenter + node.labelOffset * chartSize
                GateControlZone("label", position: labelPosition) { p in
                    let offset = (p - viewCenter) / chartSize
                    node.labelOffset = offset
                } content: { state in
                    GateLabel(node:node)
                        .scaleEffect(.init(state.hovered ? 1.1 : 1))
                        .shadow(radius: state.hovered ? 5 : 0)
                }
            }
        }
        .environment(\.isEditing, editing)
        .animation(.smooth, value:editing)
    }
    
    func rectControlZone(_ id:String, center:CGPoint, width:Double, height:Double, opacity:Double? = nil, solid:Bool = false, move:@escaping (CGPoint) -> Void) -> some View {
        let opacity = opacity ?? node.opacity
        return GateControlZone(id, position: center, move: move) { state in
            Rectangle()
                .fill(node.color.opacity(opacity))
                .frame(width:width, height:height)
        } handle: { state in
            CircleHandle(solid:solid)
        }
    }

}



protocol ViewableGate: GateDef {
    associatedtype ViewType = GateView<Self>
    
    func chartView(_ node:PopulationNode, chartSize:CGSize, chartDims:Tuple2<CDimension?>) -> any View
    func viewContent(_ view:GateView<Self>, viewCenter: inout CGPoint) -> (any View)?
    func isValid(for chartDims: Tuple2<CDimension?>) -> Bool
}

extension ViewableGate {
    func chartView(_ node:PopulationNode, chartSize:CGSize, chartDims:Tuple2<CDimension?>) -> any View {
        let visibility = visibility(for:chartDims)
        precondition(visibility != .none)
        // TODO support .transposed
        
        return GateView<Self>(
            node: node,
            axes: chartDims.map { $0?.normalizer },
            chartSize: chartSize)
    }
}

public enum GateVisibility {
    case none, normal, transposed
}

public extension GateDef {
    func isValid(for chartDims: Tuple2<CDimension?>) -> Bool {
//        visibility(for: chartDims) != .none
        visibility(for: chartDims) == .normal   //AM: transposed not yet supported
    }

    func visibility(for chartDims: Tuple2<CDimension?>) -> GateVisibility {
        let xDim = dims.get(index:0)
        let yDim = dims.get(index:1)
        
        switch (chartDims.x?.name, chartDims.y?.name) {
            // Chart matches gate
        case (xDim, yDim): return .normal
            // Chart matches gate, but transposed
        case (yDim, xDim): return .transposed
            // 1D gate matches chart X axis
        case (xDim, _): return yDim == nil ? .normal : .none
            // 1D gate matches chart Y axis
        case (_, xDim): return yDim == nil ? .transposed : .none
        case (_, _):
            return .none
        }
    }
}


extension RangeGateDef : ViewableGate {

    func viewContent(_ v:ViewType, viewCenter: inout CGPoint) -> (any View)? {
        if let n = v.normalizers.x {
            let chartSize = v.chartSize
            let (min, max) = sort(self.min, self.max)
            let viewMin = n.normalize(min) * v.chartSize.width
            let viewMax = n.normalize(max) * v.chartSize.width
            let viewWidth = viewMax - viewMin
            let chartCenter = v.chartSize / 2
            viewCenter = CGPoint(viewMin + viewWidth / 2, chartCenter.height)
            let opacity = (v.editing ? 1.5 : 1) * v.node.opacity
            
            return Group {
                v.rectControlZone("main-area",
                                  center:viewCenter, width:viewWidth, height:v.chartSize.height,
                                  opacity: opacity,
                                  solid: true
                ) { p in
                    v.gate.wrappedValue?.min = n.unnormalize((p.x - viewWidth / 2) / chartSize.width)
                    v.gate.wrappedValue?.max = n.unnormalize((p.x + viewWidth / 2)  / chartSize.width)
                }
                
                v.rectControlZone("min-edge", center:.init(viewMin, chartCenter.height), width:v.lineWidth, height:chartSize.height) { p in
                    v.gate.wrappedValue?.min = n.unnormalize(p.x / chartSize.width)
                }
                v.rectControlZone("max-edge", center:.init(viewMax, chartCenter.height), width:v.lineWidth, height:chartSize.height) { p in
                    v.gate.wrappedValue?.max = n.unnormalize(p.x / chartSize.width)
                }
            }
        }
        return nil
    }

}

extension RectGateDef : ViewableGate {

    func viewContent(_ v:ViewType, viewCenter: inout CGPoint) -> (any View)? {
        guard let xNormalizer = v.normalizers.x,
              let yNormalizer = v.normalizers.y
        else {
            return nil
        }
        
        let chartSize = v.chartSize
        let viewRect = rect
            .normalize(v.normalizers)
            .invertedY(maxY: 1)
            .scaled(chartSize)
        viewCenter = viewRect.center
        let opacity = (v.editing ? 1.5 : 1) * v.node.opacity
        
        return Group {
            v.rectControlZone("main-area",
                              center: viewRect.center,
                              width: viewRect.width,
                              height: viewRect.height,
                              opacity: opacity,
                              solid: true
            ) { p in
                var newRect = viewRect
                newRect.center = p
                v.gate.wrappedValue?.rect = newRect
                    .scaled(1 / chartSize)
                    .invertedY(maxY: 1.0)
                    .unnormalize(v.normalizers)
            }
            
            v.rectControlZone("left-edge", center:.init(viewRect.minX, viewRect.midY), width:v.lineWidth, height:viewRect.height) { p in
                v.gate.wrappedValue?.minX = xNormalizer.unnormalize(p.x / chartSize.width)
            }
            v.rectControlZone("right-edge", center:.init(viewRect.maxX, viewRect.midY), width:v.lineWidth, height:viewRect.height) { p in
                v.gate.wrappedValue?.maxX = xNormalizer.unnormalize(p.x / chartSize.width)
            }
            v.rectControlZone("top-edge", center:.init(viewRect.midX, viewRect.minY), width:viewRect.width, height:v.lineWidth) { p in
                v.gate.wrappedValue?.maxY = yNormalizer.unnormalize(1.0 - p.y / chartSize.height)
            }
            v.rectControlZone("bottom-edge", center:.init(viewRect.midX, viewRect.maxY), width:viewRect.width, height:v.lineWidth) { p in
                v.gate.wrappedValue?.minY = yNormalizer.unnormalize(1.0 - p.y / chartSize.height)
            }
        }
    }

}
//struct Test<Content:View> : View {
//    let content: (Self) -> Content
//    let name = "Hello"
//    var body: some View {
//        ZStack { content(self) }
//    }
//}
//
//extension Test {
//    func range(_ parent:Self) -> some View {
//        ZStack {
//            Text(parent.name)
//        }
//    }
//}
//
//func test() -> some View {
//    Test(content: range)
//}

//func range<Content:View>(parent:Test<Content>) -> some View {
//    ZStack {}
//}

//class GateViewBuilders {
//}



//struct RangeGateViewBuilder<Content> : GateViewBuilder<RangeGateDef, Content> where Content:View {
//    typealias Content = <#type#>
    
//    func view(view:GateView<RangeGateDef, Content>) -> Content {
//        ZStack { Text("Hello")}
//        return ZStack(alignment: .topLeading) {
//            if let gate = node.gate as? RangeGateDef {
//                let (min, max) = sort(gate.min, gate.max)
//                let viewMin = normalizer.normalize(min) * chartSize.width
//                let viewMax = normalizer.normalize(max) * chartSize.width
//                let viewWidth = viewMax - viewMin
//                let chartCenter = chartSize / 2
//                let viewCenter = CGPoint(viewMin + viewWidth / 2, chartCenter.height)
//                let opacity = (editing ? 1.5 : 1) * node.opacity
//                
//                GateControlZone("main-area", position: viewCenter) { p in
//                    gateBinding.wrappedValue?.min = normalizer.unnormalize((p.x - viewWidth / 2) / chartSize.width)
//                    gateBinding.wrappedValue?.max = normalizer.unnormalize((p.x + viewWidth / 2)  / chartSize.width)
//                } content: { state in
//                    Rectangle()
//                        .fill(node.color.opacity(opacity))
//                        .frame(width: viewWidth,  height: chartSize.height)
//                } handle: { state in
//                    CircleHandle(solid:true)
//                }
//                
//                edgeControlZone("min-edge", x: viewMin) { p in
//                    gateBinding.wrappedValue?.min = normalizer.unnormalize(p.x / chartSize.width)
//                }
//                edgeControlZone("max-edge", x: viewMax) { p in
//                    gateBinding.wrappedValue?.max = normalizer.unnormalize(p.x / chartSize.width)
//                }
//                
//                let labelPosition = viewCenter + node.labelOffset * chartSize
//                GateControlZone("label", position: labelPosition) { p in
//                    let offset = (p - viewCenter) / chartSize
//                    node.labelOffset = offset
//                } content: { state in
//                    GateLabel(node:node)
//                        .scaleEffect(.init(state.hovered ? 1.1 : 1))
//                        .shadow(radius: state.hovered ? 5 : 0)
//                }
//            }
//        }
//    }
//}


struct GateLabel: View {
    let node:PopulationNode

    var body: some View {
        Text(node.name)
            .padding()
            .background(.regularMaterial.opacity(0.4))
            .cornerRadius(10)
        // AM note this offset may need to be different when gate is transposed
//        Rectangle()
//            .fill(.blue)
//            .frame(width: 50, height: 50)
//            .position(gateCenter + node.labelOffset)
            .offset(node.labelOffset.asSize)
    }
}


struct LineWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 3.0
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
