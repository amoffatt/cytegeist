//
//  GraphicsUtil.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/19/24.
//

import Foundation
import SwiftUI


public extension CGImage {
    var image:Image? {
#if canImport(AppKit)
        let nsImage = NSImage(cgImage: self, size: .init(width: width, height: height))
        return Image(nsImage: nsImage)
#elseif canImport(UIKit)
        let uiImage = UIImage(cgImage: self)
        return Image(uiImage: uiImage)

#else
        print("Error: Platform cannot convert CGImage to SwiftUI Image")
        return nil
#endif
        
    }
}




public func pts2Rect(_ a: CGPoint,_  b: CGPoint) -> CGRect
{
    let origin = CGPoint(x: min(a.x, b.x), y: min(a.y, b.y))
    let size = CGSize(width: abs(a.x - b.x), height: abs(a.y-b.y))
    return CGRect(origin: origin, size: size)
}


public func ptInRect(pt: CGPoint, rect: CGRect) -> Bool
{
    if (pt.x > rect.origin.x) &&  (pt.y > rect.origin.y)
    {
        if (pt.x < rect.origin.x + rect.width) && (pt.y < rect.origin.y + rect.height){
            return true
        }
    }
    return false
}
public func diff (a: CGPoint, b: CGPoint) -> CGSize {
        return CGSize(width: a.x-b.x, height: a.y-b.y)
    }

public func distance(_ a: CGPoint,_  b: CGPoint) -> CGFloat {
    return sqrt(((a.x-b.x) * (a.x-b.x)) + ((a.y-b.y) * (a.y-b.y)))
}

public extension CGPoint {
    
    var asSize:CGSize { .init(width:x, height:y) }
    
    init(_ x:Double, _ y:Double) {
        self.init(x:x, y:y)
    }
    
    static func - (a: CGPoint, b: CGSize) -> CGPoint {
        return CGPoint(x: a.x-b.width, y: a.y-b.height)
    }
    
    static func - (a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x-b.x, y: a.y-b.y)
    }
    
    static func + (a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x+b.x, y: a.y+b.y)
    }
    
    static func + (a: CGPoint, b: CGSize) -> CGPoint {
        return CGPoint(x: a.x+b.width, y: a.y+b.height)
    }
    
    static func * (a: CGPoint, b: CGSize) -> CGPoint {
        return CGPoint(x: a.x * b.width, y: a.y * b.height)
    }
    
    static func / (a: CGPoint, b: CGSize) -> CGPoint {
        return CGPoint(x: a.x / b.width, y: a.y / b.height)
    }
    
    static func * (a: CGPoint, b: Double) -> CGPoint {
        return CGPoint(x: a.x * b, y: a.y * b)
    }

    static func / (a: CGPoint, b: Double) -> CGPoint {
        return CGPoint(x: a.x / b, y: a.y / b)
    }
}

public extension CGSize {
    init(_ size: Float) {
        self.init(size, size)
    }
    init(_ width: Float, _ height: Float) {
        self.init(Double(width), Double(height))
    }
    
    init(_ width: Double, _ height: Double) {
        self.init(width:width, height:height)
    }
    var asPoint:CGPoint { .init(x:width, y:height) }
    
    static func * (a: CGSize, b: Double) -> CGSize {
        .init(a.width * b, a.height * b)
    }

    static func / (a: CGSize, b: Double) -> CGSize {
        .init(a.width / b, a.height / b)
    }
}

public extension CGRect {
    var min:CGPoint { .init(minX, minY) }
    var max:CGPoint { .init(maxX, maxY) }
    
    init(from:CGPoint, to:CGPoint) {
        let x = sort(from.x, to.x)
        let y = sort(from.y, to.y)
        self.init(origin: .init(x:x.0, y:y.0), size: .init(width:x.1 - x.0, height:y.1 - y.0))
    }
    
    func scaled(_ scale:CGSize) -> CGRect {
        .init(from: min * scale, to: max * scale)
    }
    
    /// Invert Y values based on full view height
    func invertedY(maxY:Double) -> CGRect {
        var min = min
        var max = max
        max.y = maxY - max.y
        min.y = maxY - min.y
        return .init(from:min, to:max)
    }
    
//    static func * (a: CGRect, b: CGSize) -> CGPoint {
//        return CGRect(origin: a.origin * b, size: )
//    }
//    
//    static func / (a: CGPoint, b: CGSize) -> CGPoint {
//        return CGPoint(x: a.x / b.width, y: a.y / b.height)
//    }
}
