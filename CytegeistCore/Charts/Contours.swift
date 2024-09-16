    //
    //  Contours.swift
    //  CytegeistCore
    //
    //  Created by Adam Treister on 9/11/24.
    //

import Foundation
import SwiftUI

struct Segment : Equatable
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

}
    //------------------------------------------------------------------------

public struct Bin : Comparable
{
    public static func < (lhs: Bin, rhs: Bin) -> Bool {
        lhs.height < rhs.height
    }
    
    var row, col: Int
    var height: Float
    init(row: Int, col: Int, height: Float) {
        self.row = row
        self.col = col
        self.height = height
    }
}

public func binsSortedByHeight(_ bins: [Bin], _ nRows: Int,_ nCols: Int)   -> [Bin]
{
    let minimum: Float = 3.0
    let nBins = nRows * nCols
    var taggedBins = [Bin]()
    
    for i in 0 ..< nBins
    {
        let height = bins[i].height
        if height > minimum {
            taggedBins.append(Bin(row: i / nCols, col: i % nCols, height: height))
        }
    }
    taggedBins.sort()
    return taggedBins
}
    //------------------------------------------------------------------------

func isLogPlot()   -> Bool {    false }
func getNEvents() -> Float  {    100000.0 }
public struct Histo2D
{
     let nCols = 256
    let nRows = 256
    let nEvents = getNEvents()
        //------------------------------------------------------------------------
    
//    
//    func makeContourPlot(showOutliers: Bool) -> Path
//    {
//        smooth()
//        let polygons = polygonList(binsSortedByHeight())
// 
//        for poly in polygons {    poly.path()    }
//        
//        if showOutliers
//        {
//             var  nPolys = 0
//            var  polys = [Polygon]()
//            var spPolys = [CGPoint]
//            for i in polys {
//                spPolys.append(CGPointSet(i))
//            }
//            drawDotsMasked(contourPlot, spPolys, nPolys)
//        }
//                                   
//            
//// finalize Image
//        return path
//    }
//                                   
    let nLevels: Float = 20

//------------------------------------------------------------------------
    func polygonList(bins: [Bin]) -> PathList
    {
        let eventsPerLevel: Float = nEvents / nLevels
        var level: Float = 1.0
        var list = PathList()
        
        var threshold = getThreshold( bins, level)

        for bin in 0 ..< bins.count  {
            let curBin = bins[bin]
            let h = curBin.height
            let prev = bin > 0 ? bins[bin-1].height : 0.0

            threshold -= h
            var  fire = thresholdTrigger(h, prev, threshold)
            while  (fire)
            {
                let levelHeight = getLevelHeight(h, prev, threshold)
                let segments = segments(bins, levelHeight)
                let prunedSegments = removeDuplicates(segments: segments)
                list.paths.append(contentsOf: PathList(segments: prunedSegments).paths)
                threshold += eventsPerLevel
//                threshold = getThreshold()
                fire = threshold < 0.0
             }
        }
        return list
    }

    func thresholdTrigger(_ height: Float, _ prev: Float, _ threshold: Float) -> Bool
    {
        var level = threshold
        let minLogLevel: Float = 6.0
        
        if isLogPlot()
        {
            let below = (height < level)
            if below
            {
                if level == prev     {
                    level = level - 0.001 * (prev - height)
                }
                
                level = level * (Float(nLevels))/100.0
                if level < minLogLevel
                {    return false   }
            }
            return below
        }
        return (threshold < 0.0)
    }
    
