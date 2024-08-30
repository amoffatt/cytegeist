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

    @State private var mode = ReportMode.gating
    @State var curTool = GatingTool.range
    @State private var isDragging = false
 
    @State public var startLocation = CGPoint.zero
    @State public var mouseLocation = CGPoint.zero
    @State public var mouseTranslation = CGPoint.zero
    @State private var isHovering = false
    @State private var offset = CGSize.zero
    
    @State private var candidateGate:PopulationNode? = nil
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
        if let children = population?.children {
            let result = children.compactMap { child in
                child.chartView(chart: chartDef)
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



//    var selectedSample: Sample
    func chart(_ request: PopulationRequest, _ meta: FCSMetadata) -> some View {
        let showGatePopup:Binding<Bool> = .init(
            get: { self.candidateGate != nil },
            set: { _ in self.candidateGate = nil }
        )
        
        
        return ChartView(population: request, config: $chartDef) {
            VStack {
                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack(alignment: .topLeading){
                        ForEach(visibleChildren()) { child in
                            AnyView(child.view(meta, size))
                        }
                        
                        gateRadius(siz: proxy.size)
                        gateRange(siz: proxy.size)
                        gateRect(siz: proxy.size)
                        gateEllipse(siz: proxy.size)
                        crosshair(location: mouseLocation, size: proxy.size )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .gesture(gateDrag(areaSize: proxy.size))
                    }
//                    .frame(width:size.width, height:size.height)
                }
            }
            .fillAvailableSpace()
            }
            .padding(40)
            .allowsHitTesting(true)
            .opacity(mode == ReportMode.gating ? 1.0 : 0.0)
        
            .confirmationDialog("Enter new gate name", isPresented: showGatePopup) {
                if let candidateGate {
                    GateConfigView(node:candidateGate, finalize: finalizeCandidateGate)
                }
            }
    }
    
//    func makeChart() -> some View {
//        
//    }
    
    var sampleMeta: FCSMetadata? {
        population?.getSample()?.meta
    }
    
    var axisNormalizers: Tuple2<AxisNormalizer> {
        guard let sampleMeta else {
            return .init(.none, .none)
        }
        
        let xAxis = chartDef.xAxis?.name
        let yAxis = chartDef.yAxis?.name
        
        return .init(
            sampleMeta.parameter(named: xAxis.nonNil)?.normalizer ?? .none,
            sampleMeta.parameter(named: yAxis.nonNil)?.normalizer ?? .none
        )
    }
    
    
    func makeGate(_ start: CGPoint, _ location: CGPoint, areaPixelSize:CGSize)
    {
        var start = (start / areaPixelSize)
        var end = (location / areaPixelSize)
        
        // Invert view space coordinates
        start.y = 1 - start.y
        end.y = 1 - end.y

        let normalizers = axisNormalizers
        let rect = CGRect(
            from: start.unnormalize(normalizers),
            to: end.unnormalize(normalizers)
        )
        
//        if let xAxis = normalizers.x {
//            
//            minX = min(start.x, location.x) / areaPixelSize.width
//            maxX = max(start.x, location.x) / areaPixelSize.width
//            minX = xAxis.unnormalize(minX)
//            maxX = xAxis.unnormalize(maxX)
//        }
        
            // TODO delete
        let candidateGateName = ""
        
        guard let xDim = chartDef.xAxis?.name else {
            print("No x axis for gate")
            return
        }
        

        switch curTool
        {
            case .range:        addRangeGate(candidateGateName, xDim, rect.minX, rect.maxX); return
            case .split:        add2RangeGates(candidateGateName, xDim, rect.maxX); return
            default: break
        }
        
        guard let yDim = chartDef.yAxis?.name else {
            print("No y axis for gate")
            return
        }
        let dims = Tuple2(xDim, yDim)

        switch curTool {
            case .rectangle:    addRectGate(candidateGateName, dims, rect)
            case .ellipse:      addEllipseGate(candidateGateName, start, location)
                    //            case .quads:        addQuadGates(gateName, start, location)
                    //            case .polygon:      addPolygonGate(gateName, start, location)
                    //            case .spline:       addSplineGate(gateName, start, location)
            case .radius:       addRadialGate(candidateGateName, start, distance(start, location))
            default: break
        }
    }
    func addGate(_ gate: AnyGate)
    {
            //        self.candidateGateName = getCandidateGateName()
        let node = PopulationNode(gate:gate)
        node.gate = gate
        node.name = "T Cells"
        candidateGate = node
    }
    
    func finalizeCandidateGate() {
        guard let population,
              let candidateGate
        else {
            print("No population selected")
            return
        }
        
        let graphDef = population.graphDef            // change axes?
        candidateGate.graphDef = graphDef

        
        print("adding \(candidateGate.name) to \(population.name)")
        population.addChild(candidateGate)
        
        experiment.selectedAnalysisNodes.nodes = [candidateGate]
        
        self.candidateGate = nil
    }
    
    
    var icons = ["None","triangle.righthalf.fill","pencil","square.and.pencil","ellipsis.circle", "skew", "scribble" ]

    var  GatingTools: some View {
        HStack{
            Spacer()
            HStack{
                Button("Range", systemImage: "pencil",  action: { curTool = GatingTool.range }).background(curTool == .range ? .yellow : .gray)
//                Button("Split", systemImage: "triangle.righthalf.fill",   action: {curTool = GatingTool.split })
                Button("Radius", systemImage: "triangle.righthalf.fill",   action: {curTool = GatingTool.radius }).background(curTool == .radius ? .yellow : .gray)
                Button("Rectangle", systemImage: "square.and.pencil",   action: { curTool = GatingTool.rectangle}).background(curTool == .rectangle ? .yellow : .gray)
                Button("Ellipse", systemImage: "ellipsis.circle",   action: {curTool = GatingTool.ellipse }).background(curTool == .ellipse ? .yellow : .gray)
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
                } else {
                    Text("Sample metadata not found")
                }
            }
            else {
                Text("Select a sample")
            }

        }.toolbar {
            GatingTools
            
        }
    }
    //------------------------------------------------------
