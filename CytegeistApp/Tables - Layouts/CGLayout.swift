//
//  CGLayoutModel.swift
//
//
import SwiftUI
import Charts
import CytegeistLibrary
import CytegeistCore

@Observable
class CGLayout : Codable, Hashable, Identifiable
{
    static func == (lhs: CGLayout, rhs: CGLayout) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID()
    var name = "Untitled Layout"
    
    var items = [LayoutItem]()
    var attribs = Dictionary<String, String> ()
        //    var info = BatchInfo()
    
    init() {
    }
    
    init(_ xml: TreeNode)
    {
        
    }
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
        let layoutItem = LayoutItem(value: name)
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
        let item = LayoutItem(position: position, type: .table)
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

enum ELayoutType : Codable {
    case text
    case chart
    case table
}

@Observable
public class LayoutItem: Codable, Identifiable, Equatable
{
    public static func == (lhs: LayoutItem, rhs: LayoutItem) -> Bool {   lhs.id == rhs.id  }
    public private(set) var id = UUID()
    var size: CGSize = .zero
    var position: CGPoint = .zero
    var tmpOffset: CGPoint = .zero
    var type: ELayoutType = .text
    var value: String = ""
    var xAxis: AxisNormalizer?
    var yAxis: AxisNormalizer?
    var data: Data?

// save scale, rotation, background, stroke, etc
    
    var selected:Bool = false
    private(set) var node:AnalysisNode?
//
    var name:String {
        get { node != nil ? node!.name : "n/a"}
        set { if node != nil { node!.name = newValue }}
    }
    
    
    //public
    init(position: CGPoint, node: AnalysisNode?) {
        self.node = node
        self.position = position
    }
    
    init(position: CGPoint, type: ELayoutType) {
        self.position = position
        self.type = type
        
    }
    init(value: String) {
        self.value = value
        self.type = .text
        
    }
    
    init(position: CGPoint, type: ELayoutType, node: AnalysisNode?, size: CGSize, tmpOffset: CGPoint) {
        self.node = node
        self.position = position
        self.type = type
        self.size = size
        self.tmpOffset = tmpOffset
    }

    convenience init(data: Data?) {
        self.init(position: CGPoint.zero, node: nil )
         self.data = data
      }

    
     public required init(from decoder: any Decoder) throws {
        
        fatalError("init(from:) has not been implemented")
    }
    
    public func clone() -> LayoutItem
    {
        LayoutItem(position: self.position, type: self.type, node: self.node,
                   size: self.size, tmpOffset: self.tmpOffset)
    }

}


//---------------------------------------------------------------------
//@Observable
//public class CText: LayoutItem {
//    var value: String = ""
//    
//    init(value: String) {
//        self.value = value
//        super.init(position: CGPoint(x: 200, y: 200), node: nil )
//    }
//    
//    
//    init(value: String, position: CGPoint) {
//        super.init(position: position, node: nil )
//        self.value = value
//   }
//
//    public  required init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//    
//    override public func clone() -> CText    {
//        return .init(value: value, position: position)
//   }
//
//}
    //---------------------------------------------------------------------

//@Observable
//class CChart : LayoutItem
//{
//    var xAxis: AxisNormalizer?
//    var yAxis: AxisNormalizer?
//
//    init() {
//        super.init(position: CGPoint.zero, node: nil )
//    }
//   
//    init(xAxis: AxisNormalizer?, yAxis: AxisNormalizer?
//         , position:CGPoint = .zero, node: AnalysisNode?) {
// 
//        self.xAxis = xAxis;
//        self.yAxis = yAxis;
//        super.init(position: position, node: node )
// 
//    }
//    
//    init(node: AnalysisNode, position:CGPoint = .zero) {
//        super.init(position: position, node: node )
//    }
//    
//    
//    required init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//    
//    override public func clone() -> CChart
//    {
//        return .init(xAxis: xAxis, yAxis: yAxis, position: position, node: node)
//    }
//
//}
//---------------------------------------------------------------------
//
//@Observable
//class CTable : LayoutItem
//{
//    var data: Data?      
//    init(position: CGPoint) {
//        self.data = nil
//        super.init(position: CGPoint.zero, node: nil )
//    }
//    init(data: Data?) {
//        super.init(position: CGPoint.zero, node: nil )
//        self.data = data
//    }
//    
//    init(data: Data?, position: CGPoint, node: AnalysisNode?)
//    {
//        super.init(position: position, node: node )
//       self.data = data
//    }
//
//    required init(from decoder: any Decoder) throws {
//        fatalError("init(from:) has not been implemented")
//    }
//    
//    override public func clone() -> CTable
//    {
//        return .init(data: data, position: position, node: node)
//    }
//
//}
