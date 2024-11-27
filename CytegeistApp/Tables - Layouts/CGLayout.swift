//
//  CGLayoutModel.swift
//
//
import SwiftUI
import Charts
import CytegeistLibrary
import CytegeistCore

    //-------------------------------------------------------------
// layout cell is the replicate made during batches

public struct LayoutCell : Codable, Hashable, Identifiable
{
    public var id = UUID()
    public func hash(into hasher: inout Hasher) {     hasher.combine(id)   }
    let sample: Sample
    var iteratorValue: String = ""
    let items: [LayoutItem]
    let rect: CGRect
    public init (sample: Sample, items: [LayoutItem], val: String = "")
    {
        self.sample =  sample
        self.items = items
        iteratorValue = val

        var xMin  =  10000.0, xMax = 0.0, yMin = 10000.0, yMax = 0.0
        for item in items {
            let r = item.getRect()
            xMin = min(xMin, r.minX)
            xMax = max(xMax, r.maxX)
            yMin = min(yMin, r.minY)
            yMax = max(yMax, r.maxY)
        }
        rect =  CGRect(x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin)
        items.forEach { $0.position = $0.position - rect.origin }
        items.forEach { $0.inject(sample: sample, iterator: iteratorValue) }
    }
    func width() -> CGFloat    {   rect.width    }
    
}
    //-------------------------------------------------------------

@Observable
class CGLayout : Codable, Hashable, Identifiable
{
    var id = UUID()
    var name = "Untitled Layout"
    var items = [LayoutItem]()
    var isTemplate = true
    var cells: [LayoutCell]?        // result of a batch
    //-------------------------------------------------------------
    init() {    }
    init(_ xml: TreeNode)    {    }

    init(orig: CGLayout, cells: [LayoutCell])
    {
        items = orig.items
        self.cells = cells
        isTemplate = false
  }
    //-------------------------------------------------------------
    static func == (lhs: CGLayout, rhs: CGLayout) -> Bool {       lhs.id == rhs.id   }
    func hash(into hasher: inout Hasher) {     hasher.combine(id)   }
    
    public func xml() -> String {
        return "<Layout " + attributes() + " >\n\t<Items>\n" +
               items.compactMap { $0.xml() }.joined() +
        "\t</Items>\n</Layout>\n"
    }
    
    public func attributes() -> String {  return "name= \(self.name) id=\(self.id)"  }

    //-------------------------------------------------------------
    // adding items
    
    func addItem(_ item:LayoutItem) {     items.append(item)   }
    
    public func addTextItem() -> ()
    {
        if !optionKey() { deselectAll()  }
        newTextItem(name: "some text", position: CGPoint(100,100))
    }
    
    public func newTextItem(name: String, position:CGPoint)
    {
        let layoutItem = LayoutItem(.text(name), position: position)
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
        let item = LayoutItem(.table, position: position, size: CGSize(width: 220, height: 120))
        item.selected = true
        addItem(item)
    }
    
    public func addImage() -> ()
    {
        if !optionKey() { deselectAll()  }
        newImage(name: "some image", position: CGPoint.zero, size: CGSize(width: 150, height: 180))
    }
    
    public func group() -> ()
    {
        print("TODO group")
//        if !optionKey() { deselectAll()  }
//        newImage(name: "some image", position: CGPoint.zero)
    }
    
    public func newImage(name: String, position:CGPoint, size: CGSize)
    {
        let item = LayoutItem(.image, position: position, size: size)
        item.selected = true
        addItem(item)
    }
        //---------------------------------------------------------------------------
        // manage the selection
    
    func deselectAll() -> ()  {   for item in items  { item.selected = false  }    }
    func selectAll() -> ()    {  for item in items   { item.selected = true   }    }
    
    func selectItem(_  newSel: LayoutItem) -> ()   {
        if !anyModifiers() { deselectAll() }
        newSel.selected = true
    }
    func deleteSelection() -> ()       {    items.removeAll (where:  { $0.selected } )    }
 
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
    // TODO dont think this is correct
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

public enum ELayoutType : Codable {
    case text(String)
    case chart(ChartDef?)
    case table
    case image
    case group
    
    public func xml() -> String
    {
        switch self {
            case .text: return "text"
            case .chart: return "chart"
            case .table: return "table"
            case .image: return "image"
            case .group: return "group"
        }
    }
}
//Model
@Observable
public class LayoutItem: Codable, Identifiable, Equatable
{
    public static func == (lhs: LayoutItem, rhs: LayoutItem) -> Bool {   lhs.id == rhs.id  }
    public private(set) var id = UUID()
    var size: CGSize = .zero
    var position: CGPoint = .zero
    var tmpOffset: CGPoint = .zero
    var currentCenterPosition:CGPoint { position + tmpOffset + size / 2 }
    var type: ELayoutType
        //    var value: String = ""              //Text
        //    var xAxis: AxisNormalizer?          //Chart
        //    var yAxis: AxisNormalizer?
        //    var data: Data?                     //Table
        //      var items: [LayoutItem]             // Group
        // save scale, rotation, background, stroke, etc
    
    var selected:Bool = false
    private(set) var node:AnalysisNode?
    
    var name:String {
        get { node != nil ? node!.name : "n/a"}
        set { if node != nil { node!.name = newValue }}
    }
    
        //    init(_ type: ELayoutType, position: CGPoint = .zero, node: AnalysisNode? = nil) {
        //        self.node = node
        //        self.position = position
        //        self.type = type
        //    }
    
        //    init(position: CGPoint, type: ELayoutType) {
        //        self.position = position
        //        self.type = type
        //
        //    }
        //    init(value: String) {
        //        self.value = value
        //        self.type = .text
        //    }
    
    public init(_ type: ELayoutType, node: AnalysisNode? = nil, position: CGPoint = .zero, size: CGSize = .init(100)) {
        self.node = node
        self.position = position
        self.type = type
        self.size = size
            //        self.tmpOffset = tmpOffset
    }
    
        //    convenience init(data: Data?) {
        //        self.init(position: CGPoint.zero, node: nil, type: ELayoutType.table )
        //         self.data = data
        //      }
    
    public required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public func clone() -> LayoutItem
    {
        LayoutItem(self.type, node: self.node, position: self.position, size: self.size)
    }
    
    public func inject(sample: Sample, iterator: String)
    {
        self.node = node
    }
    
    public func getRect() -> CGRect {
        return CGRect(origin: position, size: size)
    }
    public func string() -> String {  return type.xml()    }
    public func xml() -> String {
        return "<LayoutItem " + attributes() + " >\n" +
        position.xml() + size.xml() +  // + type specific content
        "</LayoutItem>\n"
        
    }
    
    public func attributes() -> String {
        return "type=\(type.xml())"
    }

}
