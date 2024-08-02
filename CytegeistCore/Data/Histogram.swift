//
//  Histogram.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/28/24.
//

import Foundation


public struct HistogramData {
    public let bins:[Int]
    public let xAxis:AxisNormalizer
    public let countAxis:AxisNormalizer?
    
    public var resolution:Int { bins.count }
    
    public func count(bin: Int) -> Int { bins[clamp(bin, min:0, max:resolution-1)] }
    
    public init(bins: [Int], xAxis: AxisNormalizer, countAxis: AxisNormalizer? = nil) {
        self.bins = bins
        self.xAxis = xAxis
        self.countAxis = countAxis ?? HistogramData.defaultCountAxis(bins: bins)
    }
    
    public init(data: [Float], resolution: Int, xAxis: AxisNormalizer, countAxis: AxisNormalizer? = nil) {
        self.xAxis = xAxis
        
        var bins = Array(repeating: 0, count: resolution)
        var unitToBin = Float(resolution)
        
        for value in data {
            let bin = clamp(Int(xAxis.normalize(value) * unitToBin), min: 0, max: resolution-1)
            bins[bin] += 1
        }
        
        self.bins = bins
        self.countAxis = countAxis ?? HistogramData.defaultCountAxis(bins: bins)
    }
    
    private static func defaultCountAxis(bins:[Int]) -> AxisNormalizer {
        var maxValue = max(1, bins.max() ?? 1)
        return LinearAxisNormalizer(min: 0, max: Float(maxValue))
    }
}
