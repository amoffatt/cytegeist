//
//  ParameterInspector.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/1/24.
//

import Foundation
import SwiftUI


public struct ParameterInspectorView: View {
    let core:CytegeistCoreAPI
    let sample:SampleRef
    let parameterName:String
    
    public var body: some View {
        VStack {
            HistogramView(data: core.histogram(sample: sample, parameterName: parameterName))
            Text(parameterName)
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}
