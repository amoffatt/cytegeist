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
    
    /// Invert Y values based on full view height (defaults to normalized coordinates with max=1
    func invertedY(maxY:Double = 1) -> CGPoint {
        var p = self
        p.y = maxY - p.y
        return p
    }
    
    func rotated(by angle: Angle) -> CGPoint {
        let angle = angle.radians
        return CGPoint(x * Foundation.cos(angle) - y * Foundation.sin(angle),
                       x * Foundation.sin(angle) + y * Foundation.cos(angle))
    }
    
    var magnitudeSqr:Double { sqr(x) + sqr(y) }
    var magnitude:Double { sqrt(magnitudeSqr) }
    var angle:Double { atan2(y, x) }
}

public extension CGSize {
    init(_ size: CGFloat) {
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
    
    static func / (a: Double, b: CGSize) -> CGSize {
        .init(a / b.width, a / b.height)
    }
}

public extension CGRect {
    var min:CGPoint { .init(minX, minY) }
    var max:CGPoint { .init(maxX, maxY) }
    var center:CGPoint {
        get { .init(midX, midY) }
        set { origin = newValue - size / 2 }
    }

    init(from:CGPoint, to:CGPoint) {
        let x = sort(from.x, to.x)
        let y = sort(from.y, to.y)
        self.init(origin: .init(x:x.0, y:y.0), size: .init(width:x.1 - x.0, height:y.1 - y.0))
    }
    
    func toString() -> String
    {
        "(\(String(format: "%0.0f", minX)), \(String(format: "%0.0f", minY))) \(String(format: "%0.0f", width)) x \(String(format: "%0.0f", height)) "
    }
    /// Based on lower-left origin
    subscript(_ point:Alignment) -> CGPoint {
        get {
            let x = switch point.horizontal {
                case .leading: origin.x
                case .center: origin.x + size.width / 2
                case .trailing: origin.x + size.width
            default: fatalError("Unsupported")
            }
            
            let y = switch point.vertical {
                case .top: origin.y + size.height
                case .center: origin.y + size.height / 2
                case .bottom: origin.y
            default: fatalError("Unsupported")
            }
            
            return .init(x, y)
        }
        set {
            switch point.horizontal {
            case .leading:
                size.width = origin.x + size.width - newValue.x
                origin.x = newValue.x
            case .center:
                origin.x = newValue.x - size.width / 2
            case .trailing:
                size.width = newValue.x - origin.x
            default: fatalError("Unsupported")
            }
            
            switch point.vertical {
            case .top:
                size.height = newValue.y - origin.y
            case .center:
                origin.y = newValue.y - size.height / 2
            case .bottom:
                size.height = origin.y + size.height - newValue.y
                origin.y = newValue.y
            default: fatalError("Unsupported")
            }
        }
    }
    
    /// Fix rectangle with negative size values
    mutating func canonicalize() {
        if size.width < 0 {
            size.width *= -1
            origin.x -= size.width
        }
        if size.height < 0 {
            size.height *= -1
            origin.y -= size.height
        }
    }
    
    func scaled(_ scale:CGSize) -> CGRect {
        .init(from: min * scale, to: max * scale)
    }
    
    
    /// Invert Y values based on full view height (defaults to normalized coordinates with max=1
    func invertedY(maxY:Double = 1) -> CGRect {
        return .init(
            from:min.invertedY(maxY: maxY),
            to:max.invertedY(maxY: maxY)
        )
    }
    
//    static func * (a: CGRect, b: CGSize) -> CGPoint {
//        return CGRect(origin: a.origin * b, size: )
//    }
//    
//    static func / (a: CGPoint, b: CGSize) -> CGPoint {
//        return CGPoint(x: a.x / b.width, y: a.y / b.height)
//    }
}


