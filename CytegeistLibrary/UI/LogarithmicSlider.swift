//
//  LogarithmicSlider.swift
//  Cytegeist
//
//  Created by AM on 11/17/24.
//
import Foundation
import SwiftUI

public struct LogarithmicSlider: View {
    @Binding var value: Double
    let range:ClosedRange<Double>
    
    // Optional parameters
//    var label: String = ""
//    var minimumValueLabel: String = ""
//    var maximumValueLabel: String = ""
    
    public init(value:Binding<Double>, in range: ClosedRange<Double>) {
        self._value = value
        self.range = range
//        self.minValue = minValue
//        self.maxValue = maxValue
//        self.label = label
    }
    
    private var linearValue: Binding<Double> {
        Binding(
            get: {
                // Convert from log scale to linear (0-1)
                let span = log(range.upperBound) - log(range.lowerBound)
                let logValue = (log(value) - log(range.lowerBound)) / span
                return logValue
            },
            set: { newLinearValue in
                // Convert from linear (0-1) to log scale
                let span = log(range.upperBound) - log(range.lowerBound)
                value = exp(log(range.lowerBound) + newLinearValue * span)
            }
        )
    }
    
    
    public var body: some View {
        Slider(
            value: linearValue,
            in: 0.0...1.0
//            label: { Text(label) }
//            minimumValueLabel: { Text(minimumValueLabel) },
//            maximumValueLabel: { Text(maximumValueLabel) }
        )
    }
}

#Preview {
    
}
