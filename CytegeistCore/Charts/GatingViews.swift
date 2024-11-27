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

public protocol GateHandle : View {
}

public struct CircleHandle: GateHandle {
    @Environment(\.gateColor) var color
    @Environment(\.controlState) var state
    
    
    let solid:Bool
    public init(solid: Bool = false) {
        self.solid = solid
    }
    
    public var body: some View {
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


public typealias ControlState = (hovered:Bool, pressed:Bool)
public typealias MoveAction = ((point:CGPoint, ended:Bool)) -> Void

public struct GateControlZone<Content, Handle> : View, Identifiable where Content:View, Handle:View {
    @Environment(\.handleSize) var size
    @Environment(\.controlSize) var controlSize
    @Environment(\.isEditing) var editing

    public let id: String
    let position: CGPoint
    let applyPosition:Bool
    let content: ((ControlState) -> Content)
    let handle: ((ControlState) -> Handle)
    let move:MoveAction
    
    @State var dragStart:(zonePosition:CGPoint, pressPosition:CGPoint)?

    @State var isHovered:Bool = false
    @State var isPressed:Bool = false
    
    public init(_ id: String,
         position: CGPoint, applyPosition:Bool = true,
         move: @escaping MoveAction,
         content: @escaping ((ControlState) -> Content) = { _ in EmptyView() },
         handle: @escaping ((ControlState) -> Handle) = { _ in EmptyView() }
    ) {
        self.id = id
        self.position = position
        self.applyPosition = applyPosition
        self.content = content
        self.handle = handle
        self.move = move
    }
    
    public var body: some View {
        let state = (isHovered, isPressed)
        
        ZStack() {
            content(state)

            if editing, Handle.self != EmptyView.self {
                let size = (size * controlSize.scaling) * (isHovered ? 1.15 : 1) * (isPressed ? 0.8 : 1)
                handle(state)
                    .frame(width:size, height: size)
            }
        }
        .if(applyPosition) {
            $0.position(position)
        }
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
                            handleDrag(drag, false)
                        }
                        .onEnded { drag in
                            handleDrag(drag, true)
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
    
    func handleDrag(_ drag:DragGesture.Value, _ ended:Bool) {
        guard let dragStart else {
            print("dragStart not set in gate handle \(id)")
            return
        }
        let delta = drag.location - dragStart.pressPosition
        let p = dragStart.zonePosition + delta
        move((p, ended))
    }
}


let gateNudgeOffsetNormalized = 0.002

struct GateView<GateType:GateDef> : View where GateType:ViewableGate {

    @Environment(\.lineWidth) var lineWidth
    @Environment(\.isEditing) var editing
    @Bindable var node: AnalysisNode
    let normalizers:Tuple2<AxisNormalizer?>
    let chartSize:CGSize
    let chartCenter:CGSize
    
    var color:Color = Color.black  //{ node.color ?? .green }
    var fillOpacity:Double { (editing ? 1.5 : 1) * node.opacity }
    var fillColor:Color { color.opacity(fillOpacity) }
    var strokeColor:Color { color.opacity(0.8) }

    var gate:Binding<GateType?> {
        castBinding($node.gate)
    }
    
    public init(node: AnalysisNode, axes: Tuple2<AxisNormalizer?>, chartSize: CGSize) {
        self.node = node
        self.normalizers = axes
        self.chartSize = chartSize
        self.chartCenter = chartSize / 2
    }
    
    var body: some View {
        
        return ZStack(alignment: .topLeading) {
            if let gate = gate.wrappedValue,
               normalizersValidForGate(gate)
            {
                var viewCenter:CGPoint = .zero
                if let content = gate.viewContent(self, viewCenter: &viewCenter) {
                    AnyView(content)
                }
                
                let labelPosition = viewCenter + node.labelOffset * chartSize
                GateControlZone("label", position: labelPosition) { (p, _) in
                    let offset = (p - viewCenter) / chartSize
                    node.labelOffset = offset
                } content: { state in
                    GateLabel(node:node)
                        .scaleEffect(.init(state.hovered ? 1.1 : 1))
                        .shadow(radius: state.hovered ? 5 : 0)
                }
            }
        }
        .focusable()
        .focusEffectDisabled()
        .onArrowKeys { offset in
            gate.wrappedValue?.nudge(node, axes:normalizers, offset: offset * gateNudgeOffsetNormalized)
        }
//        .environment(\.isEditing, editing)
        .animation(.smooth, value:editing)
    }
    
    private func normalizersValidForGate(_ gate:GateType) -> Bool {
        // AM TODO support transposed range gate
        if gate.dims.get(index:0) != nil,
           normalizers.x == nil {
            fatalError("X axis normalizer not availble for gate \(gate)")
//            return false
        }
        
        if gate.dims.get(index:1) != nil,
           normalizers.y == nil {
//            fatalError("Y axis normalizer not availble for gate \(gate)")
            return false
        }

        return true
    }
    
    func rectControlZone(_ id:String, center:CGPoint, width:Double, height:Double, color:Color, solid:Bool = false, move:@escaping MoveAction) -> some View {
        return GateControlZone(id, position: center, move: move) { state in
            Rectangle()
                .fill(color)
                .frame(width:width, height:height)
        } handle: { state in
            CircleHandle(solid:solid)
        }
    }
    
    func handle(_ id:String, position:CGPoint, solid:Bool = false, move:@escaping MoveAction) -> some View {
        return GateControlZone(id, position: position, move: move, handle: { state in
            CircleHandle(solid:solid)
        })
    }

    
    
    // AM for each of these, normalizers should be preverified to be ready for gate axes
    // via normalizersValidForGate
    func view2Data(_ point:CGPoint) -> CGPoint {
        (point / chartSize).invertedY().unnormalize(normalizers)
    }
    
    func data2View(_ point:CGPoint) -> CGPoint {
        point.normalize(normalizers).invertedY() * chartSize
    }
    
    func view2DataX(_ x:Double) -> Double {
        normalizers.x!.unnormalize(x / chartSize.width)
    }
    
    func data2ViewX(_ x:Double) -> Double {
        normalizers.x!.normalize(x) * chartSize.width
    }
    
    func view2DataY(_ x:Double) -> Double {
        normalizers.y!.unnormalize(1 - x / chartSize.height)
    }
    
    func data2ViewY(_ x:Double) -> Double {
        (1 - (normalizers.y!.normalize(x))) * chartSize.width
    }

}



protocol ViewableGate: GateDef {
    associatedtype ViewType = GateView<Self>
    
    func chartView(_ node:AnalysisNode, chartSize:CGSize, chartDims:Tuple2<CDimension?>) -> any View
    func viewContent(_ view:GateView<Self>, viewCenter: inout CGPoint) -> (any View)?
    func isValid(for chartDims: Tuple2<CDimension?>) -> Bool
    mutating func nudge(_ node:AnalysisNode, axes: Tuple2<AxisNormalizer?>, offset:CGPoint)
}

extension ViewableGate {
    func chartView(_ node:AnalysisNode, chartSize:CGSize, chartDims:Tuple2<CDimension?>) -> any View {
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
        let chartSize = v.chartSize
        let (min, max) = sort(self.min, self.max)
        let viewMin = v.data2ViewX(min)
        let viewMax = v.data2ViewX(max)
        let viewWidth = viewMax - viewMin
        viewCenter = CGPoint(viewMin + viewWidth / 2, v.chartCenter.height)
        
        return Group {
            v.rectControlZone("main-area",
                              center:viewCenter, width:viewWidth, height:v.chartSize.height,
                              color: v.fillColor,
                              solid: true
            ) { (p, _) in
                v.gate.wrappedValue?.min = v.view2DataX(p.x - viewWidth / 2)
                v.gate.wrappedValue?.max = v.view2DataX(p.x + viewWidth / 2)
                print("Moving gate: \(p). Binding value after: \(v.gate.wrappedValue?.max)")
            }
            
            v.rectControlZone("min-edge", center:.init(viewMin, v.chartCenter.height), width:v.lineWidth, height:chartSize.height, color:v.strokeColor) { (p, ended) in
                v.gate.wrappedValue?.min = v.view2DataX(p.x)
            }
            v.rectControlZone("max-edge", center:.init(viewMax, v.chartCenter.height), width:v.lineWidth, height:chartSize.height, color:v.strokeColor) { (p, ended) in
                v.gate.wrappedValue?.max = v.view2DataX(p.x)
            }
        }
    }
    
    mutating func nudge(_ node: AnalysisNode, axes: Tuple2<AxisNormalizer?>, offset: CGPoint) {
        if let x = axes.x {
            self.min = x.unnormalize(x.normalize(self.min) + offset.x)
            self.max = x.unnormalize(x.normalize(self.max) + offset.x)
        }
    }
    

}


extension RectGateDef : ViewableGate {
    
    
//    typealias HandleInfo = (id:String,
//                            position:Alignment,
//                            size:(ViewType, CGRect) -> CGSize,
//                            setter:(inout CGPoint, CPoint) -> Void)
////
//    static let handles:[HandleInfo] = [
//        ("l-edge", .leading, { .init($0.lineWidth, $1.height) }, { r, p in })
//    ]

    func viewContent(_ v:ViewType, viewCenter: inout CGPoint) -> (any View)? {
        let viewRectOrigin = v.data2View(rect[.bottomLeading])
        let viewRectOppositeOrigin = v.data2View(rect[.topTrailing])
        let viewRect = CGRect(origin: viewRectOrigin, size: (viewRectOppositeOrigin - viewRectOrigin).asSize)
        viewCenter = viewRect[.center]
        
        
        return Group {
            v.rectControlZone("main-area",
                              center: viewCenter,
                              width: viewRect.width,
                              height: viewRect.height,
                              color: v.fillColor,
                              solid: true
            ) { (p, _) in
                v.gate.wrappedValue?.rect[.center] = v.view2Data(p)
            }
            
//            ForEach(handles, id:\.id) { h in
//                let size = h.size(v, viewRect)
//                v.rectControlZone(h.id, center:viewRect[h.position], width:size.width, height:size.height, color:v.strokeColor) { p in
//                    v.gate.wrappedValue?.rect[.leading].x = v.view2DataX(p.x)
//                }
//            }

            Group {
                v.rectControlZone("left-edge", center:viewRect[.leading], width:v.lineWidth, height:viewRect.height, color:v.strokeColor, solid:true) { (p, ended) in
                    updateGateRect(v, fix:ended, { r in r[.leading].x = v.view2DataX(p.x) })
                }
                v.rectControlZone("right-edge", center:viewRect[.trailing], width:v.lineWidth, height:viewRect.height, color:v.strokeColor, solid:true) { (p, ended) in
                    updateGateRect(v, fix:ended, { r in r[.trailing].x = v.view2DataX(p.x) })
                    
                }
                v.rectControlZone("top-edge", center:viewRect[.top], width:viewRect.width, height:v.lineWidth, color:v.strokeColor, solid:true) { (p, ended) in
                    updateGateRect(v, fix:ended, { r in r[.top].y = v.view2DataY(p.y)})
                }
                v.rectControlZone("bottom-edge", center:viewRect[.bottom], width:viewRect.width, height:v.lineWidth, color:v.strokeColor, solid:true) { (p, ended) in
                    updateGateRect(v, fix:ended, { r in r[.bottom].y = v.view2DataY(p.y)})
                }
            }
            .controlSize(.small)
            
            
            v.handle("tl", position: viewRect[.topLeading], solid:false) { (p, ended) in
                updateGateRect(v, fix:ended, { r in r[.topLeading] = v.view2Data(p) })
            }
            v.handle("tr", position: viewRect[.topTrailing], solid:false) { (p, ended) in
                updateGateRect(v, fix:ended, { r in r[.topTrailing] = v.view2Data(p) })
            }
            v.handle("bl", position: viewRect[.bottomLeading], solid:false) { (p, ended) in
                updateGateRect(v, fix:ended, { r in r[.bottomLeading] = v.view2Data(p) })
            }
            v.handle("br", position: viewRect[.bottomTrailing], solid:false) { (p, ended) in
                updateGateRect(v, fix:ended, { r in r[.bottomTrailing] = v.view2Data(p) })
            }
        }
    }
    
    func updateGateRect(_ view: ViewType, fix:Bool, _ update:(inout CRect) -> Void) {
        if var rect = view.gate.wrappedValue?.rect {
            update(&rect)
            if fix {
                rect.canonicalize()
            }
            view.gate.wrappedValue?.rect = rect
        }
    }
    
    
    mutating func nudge(_ node: AnalysisNode, axes: Tuple2<AxisNormalizer?>, offset: CGPoint) {
        print("Rect Nudge not implemented")
    }
}


extension EllipsoidGateDef : ViewableGate {
    
    func gate2View(_ point:CPoint, _ view:ViewType) -> CPoint {
        view.data2View(point.unnormalize(self.axes))
    }
    
    func view2Gate(_ point:CPoint, _ view:ViewType) -> CPoint {
        view.view2Data(point).normalize(self.axes)
    }

    func viewContent(_ v:ViewType, viewCenter: inout CGPoint) -> (any View)? {
//        let normalizers = v.normalizers.nonNil
        
        let gate = v.gate
        let majorVertices = normalizedShape.majorVertices
        let minorVertices = normalizedShape.minorVertices
//        let viewEllipse = normalizedShape.scaled(chartSize)
        
        viewCenter = gate2View(normalizedShape.center, v)
        let viewCenter = viewCenter
        let points = normalizedPath().map { gate2View($0, v) }
        let shape = Polygon(points: points)
//        gate.wrappedValue?.normalizedShape.setMajor(view2Gate(CPoint(0,0) - viewCenter))
//        gate.wrappedValue?.normalizedShape.setMajor(relativeToCenter:view2Gate(CPoint(0,0) - viewCenter, v))

        return Group {
            GateControlZone("main-area", position: viewCenter, applyPosition:false) { (p, _) in
                gate.wrappedValue?.normalizedShape.center = view2Gate(p, v)
            } content: { state in
                shape
                    .fill(v.fillColor)
                    .stroke(v.strokeColor, lineWidth: v.lineWidth)
                    .contentShape(shape)
            }
//            handle: { state in
//                CircleHandle(solid:true)
//            }
            
            ForEach(0...1, id:\.self) { i in
                GateControlZone("major-vertex\(i)", position: gate2View(majorVertices[i], v)) { (p, _) in
                    // Set major vertex based on the vector from ellipse center to drag point
                    let vertex = view2Gate(p, v) - normalizedShape.center
                    gate.wrappedValue?.normalizedShape.setMajor(relativeToCenter:vertex)
                } handle: { state in
                    CircleHandle()
                }
            }
            
            ForEach(0...1, id:\.self) { i in
                GateControlZone("minor-vertex\(i)", position: gate2View(minorVertices[i], v)) { (p, _) in
                    // Set minor vertex based on the vector from ellipse center to drag point
                    let vertex = view2Gate(p, v) - normalizedShape.center
                    gate.wrappedValue?.normalizedShape.setMinor(relativeToCenter:vertex)
                } handle: { state in
                    CircleHandle(solid:true)
                }
//                .controlSize(.small)
            }
        }
    }
    
    mutating func nudge(_ node: AnalysisNode, axes: Tuple2<AxisNormalizer?>, offset: CGPoint) {
        print("Ellipse Nudge not implemented")
    }
}

public struct Polygon : Shape {
    public let points:[CGPoint]
    public init(points: [CGPoint]) {
        self.points = points
    }
    
    public func path(in rect:CGRect) -> Path {
        Path(points:points)
    }
}




struct GateLabel: View {
    @Environment(\.annotationScale) var scale
    
    let node:AnalysisNode

    var body: some View {
        Text(node.name)
            .padding()
            .background(.regularMaterial.opacity(0.4))
            .cornerRadius(10)
            .scaleEffect(scale)
        // AM this offset may need to be different when gate is transposed
            .offset(node.labelOffset.asSize)
    }
}


struct LineWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 1.5
}

struct HandleSizeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Double = 20
}

struct GateColorEnvironmentKey: EnvironmentKey {
    static let defaultValue = Color.green
}

struct ControlStateEnvironmentKey: EnvironmentKey {
    static let defaultValue:ControlState = (false, false)
}

struct IsEditingEnvironmentKey: EnvironmentKey {
    static let defaultValue:Bool = false
}

struct AnnotationScaleEnvironmentKey: EnvironmentKey {
    static let defaultValue:CGFloat = 1.0
}

public extension EnvironmentValues {
    var lineWidth: Double {
        get { self[LineWidthEnvironmentKey.self] }
        set { self[LineWidthEnvironmentKey.self] = newValue }
    }
    
    var handleSize: Double {
        get { self[HandleSizeEnvironmentKey.self] }
        set { self[HandleSizeEnvironmentKey.self] = newValue }
    }
    
    var gateColor: Color {
        get { self[GateColorEnvironmentKey.self] }
        set { self[GateColorEnvironmentKey.self] = newValue }
    }
    
    internal var controlState: ControlState {
        get { self[ControlStateEnvironmentKey.self] }
        set { self[ControlStateEnvironmentKey.self] = newValue }
    }
    
    var isEditing: Bool {
        get { self[IsEditingEnvironmentKey.self] }
        set { self[IsEditingEnvironmentKey.self] = newValue }
    }
    
    var annotationScale: CGFloat {
        get { self[AnnotationScaleEnvironmentKey.self] }
        set { self[AnnotationScaleEnvironmentKey.self] = newValue }
    }
}


