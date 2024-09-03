//
//  SampleDetail.swift
//  filereader
//
//  Created by Adam Treister on 7/30/24.
//

import SwiftUI
import Charts
import UniformTypeIdentifiers.UTType
import CytegeistLibrary
import CytegeistCore


struct GateConfigView : View {
    var node:PopulationNode
    var finalize:() -> Void
    
    
        //    init(name: String, finalize: @escaping (String) -> Void) {
        //        self.finalize = finalize
        //        self.name = name
        //    }
    
    var body: some View {
        @Bindable var node = node
        
        Group {
            TextField("Name", text: $node.name)
            Buttons.ok("Create Gate", action:finalize)
            Buttons.cancel()
        }
    }
}



struct GatingView: View {

//    @State private var mode = ReportMode.gating
    @State var curTool = GatingTool.range
    @State private var isDragging = false
 
    @State public var startLocation = CGPoint.zero
    @State public var mouseLocation = CGPoint.zero
    @State public var mouseTranslation = CGPoint.zero
    @State private var isHovering = false
    @State private var offset = CGSize.zero
    
    @State private var confirmGate:PopulationNode? = nil
    @State private var focusedItem:ChartAnnotation? = nil
    @State private var confirmDelete:ChartAnnotation? = nil
//    var sample: Sample?
    var population: AnalysisNode?
    
    @State var chartDef: ChartDef = {
        var c = ChartDef()
        c.xAxis = .init(dim:"FSC-A")
        c.yAxis = .init(dim:"SSC-A")
        return c
    }()
    
    @Environment(Experiment.self) var experiment
    
    func visibleChildren() -> [ChartAnnotation] {
        let dims = dimensions()
        if let children = population?.children {
            let result = children.compactMap { child in
                child.chartView(chart: chartDef, dims:dims)
            }
            return result
        }
        return []
//        guard let children:[PopulationNode] = population?.getChildren() else {
//            return []
//        }
        
//        children.filter { child in
//            let gate = child.gate
////            gate.dims.
//        }
    }

    func deleteSelectedAnnotation() {
        if let focusedItem, focusedItem.remove != nil {
            confirmDelete = focusedItem
        }
    }


//    var selectedSample: Sample
    func chart(_ request: PopulationRequest, _ meta: FCSMetadata) -> some View {
        
        return ChartView(population: request, config: $chartDef) {
            VStack {
                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack(alignment: .topLeading) {
                        gateRadius(siz: proxy.size)
                        gateRange(siz: proxy.size)
                        gateRect(siz: proxy.size)
                        gateEllipse(siz: proxy.size)
                        crosshair(location: mouseLocation, size: proxy.size )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .gesture(makeDragGesture(areaSize: proxy.size))
                            .gesture(makeTapGesture())
                        
                        
                        ForEach(visibleChildren(), id:\.self) { child in
                            let editing = child == focusedItem
                            AnyView(child.view(size, editing))
                                .environment(\.isEditing, editing)
                            .onTapGesture {
                                focusedItem = child
                            }
                        }
                    }
                }
            }
            .fillAvailableSpace()
            }
            .padding(40)
            .allowsHitTesting(true)
//            .opacity(mode == ReportMode.gating ? 1.0 : 0.0)
            .focusable()
            .focusEffectDisabled()
            .onDeleteCommand(perform: deleteSelectedAnnotation)
        
