//
//  SampleInspectorView.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/1/24.
//

import Foundation
import SwiftUI

public struct SampleInspectorView: View {
    let core: CytegeistCoreAPI
    let sample: SampleRef
    
    public var body: some View {
        let metadata = core.metadata(sampleRef: sample)
        
        VStack {
            Text(sample.filename)
            ParameterGalleryView(core:core, sample: sample)
        }
    }
}

public struct ParameterGalleryView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let core: CytegeistCoreAPI
    let sample: SampleRef
    let parameters: [FCSParameter]
    
    public var body: some View {
        
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(parameters, id: \.0) { parameter in
                    ParameterInspectorView(core:core, sample:sample)
                }
            }
            .padding()
        }
    }
}
