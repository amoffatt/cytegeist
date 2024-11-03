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

public struct ExperimentSamplePair: Codable, Hashable {
    public var sample:Sample
    public var experiment:Experiment
    public func hash(into hasher: inout Hasher) {        hasher.combine(sample )    }
}


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
            HSplitView {
                VStack {
                    TabView {
                        if let keywords = query?.data?.meta.keywords {
                            VStack {
                                KeywordsTable(keywords: keywords)
                                if let comp = query?.data?.meta.comp {
                                    CompMatrixDisplay(keyword: comp)
                                }
                            }.tabItem {
                                Label("Keywords", systemImage: "key")
                            }
                        }
                        
                        if let parameters = query?.data?.meta.parameters {
                            ParameterKeywordTable(parms: parameters).tabItem {
                                Label("Parameters", systemImage: "clock")
                            }
                        }
                       
                    }
                    
                }
                TabView {
                    VStack {
                        if let metadata = query?.data?.meta {
                            if let parameters = metadata.parameters {
                                ParameterGalleryView(core:experiment.core, sample: sample, parameters: parameters)
                            }
                        }
                    }.tabItem {
                        Label("Histograms", systemImage: "gauge")
                    }
                    if let data = query?.data {
                        
                        dataView()
                            .tabItem {
                                Label("Event Data", systemImage: "tablecells")
                            }
                    }
                }
            }
        }
        .onChange(of: sample.url, initial: true) {
            query = experiment.core.loadSample(SampleRequest.init(sample, includeData:true))
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
                    if #available(macOS 14.4, *) {
                        TableColumnForEach(0..<parameters.count, id: \.self) { index in
                            TableColumn("\(parameters[index].displayName)") { e in
                                Text(String(format: "%.0f", e.values[index]))
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
        let filteredKeys = keywords.filter {
            
            if $0.name.contains("$P") { return false }
            if filter.isEmpty { return true}
            return   $0.name.localizedCaseInsensitiveContains(filter) ||
            $0.value.localizedCaseInsensitiveContains(filter)
        }
        Table(filteredKeys) {
                TableColumn("Name", value:\.name)
                TableColumn("Value", value:\.value)
            }
            .searchable(text:$filter)
         
        }
    }
    
    public struct  CompMatrixDisplay: View {
        let keyword:String          //comma delim string starting with size
        public var body: some View {
            Text("comp").frame(minWidth: 100, minHeight: 100)
            let k = keyword
            let nums = get_numbers(stringtext: k)
            let strs = getStrList(nums: nums)
            ForEach(strs){ str in
                Text(str)
            }
        }
  
        func getStrList(nums:  [Float])  -> [String]
        {
            let sz = Int(nums[0])
            var strs = [String]()
            for row in 0..<sz {
                var s: String = ""
                for i in 0..<sz {
                    var a = "0\t"
                    let idx = i + (sz * row) + 1
                    let val = nums[idx]
                    if val == 1 { a = "1"}
                    else if abs(val) > 0.0000 {
                        a = String(format: "%0.4f\t", val)
                    }
                    s.append(a)
                }
                s.append("\n")
                strs.append(s)
            }
            return strs
        }
        
        func get_numbers(stringtext:String) -> [Float] {
            let StringRecordedArr = stringtext.components(separatedBy: ",")
            return StringRecordedArr.map { Float($0)!}
        }
    }
    
        public struct ParameterKeywordTable: View {
        let parms:[CDimension]
        public var body: some View {
            
            Table(parms) {
                TableColumn("Name", value:\.name)
                TableColumn("Stain", value:\.stain)
                TableColumn("Display", value:\.displayName)
                    //            TableColumn("Bits", value:\.displayInfo)
                    //            TableColumn("Type") { e in Text(String(e.type)) }
                TableColumn("Bits") { e in Text(String(format: "%d", e.bits)) }
                TableColumn("Range") { e in Text(String(format: "%.0f", e.range)) }
            }
        }
    }
        
        public struct ParameterGalleryView: View {
            
            
            let core: CytegeistCoreAPI
            let sample: SampleRef
            let parameters: [CDimension]
            public var body: some View {
                
                    //        ScrollView {
                
                VStack {
                    ForEach(parameters, id: \.name) { parameter in
                            //   ParameterInspectorView(core:core, sample:sample, parameter: parameter)
                        HStack {
                            Text(parameter.displayName).font(.title3).frame(width: 100)
                            HistogramView(query: core.histogram(.init(.sample(sample), .init(parameter.name)))).padding(20)
                        }
                    }
                }
                    //        }
            }
        }
    }

