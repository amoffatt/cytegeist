//
//  HistogramView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI
import Charts

struct HistogramView: View {
    let data:APIQuery<HistogramData>
    
    var body: some View {
        LoadingOverlay(isLoading: data.isLoading) {
            VStack {
                
                //            Chart(histogramData, id: \.range) { bucket in
                //                BarMark(
                //                    x: .value("Range", bucket.range),
                //                    y: .value("Count", bucket.count)
                //                )
                //            }
                
                
                if let data = data.data {
                    let resolution = data.resolution
                    Chart(0..<resolution, id: \.self) { bin in
                        BarMark(
                            x: .value("X", Float(bin) / Float(resolution)),
                            y: .value("Count", data.count(bin: bin))
                            //                        y: .value("Count", Float.random(in:0.0...5.0))
                        )
                    }
                }
                else {
                    Text("Loading data...")
                }
            }
            .onDisappear {
                data.dispose()
            }
        }
    }
}

#Preview {
    return HistogramView(data:TestUtil.histogram())
        .padding()
        .glassBackgroundEffect()
}
