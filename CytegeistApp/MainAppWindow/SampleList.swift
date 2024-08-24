//
//  ExperimentDetail.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import Foundation
import UniformTypeIdentifiers
import CytegeistCore
import CytegeistLibrary
/*
See LICENSE folder for this sample’s licensing information.

Abstract:    The sample table view for an experiment.
*/

import SwiftUI

extension SampleList
{
        // access to the samples with filter and sort applied
    var filteredSamples: [Sample] {
        var samples  = experiment.samples
//        print (samples.count)
        
        if !searchText.isEmpty {
            samples = samples.filter {
                for column in columns {
                    if column.value(from: $0).localizedCaseInsensitiveContains(searchText) {
                        return true
                    }
                }
                return false
            }
        }
        
        return samples
            .sorted(using: sortOrder)
    }
    
}

extension TableColumnField<Sample> {
    init(keyword: String) {
        self.init(keyword, \.self[keyword] )
    }
}

extension Sample {
    var eventCountString: String { String(eventCount) }
}



struct SampleList: View {
    var experiment: Experiment
    @State var columnCustomization = TableColumnCustomization<Sample>()

    @Environment(App.self) var app: App
    
    @SceneStorage("viewMode") private var mode: ViewMode = .table
    @State var searchText: String = ""
    @State private var selectedSamples = Set<Sample.ID>()
    @State var sortOrder: [KeyPathComparator<Sample>] = [    .init(\.id, order: SortOrder.forward) ]
    @State private var draggedItem: String?
    @State private var showFCSImporter = false
    @State private var isDragging = false
    @State private var isDropTargeted = false
    @State private var fileInfo: [String] = []
    
    @State private var columns:[TableColumnField<Sample>] = [
        .init("Name", \.tubeName),
        .init(keyword: FCSKeys.fil),
        .init("Count", \.eventCountString ),
        .init(keyword: FCSKeys.btim),
        .init(keyword: FCSKeys.cyt),
        .init(keyword: FCSKeys.sys),
        .init(keyword: FCSKeys.setup),
        .init(keyword: FCSKeys.creator),
    ]
//    @StateObject var store: Store

//    let colMap = [ ["Name", .tubeName], ["FIL", .experimentName], ["CYT", .cytometer], ["BTIM", .btime],
//                   ["SYS", .sys], ["Count", .cellCount], ["SETUP", .setup1], ["EXP", .creator] ]
    
    
    var header: some View {
        
        return HStack {
            TextField("Search Samples", text: $searchText)
                .font(.body)
                .textFieldStyle(.roundedBorder)
                .padding(.trailing, 24)
            Spacer()
            
//                    DisplayModePicker(mode: $mode)
        }
    }
    
    var table: some View
    {
        
        return Table(filteredSamples, selection: $selectedSamples, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumnForEach(columns) { column in
                column.defaultColumn()
                    .customizationID(column.name)
            }
//            TableColumn("Name", value: \.tubeName)          { sample in Text(sample.tubeName)}.customizationID("tubeName")
//            TableColumn("$FIL", value: \.experimentName)    { sample in Text(sample.experimentName)  }.customizationID("experimentName")
//            TableColumn("Count", value: \.cellCount)        { sample in Text(String(sample.cellCount))  }.customizationID("cellCount")
//            TableColumn("$BTIM", value: \.btime)            { sample in Text(sample.btime)  }.customizationID("btime")
//            TableColumn("$CYT", value: \.cytometer)         { sample in Text(sample.cytometer)  }.customizationID("cytometer")
//            TableColumn("$SYS", value: \.sys)               { sample in Text(sample.sys)  }.customizationID("sys")
//            TableColumn("SETUP", value: \.setup1)           { sample in Text(sample.setup1)  }.customizationID("setup1")
//            TableColumn("$Creator", value: \.creator)       { sample in Text(sample.creator)  }.customizationID("creator")
        }
        .onDeleteCommand {
            experiment.samples.removeAll { selectedSamples.contains($0.id) }
            selectedSamples.removeAll()
        }
        .onChange(of: experiment.id) {
            selectedSamples.removeAll()
        }
//        rows: {
//            ForEach(samples) { sample in
//                TableRow(sample)
//                    .itemProvider { sample.itemProvider }
//            }
//            .onInsert(of: [Sample.draggableType]) { index, providers in
//                Sample.fromItemProviders(providers) { samples in
//                    self.experiment.samples.insert(contentsOf: samples, at: index)
//                }
//            }
//            .onDelete(perform: { indexSet in
//            })
//        }
    }
    