//
//var drag: some Gesture {
//    DragGesture()
//        .onChanged { _ in self.isDragging = true }
//        .onEnded { _ in self.isDragging = false }
//}
    func gateDrag(areaSize: CGSize) -> some Gesture {
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
    
    func addRangeGate(_ newName: String, _ dim:String, _ min: CGFloat, _ max: CGFloat)
    {
        addGate(RangeGateDef(dim, min, max))
    }
    
    func add2RangeGates(_ name: String, _ dim:String, _ x: CGFloat)
    {
//        addGate(Gate(spec: BifurGateDef(x), color: Color.yellow, opacity: 0.2))
            //        addGate(Gate(spec: RangeGateDef(,0, x), color: Color.yellow, opacity: 0.2))
            //        addGate(Gate(spec: RangeGateDef(x, 2 * x), color: Color.red, opacity: 0.2))         // TODO MAX value
    }
    
    func addRectGate(_ name: String, _ dims:Tuple2<String>, _ rect: CGRect)
    {
        addGate(RectGateDef(dims, rect))
    }
    
    func addRadialGate(_ newName: String,_ start: CGPoint, _ radius: CGFloat)
    {
//        addGate(Gate(spec: RadialGateDef(start, radius), color: Color.brown, opacity: 0.2))
    }
    
    func addEllipseGate(_ name: String,_ start: CGPoint, _ location: CGPoint)
    {
//        addGate(Gate(spec: EllipsoidGateDef(start, location), color: Color.brown, opacity: 0.2))
    }

    
    
    
    
    
let DEBUG = false
    //------------------------------------------------------
    // we need the size of the parent View to offset ourself
    func gateRect(siz: CGSize ) -> some View {
        let start = startLocation.x
        let end = mouseLocation.x
        let startY = startLocation.y
        let endY = mouseLocation.y
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
struct LayoutPasteboard: View {
    @State  var mode =  ReportMode.gating
 
//    var Dragger: any View {
//     }
    var body: some View
    {
        VStack {
            Text("Layout Editor:. \(mode) ")
            Spacer()
            CGLayoutView()
//            Spacer(4)
         }
        .opacity(mode == ReportMode.layout ? 1.0 : 0.0)
   }
}

//
//
//struct MyDropDelegate : DropDelegate {
//    
//    let item : String
//    @Binding var items : [String]
//    @Binding var draggedItem : String?
//    
//    func performDrop(info: DropInfo) -> Bool {
//        return true
//    }
//    
//    func dropEntered(info: DropInfo) {
//        guard let draggedItem = self.draggedItem else {
//            return
//        }
//        
//        if draggedItem != item {
//            let from = items.firstIndex(of: draggedItem)!
//            let to = items.firstIndex(of: item)!
//            withAnimation(.default) {
//                self.items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
//            }
//        }
//    }
//}
//
