//
//  LayoutItemViews.swift
//  filereader
//
//  Created by Adam Treister on 8/14/24.
//

import SwiftUI
import Charts
import CytegeistCore
import CytegeistLibrary

    // wrap the model in a view that can be styled and dragged
struct LayoutItemWrappper: View, Identifiable {
    var parent: CGLayoutView
    var id = UUID()
    var item: LayoutItem
    let editableItem:Binding<LayoutItem?>
   @State var dragStartPosition: CGPoint? = nil
    
    var body: some View
    {
        let editing = editableItem.wrappedValue == item
        ZStack(alignment:.topLeading) {
            VStack {
                switch item.type {
                    case .text:   CTextView(parent: parent, item: item, editing: editing).background(.purple.opacity(0.3))
                    case .chart:  CChartView(parent: parent, item: item, editing: editing).background(.green.opacity(0.2))
                    case .table:  CTableView(parent: parent, item: item, editing: editing).background(.blue.opacity(0.2))
                    case .image:  CImageView(parent: parent, item: item, editing: editing).background(.brown.opacity(0.2))
                    case .group:  CGroupView(parent: parent, item: item, editing: editing).background(.pink.opacity(0.2))
                }
            }
            .shadow(color: .black, radius: 3)
            .border(.red, width: item.selected ? 3.0 : 0.0 )

            GateControlZone("lower-right", position: item.size.asPoint) { position, ended in
                print("Move to position: \(position)")
                item.size = position.asSize
            } handle: { state in
                CircleHandle(solid:false)
            }
        }
        .environment(\.isEditing, item.selected)
        .allowsHitTesting(true)
        .frame(width: item.size.width, height: item.size.height)
        .position(item.currentCenterPosition)
//        .padding(15)
        .gesture(dragSelectedItems)
        .onTapGesture(count:2) {    self.editableItem.wrappedValue = item        }
        .onTapGesture(count:1) {     parent.layoutModel.selectItem(item)      }
        
     }

    var dragSelectedItems: some Gesture {
        DragGesture()
            .onChanged { info in
                if dragStartPosition == nil && optionKey()  {
                    parent.layoutModel.cloneSelection()
                }
                dragStartPosition = info.location
                item.tmpOffset = info.translation.asPoint
                if !item.selected && !anyModifiers() { parent.layoutModel.deselectAll() }
                item.selected = true;
                parent.layoutModel.setSelectedOffset(offset: item.tmpOffset)
            }
            .onEnded { info in
                parent.layoutModel.moveSelection(offset: item.tmpOffset)
                item.tmpOffset = .zero
                dragStartPosition = nil
            }
    }
}

//--------------------------------------------------------------------
// TEXT

struct CTextView : View {
    var parent: CGLayoutView
    let item: LayoutItem
    let editing: Bool
        //    @State private var selection: TextSelection?          MacOS 15+
    
    var body: some View {
        let bindableText:Binding<String> = .init(get: {
            if case .text(let value) = item.type {
                return value
            }
            return ""
        }, set: {
            item.type = .text($0)
        } )
        
        VStack {
            if editing {
                TextEditor(text: bindableText)
                   .foregroundColor(.black)       //, selection: $selection
                   .font(.body)
                   .multilineTextAlignment(.leading)
            } else {
                Text(bindableText.wrappedValue)
            }
        }
            //            .onTapGesture {  parent.selectItem( item)    }
            .fillAvailableSpace()
            .font(.headline)
            .fontWidth(Font.Width(36))
            .foregroundColor(.white)
        
    }
}
//--------------------------------------------------------------------
// CHART
//        let bindableText:Binding<String> = .init(get: { item.value }, set: { item.value = $0 } )

struct CChartView : View {
    var parent: CGLayoutView
    let item: LayoutItem
    let editing: Bool
    
    @Environment(CytegeistCoreAPI.self) var core:CytegeistCoreAPI
    
    var body: some View {
        let chartDefBinding:Binding<ChartDef?> = .init {
            item.node?.chartDef
        } set: {
            if let chartDef = $0 {
                item.node?.chartDef = chartDef
            }
        }
        
        VStack {
            ChartView(population: item.node, config: chartDefBinding, editable: true, focusedItem: nil)
                .padding(4)
                .background(.black.opacity(0.1))
                .cornerRadius(8)
        }
            .onTapGesture {   parent.layoutModel.selectItem( item)    }
            .onAppear(perform:  {   item.size = CGSize(width: 120, height: 100) })
        
    }
}

    //--------------------------------------------------------------------
    // IMAGE

struct CImageView : View {
    var parent: CGLayoutView
    let item: LayoutItem
    let editing: Bool
    
    var body: some View {
        VStack {
            Text("Image goes here")
        }
        .onTapGesture {   parent.layoutModel.selectItem( item)    }
        .onAppear(perform:  {   item.position = CGPoint(x: 300, y: 200) })
        
    }
    
}
    //--------------------------------------------------------------------
    // TABLE

struct CTableView : View {
    var parent: CGLayoutView
    let item: LayoutItem
    let editing: Bool
    @State var columnCustomization = TableColumnCustomization<User>()
    @State var selection = Set<User.ID>()
    @State var sortOrders = [KeyPathComparator(\User.name, order: .forward), KeyPathComparator(\User.score, order: .forward)]
    
    var body: some View {
        VStack {
            Table(selection: $selection, sortOrder: $sortOrders,  columnCustomization: $columnCustomization)
            {
                TableColumn("Marker", value:\.marker){ user in Text(user.marker)  }.customizationID("marker")
                TableColumn("Score", value:\.score) { user in Text(String(user.score))  }.customizationID("score")
                TableColumn("Number", value:\.number){ user in Text(String(user.number))  }.customizationID("number")
            }
        rows:
            {
                ForEach(users) { user in TableRow(user)  }
            }
                .fontWidth(Font.Width(8))
                .allowsHitTesting(false)
                .clipShape(Rectangle())
        }
        .onAppear(perform:  {   item.position = CGPoint(x: 100, y: 200) })
    }
    public  struct User: Identifiable {
        public var id: Int
        var name: String
        var score: Int
        var number: Double
        var marker: String
    }
    
    @State private var  users = [
        User(id: 1, name: "Taylor", score: 95, number: 9.32, marker: "CD34"),
        User(id: 2, name: "Justin", score: 80, number: Double.pi, marker: "CD3"),
        User(id: 3, name: "Adkins", score: 84, number: 9.32e4, marker: "CD4"),
        User(id: 4, name: "Bob", score: 94, number: 0.32, marker: "CD44-39"),
        User(id: 5, name: "Ted", score: 82, number: 92, marker: "CD44-8")]
}

 
 
    //--------------------------------------------------------------------
    // GROUP

struct CGroupView : View {
    var parent: CGLayoutView
    let item: LayoutItem
    let editing: Bool
    
    var body: some View {
        VStack {
            Text("Group goes here")
        }
            .onTapGesture {   parent.layoutModel.selectItem( item)    }
            .onAppear(perform:  {   item.position = CGPoint(x: 300, y: 200) })
    }
}
///-------------------------------------------------------------------------