            .confirmationDialog("Enter new gate name", isPresented: isNonNilBinding($confirmGate)) {
                if let confirmGate {
                    GateConfigView(node:confirmGate, finalize: finalizeCandidateGate)
                }
            }
            .confirmationDialog("Are you sure you want to delete \(confirmDelete?.name ?? "")",
                                isPresented: isNonNilBinding($confirmDelete)) {
                Buttons.delete() {
                    confirmDelete?.remove?()
                }
                Buttons.cancel()
            }
    }
    
    var sampleMeta: FCSMetadata? {
        population?.getSample()?.meta
    }
    
    func dimensions() -> Tuple2<CDimension?> {
        guard let sampleMeta else {
            return .init(nil, nil)
        }
        
        let xAxis = chartDef.xAxis?.name
        let yAxis = chartDef.yAxis?.name
        
        return .init(
            sampleMeta.parameter(named: xAxis.nonNil),
            sampleMeta.parameter(named: yAxis.nonNil)
        )
    }
    
    func axisNormalizers() -> Tuple2<AxisNormalizer?> {
        dimensions().map { $0?.normalizer }
    }
    
    
    func makeGate(_ start: CGPoint, _ location: CGPoint, areaPixelSize:CGSize)
    {
        let normalizers = axisNormalizers()
        
        var start = (start / areaPixelSize).invertedY().unnormalize(normalizers)
        var end = (location / areaPixelSize).invertedY().unnormalize(normalizers)

        let rect = CGRect(from:start, to:end)
        
        guard let xDim = chartDef.xAxis?.name else {
            print("No x axis for gate")
            return
        }
        

        switch curTool
        {
            case .range:        addRangeGate(xDim, rect.minX, rect.maxX); return
            case .split:        add2RangeGates(xDim, rect.maxX); return
            default: break
        }
        
        guard let yDim = chartDef.yAxis?.name else {
            print("No y axis for gate")
            return
        }
        
        guard let xNormalizer = normalizers.x,
              let yNormalizer = normalizers.y else {
            print("2D gate has nil normalizer")
            return
        }
        
        let dims = Tuple2(xDim, yDim)
        let normalizersNonNil = Tuple2(xNormalizer, yNormalizer)
        

        switch curTool {
            case .rectangle:    addRectGate(dims, rect)
            case .ellipse:      addEllipseGate(dims, normalizersNonNil, start, end)
                    //            case .quads:        addQuadGates(gateName, start, location)
                    //            case .polygon:      addPolygonGate(gateName, start, location)
                    //            case .spline:       addSplineGate(gateName, start, location)
            case .radius:       addRadialGate(dims,  start, distance(start, location))
            default: break
        }
    }
    func addGate(_ gate: AnyGate)
    {
            //        self.candidateGateName = getCandidateGateName()
        let node = PopulationNode(gate:gate)
        node.gate = gate
        node.name = "T Cells"
        confirmGate = node
    }
    
    func finalizeCandidateGate() {
        guard let population,
              let confirmGate
        else {
            print("No population selected")
            return
        }
        
        let graphDef = population.graphDef            // change axes?
        confirmGate.graphDef = graphDef

        
        print("adding \(confirmGate.name) to \(population.name)")
        population.addChild(confirmGate)
        experiment.selectedAnalysisNodes.nodes = [confirmGate]
        self.confirmGate = nil
    }
    
    func toParent() -> ()
    {
        if let pop = population {
            if let parent = pop.parent {
                experiment.setAnalysisNodeSelection(parent)
            } }
//        print ("toParent")
    }
 
    func toChild() -> ()
    {
        if let pop = population {
            if let child = pop.children.first {
                experiment.setAnalysisNodeSelection(child)
            } }
       print ("TODO  toChild -- using first child, not selected")
    }

    var icons = ["None","triangle.righthalf.fill","pencil","square.and.pencil","ellipsis.circle", "skew", "scribble" ]

    var  GatingTools: some View {
        HStack{
            Spacer()
            HStack{
                Button("Range", systemImage: "pencil",  action: { curTool = GatingTool.range }).background(curTool == .range ? .yellow : .gray)
                Button("Split", systemImage: "triangle.righthalf.fill",   action: {curTool = GatingTool.split })
                Button("Radius", systemImage: "triangle.righthalf.fill",   action: {curTool = GatingTool.radius }).background(curTool == .radius ? .yellow : .gray)
                Button("Rectangle", systemImage: "square.and.pencil",   action: { curTool = GatingTool.rectangle}).background(curTool == .rectangle ? .yellow : .gray)
                Button("Ellipse", systemImage: "ellipsis.circle",   action: {curTool = GatingTool.ellipse }).background(curTool == .ellipse ? .yellow : .gray)
                Spacer(minLength: 50)
                Button("Up",  systemImage: "arrowtriangle.up.square.fill", action: { toParent() })
                Button("Down",  systemImage: "arrowtriangle.down.square.fill", action: { toChild() })
//                Button("Quads", systemImage: "person.crop.square",   action: { curTool = GatingTool.quads})
//                Button("Polygon", systemImage: "skew",   action: { curTool = GatingTool.polygon})
//                Button("Spline", systemImage: "scribble",   action: {curTool = GatingTool.spline })
            }
            .background(Color.gray.opacity(0.3))
        }
    }
    enum GatingTool {
        var id: Self { self }
            case range
            case split
            case rectangle
            case ellipse
            case quads
            case polygon
            case spline
            case radius
        }
 

    var body: some View {
        var request:PopulationRequest? = nil
        var requestError:Error? = nil
        
        do {
            request = try population?.createRequest()
        } catch {
            requestError = error
        }

        return VStack {
//            Text("Gating Prototype")
            if let sample = population?.getSample() {
                Text("Sample: \(sample.tubeName), population: \((population?.name).nonNil)")
                
                if let meta = sample.meta {
                    if let request {
                        chart(request, meta)
                    } else {
                        Text("Error creating chart: \(requestError?.localizedDescription ?? "")")
                    }
                } else { Text("Sample metadata not found")  }
            }
            else {Text("Select a sample")  }

        }.toolbar {  GatingTools   }
    }
    //------------------------------------------------------
