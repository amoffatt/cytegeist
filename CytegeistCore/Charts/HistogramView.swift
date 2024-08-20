//
//  HistogramView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI
import Charts
import AppKit

struct HistogramView: View {
    let query:APIQuery<CachedHistogram<_1D>>
    
    var body: some View {
        LoadingOverlay(isLoading: query.isLoading) {
            VStack {
                if let error = query.error {
                    Text("Error: \(error.message)")
                }
                if let histogram = query.data?.histogram {
                    let resolution = histogram.size.x
                    Chart(0..<resolution, id: \.self) { bin in
                        AreaMark(
                            x: .value("X", Float(bin) / Float(resolution)),
                            y: .value("Count", histogram.normalizedCount(bin: .init(bin)))
                        )
                    }
                }
            }
            .onDisappear {
                query.dispose()
            }
        }
    }
    
}

struct Histogram2DView: View {
    let query:APIQuery<CachedHistogram<_2D>>
    
    var body: some View {
        LoadingOverlay(isLoading: query.isLoading) {
            VStack {
                if let error = query.error {
                    Text("Error: \(error.message)")
                }
                if let data = query.data {
//                    let size = data.histogram.size
//                    Print("Resolution: \(size)")
//                    let bins = EnumeratedArray(data.bins)
                    Chart() {
//                        let point = data.bin(bin1d: bin.element)
//                        
//                        RectangleMark(
//                            xStart: .value("X", Float(point.x)),
//                            xEnd: .value("X", Float(point.x) + 1.5),
//                            yStart: .value("Y", Float(point.y)),
//                            yEnd: .value("Y", Float(point.y) + 1.5)
//                        )
//                        .foregroundStyle(
//                            by: .value(
//                                "Count",
//                                bin.value
//                            )
//                        )
                    }
                    .background(.clear)
                    .chartBackground { proxy in
                        VStack {
                            let plotSize = proxy.plotSize
//                            let frame = proxy.
//                            if let frame = proxy.plotFrame {
                                data.view
                                    .frame(width:plotSize.width, height: plotSize.height)
//                            }
                        }
//                        Rectangle()
//                            .fill(.blue)
//                            .frame(width: 100, height: 100)
                        
                        
                    }
//                        .chartXScale(
//                            domain: 0...size.x
//                        )
//                        .chartYScale(
//                            domain: 0...size.y
////                            domain: 1...resolution.y,
////                            type: .log
//                        )
//                        .chartForegroundStyleScale(
//                            range: Colormap.jet
//                        )
                        .chartLegend(.hidden)
                }
            }
            .onDisappear {
                query.dispose()
            }
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
