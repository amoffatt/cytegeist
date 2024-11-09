    //
    //  Contours.swift
    //  CytegeistCore
    //
    //  Created by Adam Treister on 9/11/24.
    //

import Foundation
import SwiftUI
import CytegeistLibrary

public struct Segment : Equatable
{
    var start, end: CGPoint
 
    init ( _ start: CGPoint, _ end: CGPoint)
    {
        self.start = start
        self.end = end
    }
    init ( _ start: CGPoint, _ end: CGPoint, _ rev: Bool)
    {
        self.start = rev ? end : start
        self.end = rev ? start : end
    }

    init ( _ startX: Int, _ startY : Int, _ endX: Int, _ endY: Int)
    {
        self.init(  CGPoint(Double(startX), Double(startY)),
                    CGPoint(Double(endX), Double(endY)))
    }
    init ( _ startX: Float, _ startY : Float, _ endX: Float, _ endY: Float)
    {
        self.init(  CGPoint(Double(startX), Double(startY)),
                    CGPoint(Double(endX), Double(endY)))
    }
    init ( _ startX: Double, _ startY : Double, _ endX: Double, _ endY: Double)
    {
        self.init(  CGPoint(startX, startY), CGPoint(endX, endY))
        if (startX == endX) && (startY == endY)
        {
            print("0 length")
        }
    }
    init ( _ startX: Double, _ startY : Double)
    {
        self.init(  CGPoint(startX, startY), CGPoint.zero)
    }
    mutating func addEndpoint(_ levelX: Double, _ levelY : Double)
    {
        self.end = CGPoint(levelX, levelY)
    }
    public func segString() -> String
    {
        return("(" +
               String(format: "%.2f", self.start.x) + ", " +
               String(format: "%.2f", self.start.y) + ") : (" +
               String(format: "%.2f", self.end.x) + ", " +
               String(format: "%.2f", self.end.y) + ")"
        )
    }
}
//------------------------------------------------------------------------

public struct PositionBin : Comparable
{
    public static func < (lhs: PositionBin, rhs: PositionBin) -> Bool {
        lhs.height < rhs.height
    }
    
    var row, col: Int
    var height: Double
    init(row: Int, col: Int, height: Double) {
        self.row = row
        self.col = col
        self.height = height
    }
}

//public func binsSortedByHeight(_ bins: [Double], _ nRows: Int,_ nCols: Int)   -> [PositionBin]
//{
//    let nBins = nRows * nCols
//    var taggedBins = [PositionBin]()
//    
//    for i in 0 ..< nBins   {
//        taggedBins.append(PositionBin(row: i / nCols, col: i % nCols, height: bins[i]))
//    }
//    return taggedBins.sorted(by: >)
//}

public func segString(_ seg: Segment) -> String
{
    return("(" +
           String(format: "%.2f", seg.start.x) + ", " +
           String(format: "%.2f", seg.start.y) + ") : (" +
           String(format: "%.2f", seg.end.x) + ", " +
           String(format: "%.2f", seg.end.y) + ")"
    )
}
    //------------------------------------------------------------------------

func isLogPlot()   -> Bool {    true }
func getNEvents() -> Double  {    100000.0 }
public struct ContourBuilder
{
    let nCols: Int
    let nRows: Int
    var nEvents: Double = 0.0
    let nLevels: Int = 20
    var levels: [Double]
    var eventsPerLevel: Double = 0
    var positionBins: [PositionBin]
    var sortedBins: [PositionBin]
//    public var paths: PathList
    
    init(bins: [Double], width: Int, height: Int)
    {
        nCols = width
        nRows = height
        for x in 0..<nCols {
            for y in 0..<nRows {
                let idx = x + nCols * y
                nEvents += bins[idx]
            }
        }
        self.eventsPerLevel = nEvents / Double(nLevels)
        let nBins = nRows * nCols
        positionBins = [PositionBin]()
        levels = Array(repeating: Double(0.0), count: nLevels)
        for i in 0 ..< nBins   {
            positionBins.append(PositionBin(row: i / nCols, col: i % nCols, height: bins[i]))
        }
        sortedBins = positionBins.filter({ $0.height > 0.5 }).sorted(by: >)
        var level: Int = nLevels-1
        var deaccumulator  = eventsPerLevel
        for sortedBin in sortedBins {
            let ct = sortedBin.height
            deaccumulator -= ct
            if (deaccumulator  < 0)
            {
                let interpolated = ct + (deaccumulator / eventsPerLevel)
                levels[level] = interpolated
                deaccumulator += eventsPerLevel
                level -= 1
                if level < 0 { break }
            }
        }
    }
    
