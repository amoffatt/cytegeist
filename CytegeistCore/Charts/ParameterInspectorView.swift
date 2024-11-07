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
    let parameter:CDimension
    
    public init(core: CytegeistCoreAPI, sample: SampleRef, parameter: CDimension) {
        self.core = core
        self.sample = sample
        self.parameter = parameter
    }
    
    public var body: some View {
        VStack() {
            HStack {
//                Table(displayFields()) {
//                    TableColumn("Field", value:\.name)
//                    TableColumn("Value", value:\.value)
//                }
                
//                .tableColumnHeaders(.hidden)
//                .font(.footnote)
                Grid {
                    ForEach(displayFields()) { field in
                        GridRow {
                            Text(field.name)
                                .font(.body)
                                .fontWeight(.bold)
                                .frame(maxWidth:.infinity, alignment: .leading)
                            Text(field.value)
                                .font(.body)
                                .frame(maxWidth:.infinity, alignment: .leading)
                        }
                    }
                }
                
                HistogramView(query: core.histogram(.init(.sample(sample), .init(parameter.name))))
            }
            Text(parameter.displayName)
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
    
    private func displayFields() -> [StringField] {
        [
            .init("Name", parameter.name),
            .init("Stain", parameter.stain),
            .init("Filter", parameter.filter),
            .init("Display", parameter.displayInfo),
            .init("Range", String(parameter.range)),
            .init("Bits", String(parameter.bits)),
        ]
    }
}
