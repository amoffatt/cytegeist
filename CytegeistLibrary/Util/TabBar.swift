//
//  TabBar.swift
//  CytegeistLibrary
//
//  Created by Adam Treister on 8/31/24.
//

import SwiftUI

public struct TabBar<TabItems, TabItemView>: View where TabItems:RandomAccessCollection, TabItems.Element:Hashable, TabItems.Element:Identifiable, TabItemView:View{
    public typealias TabItem = TabItems.Element
    let items: TabItems
    var selection:Binding<TabItem?>
    let height:CGFloat = 20
    let tabView: (TabItems.Element) -> TabItemView
    let add: () -> Void
    let remove: (TabItem) -> Void

    public init(_ items: TabItems, selection: Binding<TabItem?>, tabView: @escaping (TabItem) -> TabItemView, add: @escaping () -> Void, remove: @escaping (TabItem) -> Void) {
        self.items = items
        self.selection = selection
        self.tabView = tabView
        self.add = add
        self.remove = remove
    }

    public var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {      //
                    ForEach(items, id: \.self) { item in
                        let selected = selection.wrappedValue == item
                        let template = false  //  item.isTemplate
                        
                        Button {
                            selection.wrappedValue = item
                        } label: {  HStack {  tabView(item)   }   }
                            .buttonStyle(selected ? .plain : .plain)
//                        .buttonBorderShape(.capsule)
                        .padding(8)
                        .background(selected ? .blue.opacity(0.2) : .clear)
                        .font(.title2)
//                        .offset(y:(selected ? 6 : 0))

                    }
                }
            }
            Buttons.icon("Add Tab", .add) {  add()  }
            .buttonStyle(.plain)
            .padding(.horizontal)
            
            Buttons.icon("Close Tab", .delete) {
                if let selected = selection.wrappedValue {
                    let index = items.firstIndex { $0 == selected }
                    remove(selected)
                    
                    // Note: item hasn't yet been removed yet from this View's items list
                    if items.count <= 1 {
                        add()
                    } else {
                        if let index {
                            let selectIndex = items.indices.last == index 
                            ? items.index(before: index)
                            : items.index(after: index)
                            selection.wrappedValue = items.get(index: selectIndex)
                        } else {
                            print("Index of item to be deleted not found")
                        }
                    }
                }
            }
            .disabled(selection.wrappedValue == nil)
            .buttonStyle(.plain)
            .padding(.horizontal)


        }
        .frame(height: height)
        
    }
}

extension String: Identifiable {
    public var id: String { self }
}


struct TabBarTest : View {
    @State var selected:String? = ""
    @State var tabs = (0...10).map { "Tab \($0)" }
    
    var body: some View {
         
        return VStack {
            TabBar(tabs, selection: $selected) { item in
                Text(item)
            } add: {
                tabs.append("\(Int.random(in: 100...200))")
            } remove: { item in
                tabs.removeAll { $0 == item }
            }
            VStack {
                Text("Selected tab: \(String(describing: selected))")
            }
            .fillAvailableSpace()
            .background(.blue.opacity(0.15))
        }
    }
}


#Preview {
    TabBarTest()
}
