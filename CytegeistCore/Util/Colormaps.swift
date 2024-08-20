//
//  Colormaps.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/17/24.
//

import Foundation
import SwiftUI
import Charts


public struct Colormap {
    public let lookup:[Color]
    public let uint8Lookup:[SIMD4<UInt8>]
    public let gradient:Gradient
    
    public init(colors:[Color], resolution:Int = 256) {
        self.init(gradient: .init(colors: colors))
    }
    
    public init(gradient:Gradient, resolution:Int = 256) {
        precondition(resolution > 0)
        
        self.gradient = gradient
        
        let r = max(2, resolution)
        
        var colors:[Color] = .init(repeating: .clear, count: r)
        var uint8Colors:[SIMD4<UInt8>] = .init(repeating: .zero, count: r)
        
        for i in 0..<r {
            let location = Double(i) / Double(resolution - 1)
            let color = gradient.color(at: location)
            colors[i] = color
            uint8Colors[i] = .init(color.rgba.clamped01 * 255)
        }
        
        self.lookup = colors
        self.uint8Lookup = uint8Colors
    }
    
    /// Return copy of colormap with new resolution lookup table
    public func resolution(_ r:Int) -> Colormap {
        .init(gradient: gradient, resolution: r)
    }
    
    /// Get colormap (values in range 0..1)
    public func color(at:Float) -> Color {
        lookup.get(clampIndex: Int(at * Float(lookup.count)))!  // Value should never be null
    }
    
    public func colorUInt8(at:Float) -> SIMD4<UInt8> {
        uint8Lookup.get(clampIndex: Int(at * Float(uint8Lookup.count)))!  // Value should never be null
    }

}


extension Colormap {
    public static let jet = Colormap(colors: [
        Color(red: 0, green: 0, blue: 0.5),
        Color(red: 0, green: 0, blue: 1),
        Color(red: 0, green: 0.5, blue: 1),
        Color(red: 0, green: 1, blue: 1),
        Color(red: 0.5, green: 1, blue: 0.5),
        Color(red: 1, green: 1, blue: 0),
        Color(red: 1, green: 0.5, blue: 0),
        Color(red: 1, green: 0, blue: 0),
        Color(red: 0.5, green: 0, blue: 0)
    ])
}




extension Gradient {
    func color(at location: Float) -> Color {
        color(at:CGFloat(location))
    }
    
    func color(at location: CGFloat) -> Color {
        let stops = self.stops.sorted { $0.location < $1.location }
        
        guard let firstStop = stops.first, let lastStop = stops.last else {
            return Color.clear
        }
        
        if location <= firstStop.location {
            return firstStop.color
        }
        
        if location >= lastStop.location {
            return lastStop.color
        }
        
        for i in 0..<stops.count - 1 {
            let stop1 = stops[i]
            let stop2 = stops[i + 1]
            
            if location >= stop1.location && location <= stop2.location {
                let t = (location - stop1.location) / (stop2.location - stop1.location)
                return stop1.color.lerp(to: stop2.color, t: t)
            }
        }
        
        return Color.clear
    }
    
}

extension Color {
    static func cmyka2rgba(_ components:[CGFloat]) -> SIMD4<Float> {
        precondition(components.count == 5)
        
        let (cyan, magenta, yellow, black, alpha) = (components[0], components[1], components[2], components[3], components[4])
        
        // CMYK to RGB conversion
        let red = (1.0 - cyan) * (1.0 - black)
        let green = (1.0 - magenta) * (1.0 - black)
        let blue = (1.0 - yellow) * (1.0 - black)
        
        return .init(x:Float(red), y:Float(green), z:Float(blue), w:Float(alpha))
    }
    
    func lerp(to: Color, t: CGFloat) -> Color {
        lerp(to: to, t: Float(t))
    }
    
    func lerp(to: Color, t: Float) -> Color {
        self.rgba.lerp(to: to.rgba, t:t).color
    }
    
    var rgba: SIMD4<Float> {
        if let color = self.cgColor,
           let c = color.components {
            switch c.count {
            case 2:
                return .init(x:Float(c[0]), y:Float(c[0]), z:Float(c[0]), w:Float(c[1]))
            case 4:
                return .init(x:Float(c[0]), y:Float(c[1]), z:Float(c[2]), w:Float(c[3]))
            case 5:
                return Color.cmyka2rgba(c)
            default:
                return .zero
            }
        }
        return .zero
    }
    
}

extension SIMD4<Float> {
    var color: Color {
        Color(cgColor)
    }
    
    var cgColor: CGColor {
        CGColor(red: CGFloat(x), green: CGFloat(y), blue: CGFloat(z), alpha: CGFloat(w))
    }
}

extension SIMD3<Float> {
    var color: Color {
        Color(cgColor)
    }
    
    var cgColor: CGColor {
        CGColor(red: CGFloat(x), green: CGFloat(y), blue: CGFloat(z), alpha: 1)
    }
}