        //------------------------------------------------------------------------
//    func  testPath() -> Path
//    {
//        let pointList: [CGPoint] = [CGPoint(3,5), CGPoint(30,50),CGPoint(45,55),CGPoint(33,33),CGPoint(30,25),CGPoint(3,9)]
//        var path = Path()
//        path.move(to: pointList[0])
//        for i in 1..<pointList.count  {
//            let pt = pointList[i]
//            path.addLine(to: pt)
//        }
//        path.closeSubpath()
//        
//        return path
//    }
//    
    public func buildPathList() -> PathList
    {
        var list = PathList()
            //        list.paths.append(testPath())
        for i in (0 ..< nLevels).reversed() {
            let level = levels[i]
            let prevlevel = (i < nLevels-1) ?  levels[i+1] : -1.0
            if level > 0 {
                let segments = segments(level: level, prevLevel: prevlevel)
                print("segments: \(segments.count)  @ level \(i) = \(level)")
                let uniqueSegments = removeDuplicates(segments: segments)
                print("uniqueSegments: \(uniqueSegments.count) ")
                    //                let  temp = PathList(segments: uniqueSegments)
                if  let temp = list.makePathRAW(segments: uniqueSegments) {
                    list.paths.append(temp) //contentsOf: temp.paths)
                                            //                print("paths: \(list.paths.count)")
                    
                        //                if  let temp2 = list.makePathRAW(segments: uniqueSegments) {
                        //                    list.paths.append(temp2)
                        //                }
                }
            }
            }
            return list
        }
        
            //
            //
            //
            //for bin in 0 ..< positionBins.count  {
            //    let curBin = positionBins[bin]
            //    let h = curBin.height
            //    let prev = bin > 0 ? positionBins[bin-1].height : 0.0
            //
            //    print("threshold: \(threshold)")
            //    threshold -= h
            //    var  fire = thresholdTrigger(h, prev, threshold)
            //    while  (fire)
            //    {
            //        let levelHeight = getLevelHeight(h, prev, threshold)
            //        print("levelHeight: \(levelHeight)")
            //    func thresholdTrigger(_ height: Double, _ prev: Double, _ threshold: Double) -> Bool
            //    {
            //        var level = threshold
            //        let minLogLevel: Double = 6.0
            //
            //        if isLogPlot()
            //        {
            //            let below = (height < level)
            //            if below
            //            {
            //                if level == prev     {
            //                    level = level - 0.001 * (prev - height)
            //                }
            //
            //                level = level * (Double(nLevels))/100.0
            //                if level < minLogLevel
            //                {    return false   }
            //            }
            //            return below
            //        }
            //        return (threshold < 0.0)
            //    }
            //
            //    func getLevelHeight(_ height: Double, _ prev: Double, _ threshold: Double) -> Double
            //    {
            //        let binDifference = height - prev
            //        if !isLogPlot()
            //        {
            //            if binDifference < 0.0 {
            //                return     height + threshold / height * binDifference * 0.999
            //            }
            //        }
            //        return height - 0.5 * binDifference
            //    }
            //------------------------------------------------------------------------
        enum Direction : CaseIterable {
            case east
            case south
            case west
            case north
        }
        
        func getDeltas( dir: Direction) -> (Int, Int)
        {
            switch dir {
                case .east:  return (1, 0)
                case .south: return (0, 1)
                case .west : return (-1, 0)
                case .north: return (0, -1)
            }
        }
        
        func getPosition( dir: Direction) -> (Int, Int)
        {
            switch dir {
                case .east:  return (0, 0)
                case .south: return (0, nCols-1)
                case .west:  return (nRows-1, nCols-1)
                case .north: return (nRows-1, 0)
            }
        }
        
        func binHeight( x: Int, y: Int) -> Double   {
            if x < 0 || y < 0  { return 0.0}
            if x >= nRows || y >= nCols { return 0.0 }
            return  positionBins[y * nCols + x].height
        }
        
        func segments( level: Double,  prevLevel: Double) -> [Segment]
        {
            assert(prevLevel > level || prevLevel < 0)
            var segments =  [Segment]()
            let binsAtThisLevel = sortedBins.filter( { $0.height >= level  &&  ($0.height < prevLevel || prevLevel < 0) })
            print ("binsAtThisLevel: \(binsAtThisLevel.count)")
            for bin in binsAtThisLevel          //            print ("bin: ( \(bin.col), \(bin.row) ) = \(bin.height)")
            {
                let crossings = addCrossings(level, bin.col, bin.row)
                segments.append(contentsOf: crossings)
            }
            return segments
        }
        
