//
//  CGLayoutModel.swift
//
//
import SwiftUI
import Charts
import CytegeistLibrary
import CytegeistCore
import SwiftData
import Combine

public class TestItem : CNamedObject {
    
    @Published public var items = [LayoutItem]()
    
//    override init() {
//        
//    }
}

public class CGLayout : CNamedObject
{
    @Published public var items = [LayoutItem]()
    var attribs = Dictionary<String, String> ()
        //    var info = BatchInfo()
        //-------------------------------------------------------------
        // adding items
    
    func addItem(_ item:LayoutItem) {
        items.append(item)
    }
    
    public func addTextItem() -> ()
    {
        if !optionKey() { deselectAll()  }
        newTextItem(name: "some text", position: CGPoint.zero)
    }
    
    public func newTextItem(name: String, position:CGPoint)
    {
        let layoutItem = CText(value: name)
        layoutItem.selected = true
        addItem(layoutItem)
    }
    
    public func addTable() -> ()
    {
        if !optionKey() { deselectAll()  }
        newTable(name: "some table", position: CGPoint.zero)
    }
    
    public func newTable(name: String, position:CGPoint)
    {
        let item = CTable(position: position)
        item.selected = true
        addItem(item)
    }
        //---------------------------------------------------------------------------
        // manage the selection
    
    func deselectAll() -> ()  {
        for item in items    { item.selected = false    }
    }
    func selectAll() -> ()   {
        for item in items   {  item.selected = true   }
    }
    
    func selectItem(_  newSel: LayoutItem) -> ()   {
        if !anyModifiers() { deselectAll() }
        newSel.selected = true
    }
    func deleteSelection() -> ()       {
        items.removeAll (where:  { $0.selected } )
    }
    func moveSelection( offset: CGPoint) -> ()   {
        for item in items where { item.selected }()   {
            item.position = item.position + item.tmpOffset
            item.tmpOffset = .zero
        }
    }
    func nudgeSelection( offset: CGPoint) -> ()
    {
        for item in items where { item.selected }()  {
            item.position = item.position + offset
        }
    }
    public func selectRect(marquee: CGRect)
    {
        for item in items   {
            item.selected = sectRect(pt: item.position, size: item.size, rect: marquee)
        }
    }
    
    public func sectRect(pt: CGPoint, size: CGSize, rect: CGRect) -> Bool
    {
        let halfHght = (size.height / 2), halfWidth = (size.width / 2)
        let topLeft = CGPoint(pt.x - halfHght, pt.y - halfWidth)
        if ptInRect(pt: topLeft, rect: rect) {  return true  }
        let bottomRight = CGPoint(pt.x + halfHght, pt.y + halfWidth)
        if ptInRect(pt: bottomRight, rect: rect) {  return true  }
        return  ptInRect(pt: pt, rect: rect)
    }
    
    func setSelectedOffset( offset: CGPoint)
    {
        for item in items where { item.selected }()  {
            item.tmpOffset = offset
        }
    }
    
    func cloneSelection() -> ()
    {
        for item in items where { item.selected }()  {
            let newItem = item.clone()
            items.insert(newItem, at: 0)
        }
    }
    
    func bringToFront() -> ()
    {
        for index in (0..<items.count).reversed()   {
            if items[index].selected   {
                let item = items.remove(at: index)
                items.insert(item, at: 0)
            }
        }
    }
    
    func sendToBack() -> ()
    {
        for index in (0..<items.count).reversed()   {
            if items[index].selected    {
                let item = items.remove(at: index)
                items.append(item)
            }
        }
    }
}
//---------------------------------------------------------------------
// base class for CText, CTable, CChart

public class LayoutItem: CObject
{
    @Published var size = CGSize.zero
    @Published var position = CGPoint.zero
    @Published var tmpOffset = CGPoint.zero
// save scale, rotation, background, stroke, etc
    
    @Published var selected:Bool = false
    @Published private(set) var node:AnalysisNode?
//
    var name:String {
        get { node != nil ? node!.name : "n/a"}
        set { if node != nil { node!.name = newValue }}
    }
    
    convenience init(position: CGPoint, node: AnalysisNode? = nil, size: CGSize = .zero, tmpOffset: CGPoint = .zero) {
        self.init()
        self.node = node
        self.position = position
        self.size = size
        self.tmpOffset = tmpOffset
    }

//    override public func clone() -> Self
//    {
//        LayoutItem(position: self.position, node: self.node,
//                   size: self.size, tmpOffset: self.tmpOffset)
//    }
}


//---------------------------------------------------------------------
public class CText: LayoutItem {
    @Published var value: String = ""
    
//    convenience init(value: String) {
//        self.init()
//        self.value = value
////        wuper.init(position: CGPoint(x: 200, y: 200))
//    }
    
    
    convenience init(value: String, position: CGPoint = .zero) {
        self.init(position: position)
        self.value = value
   }
    
//    override public func clone() -> Self    {
//        var c:Self = .init(value: value, position: position)
//        return c
//   }

}
    //---------------------------------------------------------------------

//@Observable
class CChart : LayoutItem
{
    var xAxis: AxisNormalizer?
    var yAxis: AxisNormalizer?

   
    convenience init(xAxis: AxisNormalizer?, yAxis: AxisNormalizer?
         , position:CGPoint = .zero, node: AnalysisNode?) {
        self.init(position: position, node: node)

        self.xAxis = xAxis;
        self.yAxis = yAxis;
    }
    
//    required init() {
//    }
    
//    init(node: AnalysisNode, position:CGPoint = .zero) {
//        super.init(position: position, node: node )
//    }
    
    
//    required init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
    
//    override public func clone() -> CChart
//    {
//        return .init(xAxis: xAxis, yAxis: yAxis, position: position, node: node)
//    }

}
//---------------------------------------------------------------------

class CTable : LayoutItem
{
    var data: Data? = nil
    convenience init(data: Data?) {
        self.init()
        self.data = data
    }
    
//    convenience init(data: Data? = nil)
//    {
////        self.init(position: position, node: node )
//        self.data = data
//    }
//
//    required init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
    
//    override public func clone() -> CTable
//    {
//        return .init(data: data, position: position, node: node)
//    }

}