    func getLevelHeight(_ height: Float, _ prev: Float, _ threshold: Float) -> Float
    {
        let binDifference = height - prev
        if !isLogPlot()
        {
            if binDifference < 0.0 {
                return     height + threshold / height * binDifference * 0.999
            }
        }
        return height - 0.5 * binDifference
    }
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
            case .west : return (nRows-1, nCols-1)
            case .north: return (nRows-1, 0)
        }
    }

     func segments(_ bins: [Bin], _ level: Float) -> [Segment]
    {
        func binHeight(_ y: Int, _ x: Int) -> Float   {   return  bins[y * nCols + x].height      }
        var segments =  [Segment]()
        
        for bin in bins
        {
            let centerX: Int = bin.col
            let centerY: Int = bin.row
            segments.append(contentsOf: addEdges(bins, level, centerX, centerY))
            segments.append(contentsOf: addEdges(bins, level, centerX-1, centerY))
            segments.append(contentsOf: addEdges(bins, level, centerX, centerY-1))
            segments.append(contentsOf: addEdges(bins, level, centerX-1, centerY-1))
        }
        
        var startX, startY : Float

        for direction in Direction.allCases
        {
            let (x1,y1) = getPosition(dir: direction)
            let (dx,dy) = getDeltas(dir: direction)
            let ct = (direction == .east || direction == .west) ? nCols : nRows
            
            var aboveLevel = (binHeight(x1, y1) > level)
            if aboveLevel    {
                startX = Float(x1)
                startY = Float(y1)
            }
            
            var y = y1
            var x = x1
            var levelX: Float = 0.0
            var levelY: Float = 0.0

            startX = Float(x)
            startY = Float(y)
           while (ct > 1)
            {
                let h1 = binHeight(x,y)
                let h2 = binHeight(x + dx, y + dy)
                if (inBetween(level, h1, h2))
                {
                    let fx = Float(x)
                    if (dx == 0)        { levelX = fx }
                    else if (dx == -1)  { levelX = (fx - 1.0) + (level - h2) / (h1 - h2) }
                    else                { levelX = fx + (level - h1) / (h2 - h1) }
                    
                    let fy = Float(y)
                    if (dy == 0)        { levelY = fy }
                    else if (dy == -1)  { levelY = (fy - 1.0) + (level - h2) / (h1 - h2) }
                    else                { levelY = fy + (level - h1) / (h2 - h1) }
                    
                    if (aboveLevel)   {
                        segments.append( Segment( startX, startY, levelX, levelY))
                    }
                    else {
                        startX = levelX
                        startY = levelY
                    }
                    aboveLevel = !aboveLevel
                }
                y += dy
                x += dx
            }
            if (aboveLevel)  {
                segments.append( Segment( startX, startY, levelX, levelY) )
            }
           
        }
        return segments
    }

   //------------------------------------------------------------------------
    
    func addEdges(_ bins: [Bin],_  level: Float, _ centerX: Int,_ centerY: Int) -> [Segment]
    {
        func binHeight(_ y: Int, _ x: Int) -> Float   {   return  bins[y * nCols + x].height      }

        if centerX < 0 || centerY < 0                  {   return []  }
        if centerX >= nCols-1 || centerY >= nRows-1    {    return [] }
            
        let h1 = binHeight(centerY, centerX)
        let h2 = binHeight(centerY, centerX+1)
        let h3 = binHeight(centerY+1, centerX)
        let h4 = binHeight(centerY+1, centerX+1)
        
        var points =  [CGPoint]()
        var isHead = [Bool]()
                           
        
        if inBetween(level, h1,  h2)
        {
            let ratio: Float = (level - h1) / (h2 - h1)
            let fx = Float(centerX) + ratio
            points.append(CGPoint(Double(fx), Double(centerY)))
            isHead.append(h1 < h2)
       }
        if inBetween(level, h2,  h4)
        {
            let ratio: Float = (level - h2) / (h4 - h2)
            let fy = Float(centerY) + ratio
            points.append(CGPoint(Double(centerX + 1), Double(fy)))
            isHead.append( h2 < h4)
        }
        if inBetween(level, h3,  h4)
        {
            let ratio: Float = (level - h3) / (h4 - h3)
            let fx = Float(centerX) + ratio
            points.append(CGPoint( Double(fx), Double(centerY + 1) ))
            isHead.append(h4 < h3)
        }
        if (inBetween(level, h1,  h3))
        {
            let ratio: Float = (level - h1) / (h3 - h1)
            let fy = Float(centerY) + ratio
            points.append(CGPoint(Double(centerX + 1), Double(fy)))
            isHead.append(h3 < h1)
        }
        
        if points.count == 0   { return [] }
        if points.count == 2   { return [Segment(points[1], points[0], isHead[0])]   }
        if points.count == 4     {    //  double crossing
            if (h1 > level)  {
                return[Segment(points[3],points[0], isHead[0]), 
                       Segment(points[2],points[1], isHead[1])]
            }
            return[Segment(points[1],points[0], isHead[0]), 
                   Segment(points[3],points[2], isHead[2])]
        }
        return []  // error
    }
   
   //------------------------------------------------------------------------
   func removeDuplicates(segments: [Segment]) -> [Segment]
    {
        var pruned = [Segment]()
        for seg in 0 ..< segments.count
        {
            let z = segments[seg]
            let extant = pruned.first( where:  { z == $0 })
            if extant == nil     {  pruned.append(z)}
        }
        return pruned
        
    }
   
                         
    func inBetween(_ x: Float, _ a: Float,_  b: Float) -> Bool
    {
        return  x >= min(a,b) && x < max(a,b)             // we dont know if a < b
    }
        //------------------------------------------------------------------------
    func segCompare(_ a: Segment ,_ b:  Segment) -> Bool
    {
        let aStart = a.start, bStart = b.start
        let aEnd = a.end, bEnd = b.end
        
        if (aStart == bStart)   {   return aEnd == bEnd  }
        if (aStart == bEnd)     {   return aEnd == bStart  }
        return false
    }
                       
 //------------------------------------------------------------------------
    
    
    
     
     func getThreshold(_ bins: [Bin],_  level: Float) -> Float
    {
        let logPlot = isLogPlot()
        if (logPlot)   {      return level / 2.0       }
        
        let contourLevel = (bins[0].height / level)
        if contourLevel > 0
        {
            return bins[0].height - contourLevel * level
        }
        return 0.0
    }
    