            //------------------------------------------------------------------------
        
        func addCrossings(_  level: Double, _ centerX: Int,_ centerY: Int) -> [Segment]
        {
            var segments:[Segment] = []
            
            for x in (-1...0) {
                for y in (-1...0) {
                    
                    let X = centerX + x
                    let Y =  centerY + y
                    if X < 0 || Y < 0                  {   continue  }
                    if X >= nCols-1 || Y >= nRows-1    {   continue }
                    
                    let h1 = binHeight(x: X,  y: Y)
                    if h1 == 0                         {   continue }
                    let h2 = binHeight(x: X+1, y: Y)
                    let h3 = binHeight(x: X,   y: Y+1)
                    let h4 = binHeight(x: X+1, y: Y+1)
                    
                    var points =  [CGPoint]()
                    var isHead = [Bool]()
                    
                    if inBetween(level, h1,  h2)
                    {
                        let interpolation = (level - h1) / (h2 - h1)
                        let fx = Double(X) + interpolation
                        points.append(CGPoint(Double(fx), Double(Y)))
                        isHead.append(h1 < h2)
                    }
                    if inBetween(level, h2,  h4)
                    {
                        let interpolation: Double = (level - h2) / (h4 - h2)
                        let fy = Double(Y) + interpolation
                        points.append(CGPoint(Double(X + 1), Double(fy)))
                        isHead.append( h2 < h4)
                    }
                    if inBetween(level, h3,  h4)
                    {
                        let interpolation: Double = (level - h3) / (h4 - h3)
                        let fx = Double(X) + interpolation
                        points.append(CGPoint( Double(fx), Double(Y + 1) ))
                        isHead.append(h4 < h3)
                    }
                    if (inBetween(level, h1,  h3))
                    {
                        let interpolation: Double = (level - h1) / (h3 - h1)
                        let fy = Double(Y) + interpolation
                        points.append(CGPoint(Double(X + 1), Double(fy)))
                        isHead.append(h3 < h1)
                    }
                    
                    if points.count == 0   { continue }
                    else if points.count == 2   { segments.append(Segment(points[1], points[0], isHead[0]))   }
                    else if points.count == 4     {    //  double crossing
                        if (h1 > level)  {
                            segments.append(Segment(points[3],points[0], isHead[0]))
                            segments.append(Segment(points[2],points[1], isHead[1]))
                        }
                        else {
                            segments.append(Segment(points[1],points[0], isHead[0]))
                            segments.append(Segment(points[3],points[2], isHead[2]))
                        }
                    }
                }
            }
                //        if segments.count > 0 {             //debug
                //            print( "addCrossings")
                //            for seg in segments {
                //                print( segString(seg))
                //            }
                //        }
            return segments
        }
        
            //------------------------------------------------------------------------
        func removeDuplicates(segments: [Segment]) -> [Segment]
        {
            var unique = [Segment]()
            for seg in segments
            {
                let extant = unique.first( where:  { matches(seg, $0) })
                if extant == nil     {
                    unique.append(seg)
                }
            }
            return unique
            
        }
        func matches(_ a: Segment,_ b: Segment) -> Bool
        {
            let eps = 0.001
            if abs(a.start.x - b.start.x) > eps { return false }
            if abs(a.end.x - b.end.x) > eps     { return false }
            if abs(a.start.y - b.start.y) > eps { return false }
            if abs(a.end.y - b.end.y) > eps     { return false }
            return true
        }
        
        func inBetween(_ x: Double, _ a: Double,_  b: Double) -> Bool
        {
            return  x >= min(a,b) && x < max(a,b)             // we dont know if a < b
        }
            //------------------------------------------------------------------------
            //    func segCompare(_ a: Segment ,_ b:  Segment) -> Bool
            //    {
            //        let aStart = a.start, bStart = b.start
            //        let aEnd = a.end, bEnd = b.end
            //
            //        if (aStart == bStart)   {   return aEnd == bEnd  }
            //        if (aStart == bEnd)     {   return aEnd == bStart  }
            //        return false
            //    }
            //
            //------------------------------------------------------------------------
        
        
        
