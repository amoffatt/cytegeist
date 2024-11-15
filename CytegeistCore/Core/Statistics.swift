//
//  Statistics.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 9/4/24.
//

import Foundation

public extension HistogramData<X> {
    
    /// Percentile in range [0, 1.0]
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
    
    
}
public extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    }
