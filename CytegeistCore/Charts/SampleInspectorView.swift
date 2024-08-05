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
    @State var query: APIQuery<FCSFile>?
//    @State var data: FCSFile?
    
    
    public init(_ core: CytegeistCoreAPI, sample: SampleRef) {
        self.core = core
        self.sample = sample
    }
    
    public var body: some View {

        VStack {
            Text(sample.filename)
//            NavigationSplitView {
//                
//            }
            HStack {
//                keywordsView()
                
//                TabView {
//                    dataView()
//                        .tabItem {
//                            Label("Event Data", systemImage: "tablecells")
//                        }
                    parameterGalleryView()
//                        .tabItem {
//                            Label("Parameters", systemImage: "chart.bar")
//                        }

//                }
            }
        }
        .onChange(of: sample.url, initial: true) {
            query = core.loadSample(sampleRef: sample, includeData: true)
        }
    }
    
    private func keywordsView() -> some View {
        VStack {
            Text("Keywords")
                .font(.title)
            if let metadata = query?.data?.meta {
                Table(metadata.keywords) {
                    TableColumn("Name", value:\.name)
                    TableColumn("Value", value:\.value)
                }
            }
        }
    }
    
    private func parameterGalleryView() -> some View {
        VStack {
            if let metadata = query?.data?.meta {
                if let parameters = metadata.parameters {
                    ParameterGalleryView(core:core, sample: sample, parameters: parameters)
                }
            }
        }
    }
    
    private func dataView() -> some View {
        VStack {
            if let data = query?.data,
               let eventData = data.data,
               let parameters = data.meta.parameters {
                Table(eventData) {
                    TableColumn("#") { e in
                        Text("\(e.id)")
                    }
                    TableColumnForEach(0..<parameters.count, id: \.self) { index in
                        TableColumn("\(parameters[index].displayName)") { e in
                            Text(String(format: "%.2f", e.values[index]))
                        }
                    }
                }
            }
            
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
                ForEach(parameters, id: \.name) { parameter in
                    ParameterInspectorView(core:core, sample:sample, parameter: parameter)
                }
            }
            .padding()
        }
    }
}
