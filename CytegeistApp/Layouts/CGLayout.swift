//
//  CGLayoutModel.swift
//
//
import SwiftUI
import Charts
import CytegeistLibrary
import CytegeistCore

@Observable
class CGLayoutModel : Codable, Hashable, Identifiable
{
    static func == (lhs: CGLayoutModel, rhs: CGLayoutModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID()
    var name = "Untitled Layout"
    
    var items = [LayoutItem]()
    var attribs = Dictionary<String, String> ()
    var info = BatchInfo()
 
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
       deselectAll()
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
        deselectAll()
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
    
    func deselectAll() -> ()
    {
        for item in items  {    item.selected = false      }
    }
    func selectAll() -> ()
    {
        for item in items   {          item.selected = true      }
    }
    func selectItem(_  newSel: LayoutItem) -> ()
    {
        let opt = NSEvent.modifierFlags.contains(.option)
        let cmd = NSEvent.modifierFlags.contains(.command)
        let sht = NSEvent.modifierFlags.contains(.shift)
        let anyMods = opt || cmd || sht
        if !anyMods { deselectAll() }
        newSel.selected = true
        
            //        for item in layoutModel.items       {          item.selected = (item.id == newSel.id)      }
    }
    func deleteSelection() -> ()
    {
        items.removeAll (where:  { $0.selected } )
    }
    func moveSelection( offset: CGPoint) -> ()
    {
        for item in items where { item.selected }()
        {
            item.position = item.position + item.tmpOffset
            item.tmpOffset = .zero
        }
    }
    func nudgeSelection( offset: CGPoint) -> ()
    {
        for item in items where { item.selected }()
        {
            item.position = item.position + offset
        }
    }
    public func selectRect(marquee: CGRect)
    {
        for item in items
        {
            item.selected = ptInRect(pt: item.position, rect: marquee)
        }
    }
    func setSelectedOffset( offset: CGPoint) -> ()
    {
        for item in items where { item.selected }()
        {
            item.tmpOffset = offset
        }
    }
    func cloneSelection() -> ()
    {
        for item in items where { item.selected }()
        {
            let newItem = item.clone()
            items.insert(newItem, at: 0)
        }

    }
    
    
    func bringToFront() -> ()
    {
        for index in (0..<items.count).reversed()
        {
            if items[index].selected
            {
                let item = items.remove(at: index)
                items.insert(item, at: 0)
            }
        }
    }
    func sendToBack() -> ()
    {
        for index in (0..<items.count).reversed()
        {
            if items[index].selected
            {
                let item = items.remove(at: index)
                items.append(item)
            }
        }
    }
}
//---------------------------------------------------------------------
// base class for CText, CTable, CChart

@Observable
public class LayoutItem: Codable, Identifiable, Equatable
{
    public static func == (lhs: LayoutItem, rhs: LayoutItem) -> Bool {   lhs.id == rhs.id  }
    public private(set) var id = UUID()
    var size: CGSize = .zero
    var position: CGPoint = .zero
    var tmpOffset: CGPoint = .zero
// save scale, rotation, background, stroke, etc
    
    var selected:Bool = false
    private(set) var node:AnalysisNode?
//
    var name:String {
        get { node != nil ? node!.name : ""}
        set { if node != nil { node!.name = newValue }}
    }
    
    
    //public
    init(position: CGPoint, node: AnalysisNode?) {
        self.node = node
        self.position = position
    }
    
    init(position: CGPoint, node: AnalysisNode?, size: CGSize, tmpOffset: CGPoint) {
        self.node = node
        self.position = position
        self.size = size
        self.tmpOffset = tmpOffset
    }

     public required init(from decoder: any Decoder) throws {
        
        fatalError("init(from:) has not been implemented")
    }
    
    public func clone() -> LayoutItem
    {
        LayoutItem(position: self.position, node: self.node,
                   size: self.size, tmpOffset: self.tmpOffset)
    }

}


//---------------------------------------------------------------------
@Observable
public class CText: LayoutItem {
    var value: String = ""
    
    init(value: String) {
        self.value = value
        super.init(position: CGPoint(x: 200, y: 200), node: nil )
    }
    
    
    init(value: String, position: CGPoint) {
        super.init(position: position, node: nil )
        self.value = value
   }

    public  required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override public func clone() -> CText
    {
        return .init(value: value, position: position)
   }

}
    //---------------------------------------------------------------------

@Observable
class CChart : LayoutItem
{
    var xAxis: AxisNormalizer?
    var yAxis: AxisNormalizer?

    init() {
        super.init(position: CGPoint.zero, node: nil )
    }
   
    init(xAxis: AxisNormalizer?, yAxis: AxisNormalizer?
         , position:CGPoint = .zero, node: AnalysisNode?) {
 
        self.xAxis = xAxis;
        self.yAxis = yAxis;
        super.init(position: position, node: node )
 
    }
    
    init(node: AnalysisNode, position:CGPoint = .zero) {
        super.init(position: position, node: node )
    }
    
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override public func clone() -> CChart
    {
        return .init(xAxis: xAxis, yAxis: yAxis, position: position, node: node)
    }

}
//---------------------------------------------------------------------

@Observable
class CTable : LayoutItem
{
    var data: Data?      
    init(position: CGPoint) {
        self.data = nil
        super.init(position: CGPoint.zero, node: nil )
    }
    init(data: Data?) {
        super.init(position: CGPoint.zero, node: nil )
        self.data = data
    }
    
    init(data: Data?, position: CGPoint, node: AnalysisNode?)
    {
        super.init(position: position, node: node )
       self.data = data
    }

    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override public func clone() -> CTable
    {
        return .init(data: data, position: position, node: node)
    }

}

//---------------------------------------------------------------------
// MISC JUNK that might be streamed in from a FJ workspace

struct TableSchema : Codable
{
    var tableName = "a table"

   //    var columns : [TableColumn]
    init(_ xml: TreeNode)
    {
    }
}

struct PageSection
{
  var  sectionName = "header"
    var content = ""
}
struct PrintReport
{
    var scale = 1.0
    var header : PageSection
    var footer : PageSection
}
struct BatchInfo  : Codable, Hashable
{
    var  iter = ["", ""]
    var  discrim = ["", ""]
    var  destination = "JPEG"
}
