//
//  Test.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/29/24.
//

import Foundation
import CytegeistLibrary

public class TestUtil {
    
    public static func addNormalDistribution(to array: inout [Double], amplitude: Float, mean: Float, stdDev: Float) {
        guard !array.isEmpty else { return }
        
        let xmax = Double(array.count - 1)
        
        for i in 0..<array.count {
            let x = Double(i) / xmax
            let normalValue = (1 / (stdDev * sqrt(2 * .pi))) * exp(-pow(Float(x) - mean, 2) / (2 * pow(stdDev, 2)))
            array[i] += Double(normalValue * amplitude)
        }
    }
    
    
    @MainActor
    public static func histogram() -> APIQuery<CachedHistogram<X>> {
        
        let result:APIQuery<CachedHistogram<X>> = APIQuery()
        
        Task {
            await sleep(2.0)
            
            await MainActor.run {
                var bins:[Double] = Array(repeating: 0, count: 256)
                TestUtil.addNormalDistribution(to: &bins, amplitude: 8, mean: 0.3, stdDev: 0.2)
                result.progress(
                    CachedHistogram(
                        HistogramData(
                            bins: bins,
                            size: .init(bins.count),
                            axes: .init(.linear(minVal: 0, maxVal: 200))),
                        nil,
                        view: nil
                    )
                )
            }
            
            await sleep(2)
            
            await MainActor.run {
                // AM DEBUGGING
//                var bins = result.data!.bins
//                TestUtil.addNormalDistribution(to: &bins, amplitude: 1.5, mean: 0.8, stdDev: 0.05)
//                result.success(HistogramData(bins: bins, xAxis: LinearAxisNormalizer(min: -10.1, max: 300)))
            }
            
        }
        
        return result
    }
}
