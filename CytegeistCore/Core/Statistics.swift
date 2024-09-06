//
//  Statistics.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 9/4/24.
//

import Foundation

public extension HistogramData<X> {
    
    func percentile(_ percentile:Double) -> Double {
        let searchCount = totalCount * percentile
        var countSum = 0.0
        for (value, count) in counts {
            countSum += Double(count)
            if countSum >= searchCount {
                return value.x
            }
        }
        print("Error computing percentile?")
        return .nan
    }
    
    func mean() -> Double {
        let weightedPoints = counts.map { point, count in point.x * Double(count) }
        return weightedPoints.sum() / totalCount
    }
    
    
    
}
