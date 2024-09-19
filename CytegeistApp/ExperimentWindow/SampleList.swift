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


import SwiftUI

    // The sample table view for an experiment.
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
    
    @SceneStorage("viewMode") private var mode: SampleListMode = .table
    @State var searchText: String = ""
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
    
    var selection:Set<Sample.ID> { experiment.selectedSamples }
    
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
        @Bindable var experiment = experiment
        
        return Table(filteredSamples, selection: $experiment.selectedSamples, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumnForEach(columns) { column in
                column.defaultColumn()
                    .customizationID(column.name)
            }
        }
        .onDeleteCommand {
            experiment.samples.removeAll { experiment.selectedSamples.contains($0.id) }
            experiment.selectedSamples.removeAll()
        }
        .onChange(of: experiment.id) {
            experiment.selectedSamples.removeAll()
        }
    }
    
    var footer: some View {
        let selectedText = selection.isEmpty ? "" : " (\(selection.count) selected)"
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
//        .focusedSceneValue(\.selection, $selectedSamples)
//        .toolbar {
//            ToolbarItem(placement: .navigation) {
//            }
//        }

        .navigationTitle($experiment.name)
        //        .navigationSubtitle("\(experiment.creationDate)")
//        .importsItemProviders(selection.isEmpty ? [] : Sample.importImageTypes) { providers in
//            Sample.importImageFromProviders(providers) { url in
//                for sampleID in selection {
//                    experiment[sampleID]?.imageURL = url
//                }
//            }
//            
//        }
        .fileImporter( isPresented: $showFCSImporter,
                       allowedContentTypes: [.item,  .directory],
                       allowsMultipleSelection: true)
        { result in
            switch result {
            case .success:  experiment.onFCSPicked(_result: result)       // gain access to the directory
            case .failure(let error):  print(error)         // handle error
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Buttons.toolbar("Open FCS Files", .add) { showFCSImporter = true }
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
            fileInfo = []
            var gotFile = false
            
            for itemProvider in info.itemProviders(for: ["public.file-url"]) {
                itemProvider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data {
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
           if path.hasSuffix(".fcs")  {
               print ("ADD FCS")  // store.readFCSFileLater(url)
           }
           else { print ("ignored") }

       }
    }
}

