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
}

public extension CGSize {
    init(_ size: Float) {
        self.init(width:Double(size), height:Double(size))
    }
    init(_ width: Float, _ height: Float) {
        self.init(width:Double(width), height:Double(height))
    }
    var asPoint:CGPoint { .init(x:width, y:height) }
}
