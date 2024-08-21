//
//  LayoutItemViews.swift
//  filereader
//
//  Created by Adam Treister on 8/14/24.
//

import SwiftUI
import Charts

    // wrap the model in a view that can be styled and dragged
struct LayoutItemWrappper: View, Identifiable {
    var parent: CGLayoutView
    var id = UUID()
    var item: LayoutItem
    let editableItem:Binding<LayoutItem?>
   @State var startPosition: CGPoint = .zero
    
    var body: some View
    {
        let displayOffset = item.position + item.tmpOffset
        let editing = editableItem.wrappedValue == item
        VStack {
            switch item {
                case let item as CText:
                    CTextView(parent: parent, item: item, editing: editing).background(.purple.opacity(0.8))
                case let item as CChart:
                    CChartView(parent: parent, item: item, editing: editing).background(.green.opacity(0.8))
                case let item as CTable:
                    CTableView(parent: parent, item: item, editing: editing).background(.orange.opacity(0.8))
                        //                case let item as LayoutItem:
                        //                    LayoutItemView(item: item)
                default:
                    Text("<Unknown layout item type")
            }
        }
        .allowsHitTesting(true)
        .position(displayOffset)
        .padding(15)
        .gesture(dragSelectedItems)
        .onTapGesture(count:2) {    self.editableItem.wrappedValue = item        }
        .onTapGesture(count:1) {     parent.layoutModel.selectItem(item)      }
        
     }

    var dragSelectedItems: some Gesture {
        DragGesture()
            .onChanged { info in
print("dragging")   // if starting and optionKey(), clone selection
                if startPosition == .zero && optionKey()
                {
                    startPosition = info.location
                    parent.layoutModel.cloneSelection()
                }
                item.tmpOffset = info.translation.asPoint
                if !item.selected && !anyModifiers() { parent.layoutModel.deselectAll() }
                item.selected = true;
                parent.layoutModel.setSelectedOffset(offset: item.tmpOffset)
            }
            .onEnded { info in
                parent.layoutModel.moveSelection(offset: item.tmpOffset)
                item.tmpOffset = .zero
            }
    }
}

//--------------------------------------------------------------------
// TEXTBOX

struct CTextView : View {
    var parent: CGLayoutView
    let item: CText
    let editing: Bool
        //    @State private var selection: TextSelection?          MacOS 15+
    
    var body: some View {
        let bindableText:Binding<String> = .init(get: { item.value }, set: { item.value = $0 } )
        
        VStack {
            if editing {
                TextField("Test Field", text: bindableText) .foregroundColor(.black)       //, selection: $selection
                    .font(.headline).background(.black.opacity(0.8  )).frame(width: 120)
            } else {
                Text(item.value)
            }
        }   .padding()
            //            .onTapGesture {  parent.selectItem( item)    }
            .font(.headline)
            .fontWidth(Font.Width(36))
            .foregroundColor(.white)
            .shadow(color: .black, radius: 3)
            .border(.red, width: item.selected ? 3.0 : 0.0 )
        
    }
}
    //--------------------------------------------------------------------
    // CHART

struct CChartView : View {
    var parent: CGLayoutView
    let item: CChart
    let editing: Bool
    
    @EnvironmentObject var core:CytegeistCoreAPI
    
    var body: some View {
            //        let bindableText:Binding<String> = .init(get: { item.value }, set: { item.value = $0 } )
        let sampleRef = SampleRef(url: DemoData.facsDivaSample0!)
        
        VStack {
            ChartView_Penguins()
//            HistogramView(data: core.histogram(sampleRef: sampleRef, parameterName: "FSC-A"))
                //            if editing {
                //                TextField("Test Field", text: bindableText) .foregroundColor(.black)       //, selection: $selection
                //                    .font(.headline).background(.black.opacity(0.8  )).frame(width: 120)
                //            } else {
            Text("Penguins")
            
        }  .frame(width: 100, height: 100)
            .padding()
            .onTapGesture {   parent.layoutModel.selectItem( item)    }
            .border(.red, width: item.selected ? 3.0 : 0.0 )
            .onAppear(perform:  {   item.size = CGSize(width: 120, height: 100) })
        
    }
}

    //--------------------------------------------------------------------
    // TABLE

struct CTableView : View {
    var parent: CGLayoutView
    let item: CTable
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
            }.frame(width: 180, height: 120)
                .border(.blue)
                .fontWidth(Font.Width(8))
                .allowsHitTesting(false)
                .clipShape(Rectangle())
                .border(.red, width: item.selected ? 3.0 : 0.0 )
        }
        .onAppear(perform:  {   item.position = CGPoint(x: 100, y: 200) })
        
        
    }
}
