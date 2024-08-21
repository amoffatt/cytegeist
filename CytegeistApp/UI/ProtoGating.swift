//
//  ProtoGating.swift
//  filereader
//
//  Created by Adam Treister on 7/26/24.
//

import SwiftUI

struct ProtoGating: View {
    
    @State public var startLocation = CGPoint.zero
    @State public var mouseLocation = CGPoint.zero
    @State public var mouseTranslation = CGPoint.zero
    @State private var isHovering = false
    @State public var isDragging = false
    @State var viewState = CGSize.zero
    @State private var offset = CGSize.zero
    
    @State var currentTool = "Rectangle"
    var tools = ["None","Bifurcate","Range","Rectangle","Ellipse", "Polygon", "Spline" ]
    var icons = ["None","triangle.righthalf.fill","pencil","square.and.pencil","ellipsis.circle", "skew", "scribble" ]

//    @State private var buttons: [Button] = [ (tools, icons)
//    ].map { Button(id: UUID(), name: $0, icon: $1) }
    
    var body: some View    {
                VStack  {
                    HStack{
                        
                    Text("An example of range, rectangle, and ellipse gate dragging")
                        .frame(maxHeight: 40)
                        .toolbar {
                                ToolbarItem(placement: .automatic) {
                                    Button(tools[2], systemImage: icons[2]) {  currentTool = tools[2]  }
                                }
                                ToolbarItem(placement: .automatic) {
                                    Button(tools[3], systemImage: icons[3]) {  currentTool = tools[3]   }
                                }
                                ToolbarItem(placement: .automatic) {
                                    Button(tools[4], systemImage: icons[4]) {  currentTool = tools[4]   }
                                }
                            }
                       Spacer()
                        Text(currentTool)
                    }.padding(8)
                    GeometryReader { proxy in
                      ZStack{
                           
                                 gateRange(siz: proxy.size)
                                         .offset(x: viewState.width, y: viewState.height)
                                 gateRect(siz: proxy.size)
                                         .offset(x: viewState.width, y: viewState.height)
                                 gateEllipse(siz: proxy.size)
                                 crosshair(location: mouseLocation, size: proxy.size )
                                         .frame(maxWidth: .infinity, maxHeight: .infinity)
                                         .offset(x: viewState.width, y: viewState.height)
                                         .gesture(gateDrag)
                       
                                 }
                   
                }.background(.blue) .padding(36)
                }.background(.white)
            }
        //------------------------------------------------------
    
    var drag: some Gesture {
        DragGesture()
            .onChanged { _ in self.isDragging = true }
            .onEnded { _ in self.isDragging = false }
    }
    var gateDrag: some Gesture {
        DragGesture()
            .onChanged { value in offset = value.translation
                isDragging = true
                print(offset)
                startLocation = value.location
                mouseLocation = value.location
                mouseTranslation = CGPoint( x:offset.width, y: offset.height)
                
            }
            .onEnded { value in
                    //                 withAnimation(.spring()) {
                isDragging = false
                viewState = .zero
                startLocation = CGPoint.zero
                mouseLocation = CGPoint.zero
                    //                 }
            }
    }
    let DEBUG = false
        //------------------------------------------------------
        // we need the size of the parent View to offset ourself
    func gateRect(siz: CGSize ) -> some View {
        Rectangle()
            .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
            .foregroundColor(.red)
            .opacity(DEBUG || (isDragging && (currentTool == "Rectangle")) ? 1.0 : 0.0)
            .offset(x: startLocation.x-siz.width/2, y: startLocation.y-siz.height/2)
            .offset(x:-mouseTranslation.x/2, y: -mouseTranslation.y/2)
            .frame(maxWidth: abs(mouseTranslation.x),
                   maxHeight: abs(mouseTranslation.y),
                   alignment: Alignment.center)         // DOESNT SEEM TO MATTER
            .allowsHitTesting(false)
    }
    
    func gateRange(siz: CGSize ) -> some View {
        Rectangle()
            .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
            .foregroundColor(.yellow)
            .opacity(DEBUG || (isDragging && (currentTool == "Range")) ? 1.0 : 0.0)
            .offset(x: startLocation.x-siz.width/2, y: 0.0)
            .offset(x:-mouseTranslation.x/2, y: 0.0)
            .frame(maxWidth: abs(mouseTranslation.x),
                   minHeight: siz.height,
                   maxHeight: siz.height,
                   alignment: Alignment.center)         // DOESNT SEEM TO MATTER
            .allowsHitTesting(false)
    }
    
    func gateEllipse(siz: CGSize ) -> some View {
        Ellipse()
            .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
            .foregroundColor(.green)
            .opacity(DEBUG || (isDragging && currentTool == "Ellipse")  ? 1.0 : 0.0)
            .offset(x: startLocation.x-siz.width/2, y: startLocation.y-siz.height/2)
            .offset(x:-mouseTranslation.x/2, y: -mouseTranslation.y/2)
            .frame(maxWidth: abs(mouseTranslation.x),
                   maxHeight: abs(mouseTranslation.y),
                   alignment: Alignment.center)         // DOESNT SEEM TO MATTER
            .allowsHitTesting(false)
    }
        //------------------------------------------------------
    func crosshair(location: CGPoint, size:CGSize) -> some View
    {
        ZStack { dashedLine(
            from:CGPoint(x: location.x, y:0),
            to:CGPoint(x: location.x,  y: size.height))
            
            dashedLine(
                from:CGPoint(x: 0,      y: location.y),
                to:CGPoint(x: size.width, y: location.y))
            .opacity((currentTool == "Range") ? 0.0 : 1.0)
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


