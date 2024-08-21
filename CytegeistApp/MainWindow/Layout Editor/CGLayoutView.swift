//
//  FruitView.swift
//  filereader
//
//  Created by Adam Treister on 7/31/24.
//

import SwiftUI
import UniformTypeIdentifiers.UTType
import Combine
import SwiftData
    
    
//  https://gist.github.com/tarasis/f9bac6d98de5433f1ddbadaef02f9a29
// https://swiftui-lab.com/drag-drop-with-swiftui/
//https://www.codecademy.com/resources/docs/swiftui/drag-and-drop

extension UTType {
    static var fruit = UTType(exportedAs: "com.cytegeist.fruit")
    static var population = UTType(exportedAs: "cytegeist.population")
}

//---------------------------------------------------------------------------
// MAIN VIEW

@MainActor
struct CGLayoutView: View {
    let layoutModel:CGLayoutModel = CGLayoutModel()
//    let container = try ModelContainer(for: Store.self, layoutModel)
//    container.mainContext.undoManager = UndoManager()
    
    @Environment(\.undoManager) var undoManager
        // Should come from the workspace
    @State var core:CytegeistCoreAPI = CytegeistCoreAPI()
    
    @State var editingItem:LayoutItem?
    @FocusState private var isFocused: Bool
    @State  var mouseLocation = CGPoint.zero
    @State  var size: CGFloat = 1.0
    @State private var isMouseHoveringBackdrop = false
    @State var dragValue:DragGesture.Value? = nil
    @State var viewportSize:CGSize = .zero

     //---------------------------------------------------------------------------
     
    var body: some View {
        
        let step =  shiftKey() ? 20 : optionKey() ? 1 : 5
            VStack {
                 ZStack(alignment:.topLeading) {
                     layoutBackdrop()
                     ForEach(layoutModel.items) { item in
                         LayoutItemWrappper(parent: self, item:item, editableItem:$editingItem )
                     }
                     layoutOverlay()

                } .fillAvailableSpace()
                    .scrollClipDisabled()
                    .scaleEffect( $size.wrappedValue)
                    .background(.blue.opacity(0.1))
//                }

                HStack {
                    Spacer()
                    Button("Add Text Block", systemImage: "plus", action:  layoutModel.addTextItem  )
                    Button("Add Table", systemImage: "plus", action:  layoutModel.addTable  )
                    ItemSizeSlider(size: $size)
                }
            } .fillAvailableSpace()
                .focusable()
                .focusEffectDisabled(true)
                .onKeyPress(.return)        {  print("Return key pressed!");   return .handled    }
                .onKeyPress(.deleteForward) {  layoutModel.deleteSelection();  return .handled}
                .onKeyPress(.delete)        {  layoutModel.deleteSelection();   return .handled   }         // .delete DOESNT WORK
                .onKeyPress(.init(Character(UnicodeScalar(127))))      {  layoutModel.deleteSelection();   return .handled   }         // .delete DOESNT WORK
                .onKeyPress(.leftArrow)     {  layoutModel.nudgeSelection(offset: CGPoint(x: -step, y: 0)); return .handled     }
                .onKeyPress(.rightArrow)    {  layoutModel.nudgeSelection(offset: CGPoint(x: step, y: 0)) ; return .handled     }
                .onKeyPress(.upArrow)       {  layoutModel.nudgeSelection(offset: CGPoint(x: 0, y: -step)); return .handled     }
                .onKeyPress(.downArrow)     {  layoutModel.nudgeSelection(offset: CGPoint(x: 0, y: step));  return .handled     }
            
                .background(.blue.opacity(0.1))       // Needed to received clicks
                .dropDestination(for: AnalysisNode.self) { (items, position) in
                    for item in items { newChartItem(node: item, position:position)  }
                    return true
                }
                .onTapGesture {
                    editingItem = nil
                    layoutModel.deselectAll()
                }
                .onAppear {
                    layoutModel.addItem( CText(value: "new text item!"))
                    isFocused = true
                }
                .environmentObject(CytegeistCoreAPI())
    }
    
    func layoutBackdrop() -> some View {
        GeometryReader { proxy in
            ZStack {}
                .fillAvailableSpace()
                .contentShape(Rectangle())
                .gesture(selectionDrag)            //   SELECTION DRAG
                .onHover(perform: { hovering in isMouseHoveringBackdrop = true  })
                .onContinuousHover { phase in
                    switch phase {
                        case .active(let location):
                            mouseLocation = location
                            isMouseHoveringBackdrop = true
                        case .ended:
                            isMouseHoveringBackdrop = false
                            break
                    }
                }
                .onChange(of:proxy.size) { _, newSize in
                    viewportSize = newSize
                }
        }
    }
    
    func layoutOverlay() -> some View {
        ZStack(alignment:.topLeading) {
            selectionRectangle()
            crosshair()             // <-------
        }                    
        .fillAvailableSpace()
    }
    
    
    
    
    func newChartItem(node:AnalysisNode, position:CGPoint)
    {
        print("new layout item: ", node.name)
        let layoutItem = CChart(node:node, position:position)
        layoutModel.addItem(layoutItem)
    }
    
   //------------------------------------------------------
        
        struct ItemSizeSlider: View {
            @Binding var size: CGFloat
            
            var body: some View {
                Slider(value: $size, in: 0.125...4)
                    .controlSize(.regular)
                    .frame(width: 150, height: 40)
                    .frame(maxWidth: .infinity)
            }
        }

        func selectionRectangle() -> some View {
            ZStack {
                if let dragValue {
                    let startLocation = dragValue.startLocation
                    let translation = dragValue.translation
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1.8, dash: [15, 5]))
                        .foregroundColor(.red)
//                        .opacity(isDragging ? 1.0 : 0.0)
                        .offset(x: startLocation.x, y: startLocation.y)
                        //                .offset(x:-mouseTranslation.x/2, y: -mouseTranslation.y/2)
                        .offset(x:          min(translation.width,0),  y: min(translation.height, 0) )
                        .frame(maxWidth:     abs(translation.width),    maxHeight: abs(translation.height),
                               alignment: Alignment.center)         // DOESNT SEEM TO MATTER
                        .allowsHitTesting(false)
                }
            }
        }

    func crosshair() -> some View
    {
        let location = mouseLocation
        return ZStack { dashedLine(
            from:CGPoint(x: location.x, y:0),
            to:CGPoint(x: location.x,  y: viewportSize.height))
            
            dashedLine(
                from:CGPoint(x: 0,      y: location.y),
                to:CGPoint(x: viewportSize.width-20, y: location.y))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(dragValue == nil && isMouseHoveringBackdrop ? 0.25 : 0.0)
        .allowsHitTesting(false)
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

    
    var selectionDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                dragValue = value
                layoutModel.selectRect(marquee: pts2Rect(value.startLocation, value.location))
            }
            .onEnded { value in
                dragValue = nil
            }
    }
}


  