//
//var drag: some Gesture {
//    DragGesture()
//        .onChanged { _ in self.isDragging = true }
//        .onEnded { _ in self.isDragging = false }
//}
    func makeDragGesture(areaSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in offset = value.translation
                isDragging = true
    //            print(offset)
                mouseLocation = value.location
                mouseTranslation = CGPoint( x:offset.width, y: offset.height)
                if (startLocation == CGPoint.zero)
                {
                    startLocation = value.location
                }

            }
            .onEnded { value in
                isDragging = false
                makeGate(mouseLocation, startLocation, areaPixelSize:areaSize)
                startLocation = CGPoint.zero
                mouseLocation = CGPoint.zero
            }
    }
    
    func makeTapGesture() -> some Gesture {
        TapGesture()
            .onEnded {
                focusedItem = nil
            }
    }
    
    func addRangeGate(_ dim:String, _ min: CGFloat, _ max: CGFloat)
    {
        addGate(RangeGateDef(dim, min, max))
    }
    
    func add2RangeGates(_ dim:String, _ x: CGFloat)
    {
//        addGate(Gate(spec: BifurGateDef(x), color: Color.yellow, opacity: 0.2))
            //        addGate(Gate(spec: RangeGateDef(,0, x), color: Color.yellow, opacity: 0.2))
            //        addGate(Gate(spec: RangeGateDef(x, 2 * x), color: Color.red, opacity: 0.2))         // TODO MAX value
    }
    
    func addRectGate(_ dims:Tuple2<String>, _ rect: CGRect)
    {
        addGate(RectGateDef(dims, rect))
    }
    
    func addRadialGate(_ dims:Tuple2<String>, _ start: CGPoint, _ radius: CGFloat)
    {
        addGate(RadialGateDef(dims, start.x, start.y, radius))
    }
    
    func addEllipseGate(_ dims:Tuple2<String>, _ axes:Tuple2<AxisNormalizer>, _ start: CGPoint, _ end: CGPoint)
    {
        var gate = EllipsoidGateDef(dims,
                                    .init(vertex0: start.normalize(axes),
                                          vertex1: end.normalize(axes),
                                          widthRatio: 0.6),
                                    axes: axes)
        addGate(gate)
    }
    
    
    
    let DEBUG = false
    //------------------------------------------------------
    // we need the size of the parent View to offset ourself
    func gateRect(siz: CGSize ) -> some View {
        let startLocation = startLocation
        let translation = mouseLocation - startLocation
        return Rectangle()
           .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
            .foregroundColor(.red)
            .opacity(DEBUG || (isDragging && (curTool == .rectangle)) ? 1.0 : 0.0)
            .offset(x: startLocation.x, y: startLocation.y)
            .offset(x:          min(translation.x,0),  y: min(translation.y, 0) )
            .frame(maxWidth:     abs(translation.x),    maxHeight: abs(translation.y),
                   alignment: Alignment.center)         // DOESNT SEEM TO MATTER
         .allowsHitTesting(false)
    }

    func gateRange(siz: CGSize ) -> some View {
        let start = startLocation.x
        let end = mouseLocation.x
        let width = abs(start - end)
        return Rectangle()
            .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
            .foregroundColor(.yellow)
            .opacity(DEBUG || (isDragging && (curTool == .range)) ? 1.0 : 0.0)
            .position(x: min(start, end), y: 0)
            .offset(x: width / 2, y: siz.height / 2 )
            .frame(width: width,  height: siz.height, alignment: Alignment.topLeading)  
            .allowsHitTesting(false)
    }
    
    func gateEllipse(siz: CGSize ) -> some View {
        let startLocation = startLocation
        let translation = mouseLocation - startLocation
        return Ellipse()
            .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
            .foregroundColor(.green)
            .opacity(DEBUG || (isDragging && curTool == .ellipse)  ? 1.0 : 0.0)
            .offset(x: startLocation.x, y: startLocation.y)
            .offset(x:          min(translation.x,0),  y: min(translation.y, 0) )
            .frame(maxWidth:     abs(translation.x),    maxHeight: abs(translation.y),
                   alignment: Alignment.center)         // DOESNT SEEM TO MATTER
            .allowsHitTesting(false)
    }
    
    func gateRadius(siz: CGSize ) -> some View {
        let startLocation = startLocation
        return Group
        {
            Path { path in
                path.move(to: startLocation )
                path.addLine(to: mouseLocation)
            }
            .stroke(Color.brown, style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
            let distance = distance(startLocation, mouseLocation);
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
                .foregroundColor(.brown)
                .position(startLocation)
                .frame(width: 2 * distance,
                       height: 2 * distance,
                       alignment: Alignment.center)         // DOESNT SEEM TO MATTER
                .allowsHitTesting(false)
        } 
        .opacity((isDragging && curTool == .radius)  ? 1.0 : 0.0)

    }
//    func gatePolygon(siz: CGSize ) -> some View {
//        Path()
//            .move(to: startLocation)
//            .addLine(to: startLocation)
//            .stroke(style: StrokeStyle(lineWidth: 3, dash: [15, 5]))
//            .foregroundColor(.orange)
//            .opacity(DEBUG || (isDragging && curTool == .polygon)  ? 1.0 : 0.0)
//            .offset(x: startLocation.x-siz.width/2, y: startLocation.y-siz.height/2)
//            .offset(x:-mouseTranslation.x/2, y: -mouseTranslation.y/2)
//            .frame(maxWidth: abs(mouseTranslation.x),
//                   maxHeight: abs(mouseTranslation.y),
//                   alignment: Alignment.center)         // DOESNT SEEM TO MATTER
//            .allowsHitTesting(false)
//    }
    //------------------------------------------------------
    func crosshair(location: CGPoint, size:CGSize) -> some View
    {
        ZStack { dashedLine(
            from:CGPoint(x: location.x, y:0),
            to:CGPoint(x: location.x,  y: size.height-40))      // TODO FUDGE FOR X axis
            
            dashedLine(
                from:CGPoint(x: 0,      y: location.y),
                to:CGPoint(x: size.width-20, y: location.y))          // TODO FUDGE FOR Y axis
            .opacity((curTool == .range) ? 0.0 : 1.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(isDragging ? 0.0 : 1.0)
        .onHover(perform: { hovering in isHovering = true  })
        .onContinuousHover { phase in
            switch phase {
                case .active(let location):
                    mouseLocation = location
                    isHovering = true
                case .ended:
                    isHovering = false
                    break
            }
        }
        
    }
    
    func dashedLine(from:CGPoint, to:CGPoint) -> some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
        .foregroundColor(.black)
        .allowsHitTesting(false)
    }

}


//COMING
//import TextRenderer
//struct ColorfulRender: TextRenderer {
//    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
//            // Iterate through RunSlice and their indices
//        for (index, slice) in layout.flattenedRunSlices.enumerated() {
//                // Calculate the angle of color adjustment based on the index
//            let degree = Angle.degrees(360 / Double(index + 1))
//                // Create a copy of GraphicsContext
//            var copy = context
//                // Apply hue rotation filter
//            copy.addFilter(.hueRotation(degree))
//                // Draw the current Slice in the context
//            copy.draw(slice)
//        }
//    }
//}
//
//struct ColorfulDemo: View {
//    var body: some View {
//        Text("Hello World")
//            .font(.title)
//            .fontWeight(.heavy)
//            .foregroundStyle(.red)
//            .textRenderer(ColorfulRender())
//    }
//}

