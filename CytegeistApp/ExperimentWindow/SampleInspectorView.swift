//
//  SampleInspectorView.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/1/24.
//

import Foundation
import SwiftUI
import CytegeistCore
import CytegeistLibrary

@MainActor
public struct SampleInspectorView: View {
    let experiment: Experiment
    let sample: SampleRef
    @State var query: APIQuery<FCSFile>?
//    @State var data: FCSFile?
    
    
    public init(_ experiment: Experiment, sample: SampleRef) {
        self.experiment = experiment
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
            query = experiment.core.loadSample(SampleRequest.init(sample, includeData:false))
        }
    }
    
    private func keywordsView() -> some View {
        VStack {
            Text("Keywords")
                .font(.title)
            if let keywords = query?.data?.meta.keywords {
                KeywordsTable(keywords: keywords)
            }
        }
    }
    
    private func parameterGalleryView() -> some View {
        VStack {
            if let metadata = query?.data?.meta {
                if let parameters = metadata.parameters {
                    ParameterGalleryView(core:experiment.core, sample: sample, parameters: parameters)
                }
            }
        }
    }
//    public init() {}

    private func dataView() -> some View {
        VStack {
            if let data = query?.data,
               let eventData = data.data,
               let parameters = data.meta.parameters {
                Table(eventData) {
                    TableColumn("#") { e in
                        Text("\(e.id)")
                    }
                    if #available(macOS 14.4, *) {
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
}

public struct KeywordsTable: View {
    let keywords:[StringField]
    @State var filter:String = ""
    
    public var body: some View {
        let filtered = keywords.filter {
            $0.name.localizedCaseInsensitiveContains(filter) ||
            $0.value.localizedCaseInsensitiveContains(filter)
        }
        Table(filtered) {
            TableColumn("Name", value:\.name)
            TableColumn("Value", value:\.value)
        }
        .searchable(text:$filter)
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
    let parameters: [CDimension]
    public var body: some View {
        
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(parameters, id: \.name) { parameter in
//                    ParameterInspectorView(core:core, sample:sample, parameter: parameter)
                }
            }
            .padding()
        }
    }
}