    var footer: some View {
        let selectedText = selectedSamples.isEmpty ? "" : " (\(selectedSamples.count) selected)"
        return HStack {
            Spacer()
            Text("\(filteredSamples.count) samples \(selectedText)")
        }
    }
    
 

    var body: some View
    {
        @Bindable var experiment = experiment
        let dropDelegate = CDropDelegate(fileInfo: $fileInfo)
//        let expName: String = experiment.name
        VStack(spacing: 0) {
            header
                .padding(6)
                .padding(.trailing, 10)
            
            Group {
                table
//                switch mode {
//                case .table:       alttable
//                    
//                case .gallery:     SampleGallery(experiment: experiment, selection: $selectedSamples)
//                }
            }
            footer
                .padding(6)
        }
        .onDrop(of: ["public.file-url"], delegate: dropDelegate)
//        .focusedSceneValue(\.experiment, experiment)
        .focusedSceneValue(\.selection, $selectedSamples)
//        .toolbar {
//            ToolbarItem(placement: .navigation) {
//            }
//        }

        .navigationTitle($experiment.name)
        //        .navigationSubtitle("\(experiment.creationDate)")
        .importsItemProviders(selectedSamples.isEmpty ? [] : Sample.importImageTypes) { providers in
            Sample.importImageFromProviders(providers) { url in
                for sampleID in selectedSamples {
                    experiment[sampleID]?.imageURL = url
                }
            }
            
        }
        .fileImporter( isPresented: $showFCSImporter,
                       allowedContentTypes: [.item,  .directory],
                       allowsMultipleSelection: true)
        { result in
            switch result {
            case .success:  app.onFCSPicked(_result: result)       // gain access to the directory
            case .failure(let error):  print(error)         // handle error
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Open FCS Files", systemImage: "plus") { showFCSImporter = true }
//                Buttons.icon("Open FCS Files", .add, action: { showFCSImporter = true } )
//                    .buttonStyle(DefaultButtonStyle())
            }

        }

    }

//--------------------------------------------------------
// table sorting
    
    
//--------------------------------------------------------
// accept files dropped from the Finder
    
   struct CDropDelegate: DropDelegate {
        @Binding var fileInfo: [String]
       
       func validateDrop(info: DropInfo) -> Bool {
            return info.hasItemsConforming(to: ["public.file-url"])
        }
      
        func performDrop(info: DropInfo) -> Bool {
                //        NSSound(named: "Sosumi")?.play()
            fileInfo = []
            var gotFile = false
//            print ( info.itemProviders(for: ["public.file-url"]) )
            
            for itemProvider in info.itemProviders(for: ["public.file-url"]) {
                itemProvider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data {
//                        print (data)
                        if let url = URL(dataRepresentation: data, relativeTo: nil) {
                            let theInfo = "File: \(url.lastPathComponent) \nPath: \(url.path)\n"
                            let theSizes = FileInfo.reportSizes(url: url)
                            DispatchQueue.main.async {
                                fileInfo.append(theInfo + theSizes)
                                process(url)
                                gotFile = true
                            }
                        }
                    }
                }
            }
            return gotFile
        }
 
       func process(_ url: URL)
       {
           let path = url.path
           print (path)
          if url.isDirectory
           {
              let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
              let enumerator = FileManager.default.enumerator(at: url,
                                                              includingPropertiesForKeys: resourceKeys,
                                                              options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                  print("directoryEnumerator error at \(url): ", error)
                  return true
              })!
              while let filename = enumerator.nextObject() as? URL {
                  process(filename)
              }
              
          }
           if path.hasSuffix(".fcs")
           {
                   //                                    store.readFCSFileLater(url)
               print ("ADD FCS")
           }
           else { print ("ignored") }

       }
    }
}