            //
            //     func getThreshold(_ bins: [PositionBin],_  level: Double) -> Double
            //    {
            //        let logPlot = isLogPlot()
            //        if (logPlot)   {      return level / 2.0       }
            //
            //        let contourLevel = (bins[0].height / level)
            //        if contourLevel > 0
            //        {
            //            return bins[0].height - contourLevel * level
            //        }
            //        return 0.0
            //    }
            //
            //------------------------------------------------------------------------
    }
    public struct PathList
    {
        var bottom = 256
       let width = 256.0, height = 256.0
        var paths : [Path] = [Path]()
        var pointList =  [CGPoint]()

       public func getBinResolution() -> (CGFloat, CGFloat){    return (256.0, 256.0)  }
       public func getGraphRect() -> CGRect{    .init(x: 0,y: 0, width: 256, height: 256)    }

       init()
        {
        }
        let epsilon: Double  = 0.001

        init(segments: [Segment])
        {
//            print("\(segments.count)  segments")
            var local = segments.filter({ distance($0.start, $0.end) > epsilon})
//            print("\(local.count)  segments in local")
            
                //            pointList =  segments.map { CGPoint($0.start.x, 256 - $0.start.y)}
                //            pointList = pointList.sorted(by: { $0.x > $1.x} )
                //
            if false
            {
                while !local.isEmpty
                {
                    var segment = local.removeFirst()
                    pointList.append(segment.start)
                    let pathStart = segment.start
                    var pt = segment.end
                    print( segment.segString())
                    while !local.isEmpty
                    {
                        let (minIdx, minDist) =   findClosestSegment(pt, local)                 //                    if let idx = local.firstIndex(where: { quickDistance($0.start, pt) <= 0.5 } )
                        if (minDist < 10) {
                            segment = local.remove(at: minIdx)
                            pointList.append(segment.start)
                            pt = segment.end
                        } else {  break }
                        if minDist < epsilon  { break }
                    }
                    if pointList.count >  5 {
                        if let path = makePath(pointList: pointList) {
                            paths.append(path)
                                //                        print("adding path from \(pointList.count) points")
                            pointList.removeAll()
                        }
                    }
                }
                    //            if pointList.count >  5 {
                    //                let pt = pointList.first!
                    //                pointList.append(pt)
                
                    //                if let path = makePath(pointList: pointList) {
                    //                    paths.append(path)
                    //                    print("adding path from \(pointList.count) points")
                    //                }
                    //            }
                print("\(local.count) segments left,  \(pointList.count) points")
                pointList.removeAll()
            }
        }
    
        func findClosestSegment(_ pt: CGPoint , _ segments: [Segment]) -> (Int, Double)
        {
            var minDist: Double = .infinity
            var minIdx = -1
            for i in (0 ..< segments.count) {
                let seg = segments[i]
                let di = distance( seg.start, pt)
                if di < minDist {
                    minDist = di
                    minIdx = i
                }
                if minDist < epsilon  { break }
            }
            return (minIdx, minDist)

        }

//        
//       func tail(_ segments: [Segment]) -> Int
//       {
//           for i in 0 ..< segments.count
//           {
//               let line = segments[i]
//               let x = line.start.x
//               if (x == 0 || x == width)    {    return i }
//               let y = line.start.y
//               if (y == 0 || y == height)    {    return i }
//           }
//           return 0
//       }
//       
       func  makePath(pointList: [CGPoint]) -> Path?
       {
           print("\(pointList.count) points to makePath")
           if pointList.count < 3 { return nil }
//           let rect = getGraphRect()
//           let (nRows, nCols) = getBinResolution()
//           let widthPerBin =  rect.width / nCols
//           let heightPerBin = rect.height / nRows
//           let insetRect = CGRect(x: rect.minX + widthPerBin / 2.0, y: rect.minY + heightPerBin / 2.0, width: rect.width,height: rect.height)
           var path = Path(points: pointList)
//           let startpt = pointList[0]
////           path.move(to: CGPoint(insetRect.minX + startpt.x * widthPerBin, insetRect.minY - startpt.y * heightPerBin))
//           path.move(to: startpt)
//           for i in 1..<pointList.count  {
//               let pt = pointList[i]
//               path.addLine(to: pt )
//           }
//           path.closeSubpath()
           
           return path
       }
        func  makePathRAW(segments: [Segment]) -> Path?
        {
            print("\(segments.count) segments to makePath")
            if segments.count < 3 { return nil }
            var path = Path()
            for seg in segments  {
                path.move(to: seg.start)
                path.addLine(to: seg.end )
            }
//            path.closeSubpath()
            return path
        }
   }