//------------------------------------------------------------------------
   struct PathList
    {
        var nLevels = 20
        var bottom = 256
       let width = 256.0, height = 256.0
        var paths : [Path] = [Path]()
        
       public func getBinResolution() -> (CGFloat, CGFloat){    return (256.0, 256.0)  }
       public func getGraphRect() -> CGRect{    .init(x: 0,y: 0, width: 256, height: 256)    }

       init()
        {
        }
        
        init(segments: [Segment])
        {
            var local = segments
            var pointList =  [CGPoint]()
            while (true)
            {
                var seg  = 0
                let i = tail(segments)
                if (i == -1)   {  break  }
                    
                var segment = local.remove(at: i)
                pointList.append(segment.start)
                var pt = segment.end
                
                var done = false
                while !done
                {
                    if let idx = local.firstIndex(where: { $0.start == pt})
                    {
                        segment = local.remove(at: idx)
                        pointList.append(segment.start)
                        pt = segment.end
                    }
                    else { done = true }
                }
                if  pointList[0] == pt  { break }
            }
            if pointList.count >  5 {
                if let path = makePath(pointList: pointList) {
                    paths.append(path)
                }
            }
        }
       func tail(_ segments: [Segment]) -> Int
       {
           for i in 0 ..< segments.count
           {
               let line = segments[i]
               let x = line.start.x
               if (x == 0 || x == width)    {    return i }
               let y = line.start.y
               if (y == 0 || y == height)    {    return i }
           }
           return 0
       }
       
       func  makePath(pointList: [CGPoint]) -> Path?
       {
           if pointList.count < 3 { return nil }
           let rect = getGraphRect()
           let (nRows, nCols) = getBinResolution()
           let widthPerBin =  rect.width / nCols
           let heightPerBin = rect.height / nRows
           let insetRect = CGRect(x: rect.minX + widthPerBin / 2.0, y: rect.minY + heightPerBin / 2.0, width: rect.width,height: rect.height)
           
           var path = Path()
           let startpt = pointList[0]
           path.move(to: CGPoint(insetRect.minX + startpt.x * widthPerBin, insetRect.minY - startpt.y * heightPerBin))
           for i in 1..<pointList.count  {
               let pt = pointList[i]
               path.addLine(to: CGPoint(insetRect.minX + pt.x * widthPerBin, insetRect.minY - pt.y * heightPerBin) )
           }
           path.closeSubpath()
           
           return path
       }
   }
        
}
