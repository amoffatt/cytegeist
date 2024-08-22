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


struct GatingView: View {

    @State private var mode = ReportMode.gating
    @State var curTool = GatingTool.range
    @State private var isDragging = false
 
    @State public var startLocation = CGPoint.zero
    @State public var mouseLocation = CGPoint.zero
    @State public var mouseTranslation = CGPoint.zero
    @State private var isHovering = false
    @State private var offset = CGSize.zero
//    @State var population: AnalysisNode
    @State var sample: Sample? = nil
    @State var chartDef: ChartDef = ChartDef()
    


//    var selectedSample: Sample
    var chart: some View {
        VStack {
            if let sampleRef = sample?.ref {
                ChartView(population: PopulationRequest(sampleRef), config: chartDef)
            }
            else {
                Text("No sample file reference")
            }
//            Chart()
//            {
////                PointMark(
////                    x: .value("Wing Length", $0.wingLength),
////                    y: .value("Wing Width", $0.wingWidth)
////                )
////                .symbol(by: .value("Family", $0.family))
////                .shadow(color: .blue, radius: 5, x:0, y:0)
//            }
//            .overlay { proxy in
//                GeometryReader { proxy in
//                    ZStack(alignment: .topLeading){
//                        
//                        gateRadius(siz: proxy.size)
//                        gateRange(siz: proxy.size)
//                        gateRect(siz: proxy.size)
//                        gateEllipse(siz: proxy.size)
//                        crosshair(location: mouseLocation, size: proxy.size )
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                            .gesture(gateDrag)
//                    }
//                }
//            }
//            .padding(40)
//            .allowsHitTesting(true)
//            .opacity(mode == ReportMode.gating ? 1.0 : 0.0)
        }
        
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
        Text("GatingView")
        Group{
//            Text("Gating Prototype")
            chart

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
var gateDrag: some Gesture {
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
            startLocation = CGPoint.zero
            mouseLocation = CGPoint.zero
        }
}
let DEBUG = false
    //------------------------------------------------------
    // we need the size of the parent View to offset ourself
    func gateRect(siz: CGSize ) -> some View {
        let start = startLocation.x
        let end = mouseLocation.x
        let startY = startLocation.y
        let endY = mouseLocation.y
        let width =  end - start
        let height = endY - startY
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
        let translation = mouseLocation - startLocation
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
