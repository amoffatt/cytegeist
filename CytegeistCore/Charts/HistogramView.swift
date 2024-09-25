//
//  HistogramView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI
import Charts
import CytegeistLibrary

public struct HistogramView: View {
    let query:APIQuery<CachedHistogram<X>>
    
    public init(query: APIQuery<CachedHistogram<X>>) {
        self.query = query
    }
    
    public var body: some View {
        LoadingOverlay(isLoading: query.isLoading) {
            VStack {
                if let error = query.error {
                    Text("Error: \(error.message)")
                }
                let data = query.data
                if let histogram = data?.smoothed ?? data?.histogram {
                    let resolution = histogram.size.x
                    Chart(0..<resolution, id: \.self) { bin in
                        AreaMark(
                            x: .value("X", Float(bin) / Float(resolution)),
                            y: .value("Count", histogram.normalizedCount(bin: .init(bin)))
                        )
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                }
            }
            .onDisappear {
                query.dispose()
            }
        }
    }
    
}

public struct Histogram2DView: View {
    let query:APIQuery<CachedHistogram<XY>>
    
    public init(query: APIQuery<CachedHistogram<XY>>) {
        self.query = query
    }
    
    public var body: some View {
        LoadingOverlay(isLoading: query.isLoading) {
            VStack {
                if let error = query.error {
                    Text("Error: \(error.message)")
                }
                if let data = query.data {
//                    Chart() { }
//                    .background(.clear)
//                    .chartBackground { proxy in
//                        VStack {
//                            let plotSize = proxy.plotSize
                            data.view
//                                .frame(width:plotSize.width, height: plotSize.height)
//                        }
//                    }
                        .fillAvailableSpace()
//                    .chartLegend(.hidden)
                }
            }
            .onDisappear {  query.dispose()  }
        }
    }
}


#Preview {
    return HistogramView(query:TestUtil.histogram())
        .padding()
#if os(visionOS)
        .glassBackgroundEffect()
#endif
}
