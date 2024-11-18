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
    var node:AnalysisNode
    var finalize:@MainActor () -> Void
    
    
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
    
    @State private var confirmedGate:AnalysisNode? = nil
    @State private var focusedItem:ChartAnnotation? = nil
    @State private var confirmDelete:ChartAnnotation? = nil
    
    @FocusState var isFocused

        //    var sample: Sample?
    var population: AnalysisNode?
    
    @Environment(Experiment.self) var experiment
    @Environment(CytegeistCoreAPI.self) var core
    @Environment(BatchContext.self) var batchContext

    func deleteSelectedAnnotation() {
        if let focusedItem, focusedItem.remove != nil {
            confirmDelete = focusedItem
        }
    }
    
    var chartDef: ChartDef? { population?.chartDef }
    var chartDefBinding: Binding<ChartDef?> {
        .init(get: { chartDef },
              set: { if let chartDef = $0 { population?.chartDef = chartDef  }}
        )
    }
    
    func chart(_ meta: FCSMetadata) -> some View {
        return ChartView(population: population, config: chartDefBinding, focusedItem: $focusedItem) { size in
            ZStack(alignment: .topLeading) {
                gateRadius(siz: size)
                gateRange(siz: size)
                gateRect(siz: size)
                gateEllipse(siz: size)
//                if population?.visibleChildren(batchContext, chartDef!).count == 0 {
                    crosshair(location: mouseLocation, size: size )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .simultaneousGesture(makeDragGesture(areaSize: size))
                        .simultaneousGesture(makeTapGesture())
//                }
            }
        }
        .padding(40)
        .allowsHitTesting(true)
            //            .opacity(mode == ReportMode.gating ? 1.0 : 0.0)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .focusedValue(\.analysisNode, population)
        .onAppear {  isFocused = true   }
        .onDeleteCommand(perform: deleteSelectedAnnotation)
        .confirmationDialog("Enter new gate name", isPresented: isNonNilBinding($confirmedGate)) {
            if let confirmedGate {
                GateConfigView(node:confirmedGate, finalize: finalizeCandidateGate)
            }
        }
        .confirmationDialog("Are you sure you want to delete \(confirmDelete?.name ?? "")",
                            isPresented: isNonNilBinding($confirmDelete)) {
            Buttons.delete() {    confirmDelete?.remove?()   }
            Buttons.cancel()
        }
        .onChange(of: population, initial:true) {
            if chartDef?.xAxis == nil && chartDef?.yAxis == nil {
                 chartDefBinding.wrappedValue?.xAxis = AxisDef(dim:"FSC-A")
                 chartDefBinding.wrappedValue?.yAxis = AxisDef(dim:"SSC-A")
               }
        }
        
    }
    
    func axisNormalizers() -> Tuple2<AxisNormalizer?> {
        population?.getChartDimensions(batchContext, chartDef).map { $0?.normalizer } ?? .init(nil, nil)
    }
    
        //    @MainActor
        //    func snapshot() -> NSImage?
        //    {
        //        let renderer = ImageRenderer(content: self)
        //        renderer.scale = 0.25
        //        return renderer.nsImage
        //    }
   let split = "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
        //--------------------------------------------------------------------
    var icons = ["None","triangle.righthalf.fill","pencil","square.and.pencil","ellipsis.circle", "skew", "scribble" ]
    
    var  GatingTools: some View {
        HStack{
            Spacer(minLength: 200)
            HStack{
                Spacer()
                Button("Range", systemImage: "pencil",  action: { curTool = GatingTool.range }).background(curTool == .range ? .gray : .clear)
                Button("Split", systemImage: split,   action: {curTool = GatingTool.split }).background(curTool == .split ? .gray : .clear)
                Button("Radius", systemImage: "triangle.righthalf.fill",   action: {curTool = GatingTool.radius }).background(curTool == .radius ? .gray : .clear)
                Button("Rectangle", systemImage: "square.and.pencil",   action: { curTool = GatingTool.rectangle}).background(curTool == .rectangle ? .gray : .clear)
                Button("Ellipse", systemImage: "ellipsis.circle",   action: {curTool = GatingTool.ellipse }).background(curTool == .ellipse ? .gray : .clear)
                Spacer(minLength: 50)
                    //                Button("Quads", systemImage: "person.crop.square",   action: { curTool = GatingTool.quads})
                    //                Button("Polygon", systemImage: "skew",   action: { curTool = GatingTool.polygon})
                    //                Button("Spline", systemImage: "scribble",   action: {curTool = GatingTool.spline })
                NavArrows
            }
                //            .background(Color.gray.opacity(0.3))
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
    
    var  NavArrows: some View {
        @State var canGoUp = population?.parent != nil
        @State var canGoDown = false
        @State var canGoLeftRight = experiment.samples.count > 1
        let up = { toParent() }
        let down = { toChild() }
        let left = { prevSample() }
        let right = { nextSample() }
        
        return ZStack{
            let offset : CGFloat = 15.0
            Button("Up",    systemImage: iconName("up"), action: up).offset(off(0,-offset)).disabled(!canGoUp)
            Button("Down",  systemImage: iconName("down"), action: down).offset(off(0,offset)).disabled(!canGoDown)
            Button("Prev",  systemImage: iconName("left"), action: left).offset(off( -offset,0)).disabled(!canGoLeftRight)
            Button("Next",  systemImage: iconName("right"), action: right).offset(off( offset,0)).disabled(!canGoLeftRight)
        }
        func off(_ x: CGFloat, _ y: CGFloat) -> CGSize { CGSize(width: x, height: y) }
        func iconName(_ s: String) -> String { "arrowtriangle." + s + ".square.fill"}
    }
    
        //--------------------------------------------------------------------
    var body: some View {
        return VStack {
                //            Text("Gating Prototype")
            if let sample = population?.getSample(batchContext) {
                HStack {
                    Text("Sample: \(sample.tubeName), population: \((population?.name).nonNil)")
                    Button("Contours", action: toggleContours)
                    Button("Smoothing", action: toggleSmoothing)
                }
                if let meta = sample.meta {
                    if let population {
                        AncestryView(population, height:100)
                        chart(meta)
                    } else  {   Text("No population selected")   }
                } else      {   Text("Sample metadata not found")  }
            }  else         {   Text("Select a sample")  }
            
        }.toolbar {  GatingTools   }
    }
    
        //------------------------------------------------------
    
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
                focusedItem = nil  }
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
            .foregroundColor(.green)
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
        var outOfBounds:Bool = (location.x < 2 || location.y < 2 ||
                                location.x > size.width || location.y > size.height)
            //        print(location, size)
        return ZStack { dashedLine(
            from:CGPoint(x: location.x, y:0),
            to:CGPoint(x: location.x,  y: size.height))
            
            dashedLine(
                from:CGPoint(x: 0,      y: location.y),
                to:CGPoint(x: size.width, y: location.y))
            .opacity((curTool == .range) ? 0.0 : 1.0)
        }
        .fillAvailableSpace()
        .opacity((isDragging || outOfBounds) ? 0.0 : 0.5)
        .onHover(perform: { hovering in isHovering = true  })
        .onContinuousHover { phase in
            switch phase {
                case .active(let location):
                    mouseLocation = location
                    isHovering = true
                case .ended:
                    isHovering = false
                    outOfBounds = true
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
    
    
//------------------------------------------------------------------------
//------------------------------------------------------------------------
// Controller
    
    func nextSample() -> ()
    {
        if let population {
            experiment.nextSample(path: population.path())
        }
    }
    
    func prevSample() -> ()
    {
        if let population {
            experiment.prevSample(path: population.path())
        }
    }
    
    func toParent() -> ()
    {
        if let pop = population {
            if let parent = pop.parent {
                experiment.setAnalysisNodeSelection(parent)
            }
        }
    }
    
    func toChild() -> ()
    {
        if let pop = population {
            if let child = pop.children.first {
                experiment.setAnalysisNodeSelection(child)
            } }
        print ("TODO  toChild -- using first child, not selected")
    }
    
  //--------------------------------------------------------------------
    func toggleContours() {
        let contours = population!.chartDef.contours
        population!.chartDef.contours = contours ? false : true
    }
    func toggleSmoothing() {
        let smoothing = population!.chartDef.smoothing
        population!.chartDef.smoothing = smoothing == .off ? .low : .off
    }
    
   //--------------------------------------------------------------------

    
    func makeGate(_ start: CGPoint, _ location: CGPoint, areaPixelSize:CGSize)
    {
        let normalizers = axisNormalizers()
        
        let start = (start / areaPixelSize).invertedY().unnormalize(normalizers)
        let end = (location / areaPixelSize).invertedY().unnormalize(normalizers)
        
        let rect = CGRect(from:start, to:end)
        
        guard let xDim = chartDef?.xAxis?.dim else {
            print("No x axis for gate")
            return
        }
        
        switch curTool
        {
            case .range:        addRangeGate(xDim, rect.minX, rect.maxX); return
            case .split:        add2RangeGates(xDim, rect.maxX); return
            default: break
        }
        
        guard let yDim = chartDef?.yAxis?.dim else {
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
            case .radius:       addRadialGate(dims,  start, distance(start, location))
                    //            case .quads:        addQuadGates(gateName, start, location)
                    //            case .polygon:      addPolygonGate(gateName, start, location)
                    //            case .spline:       addSplineGate(gateName, start, location)
            default: break
        }
    }
    
    func addGate(_ gate: AnyGate)
    {
            //        self.candidateGateName = getCandidateGateName()
        let node = AnalysisNode(gate:gate)
        node.gate = gate
        node.name = "T Cells"                 // TBD - generatePopulationName
        confirmedGate = node
    }
    
    @MainActor
    func finalizeCandidateGate() {
        guard let population,
              let confirmedGate
        else {
            print("No population selected")
            return
        }
        confirmedGate.chartDef = population.chartDef     //TBD -  findUnusedParameters
        population.addChild(confirmedGate)
        experiment.selectedAnalysisNodes.nodes = [confirmedGate]
        self.confirmedGate = nil
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
        let gate = EllipsoidGateDef(dims,
                                    .init(vertex0: start.normalize(axes),
                                          vertex1: end.normalize(axes),
                                          widthRatio: 0.6),
                                    axes: axes)
        addGate(gate)
    }
}
