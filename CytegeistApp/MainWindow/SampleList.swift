//
//  ExperimentDetail.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import Foundation
import UniformTypeIdentifiers
/*
See LICENSE folder for this sample’s licensing information.

Abstract:    The sample table view for an experiment.
*/

import SwiftUI

extension SampleList
{
        // access to the samples with filter and sort applied
    var samples: [Sample] {
        let samples  = store.getSelectedExperiment().samples
        print (samples.count)
        
        return samples
            .filter {
                searchText.isEmpty ? true : $0.variety.localizedCaseInsensitiveContains(searchText)
            }
            .sorted(using: sortOrder)
    }
    
}


struct SampleList: View {
    var experiment: Experiment
    @State var columnCustomization = TableColumnCustomization<Sample>()

    @EnvironmentObject var store: Store
    @SceneStorage("viewMode") private var mode: ViewMode = .table
    @State var searchText: String = ""
    @State private var selectedSamples = Set<Sample.ID>()
    @State var sortOrder: [KeyPathComparator<Sample>] = [    .init(\.id, order: SortOrder.forward) ]
    @State private var draggedItem: String?
    @State private var showFCSImporter = false
    @State private var isDragging = false
    @State private var isDropTargeted = false
    @State private var fileInfo: [String] = []
//    @StateObject var store: Store

//    let colMap = [ ["Name", .tubeName], ["FIL", .experimentName], ["CYT", .cytometer], ["BTIM", .btime],
//                   ["SYS", .sys], ["Count", .cellCount], ["SETUP", .setup1], ["EXP", .creator] ]


    var alttable: some View
     {
       VStack {
           Text("The \(samples.count) samples in this Experiment: \(experiment.name)" )
            Table(selection: $selectedSamples, sortOrder: $sortOrder, columnCustomization: $columnCustomization)
            {
                TableColumn("Name", value: \.tubeName)          { sample in Text(sample.tubeName)}.customizationID("tubeName")
                TableColumn("$FIL", value: \.experimentName)    { sample in Text(sample.experimentName)  }.customizationID("experimentName")
                TableColumn("Count", value: \.cellCount)        { sample in Text(String(sample.cellCount))  }.customizationID("cellCount")
                TableColumn("$BTIM", value: \.btime)            { sample in Text(sample.btime)  }.customizationID("btime")
                TableColumn("$CYT", value: \.cytometer)         { sample in Text(sample.cytometer)  }.customizationID("cytometer")
                TableColumn("$SYS", value: \.sys)               { sample in Text(sample.sys)  }.customizationID("sys")
                TableColumn("SETUP", value: \.setup1)           { sample in Text(sample.setup1)  }.customizationID("setup1")
                TableColumn("$Creator", value: \.creator)       { sample in Text(sample.creator)  }.customizationID("creator")
           }
        rows: {
            ForEach(samples) { sample in TableRow(sample).itemProvider { sample.itemProvider }  }
                .onInsert(of: [Sample.draggableType]) { index, providers in
                    Sample.fromItemProviders(providers) { samples in
                        self.experiment.samples.insert(contentsOf: samples, at: index)
                    }
                }
            }
        }
     }
  
 

    var body: some View
    {
        let dropDelegate = CDropDelegate(fileInfo: $fileInfo)
//        let expName: String = experiment.name
        Group {
            switch mode {
                case .table:       alttable

                case .gallery:     SampleGallery(experiment: experiment, selection: $selectedSamples)
            }
        }.onDrop(of: ["public.file-url"], delegate: dropDelegate)
//        .focusedSceneValue(\.experiment, experiment)
        .focusedSceneValue(\.selection, $selectedSamples)
        .searchable(text: $searchText)
        .toolbar {
            Button("Read FCS File", systemImage: "plus", action: { showFCSImporter = true } )
                .bold()
                .fileImporter( isPresented: $showFCSImporter,
                               allowedContentTypes: [.item,  .directory],
                               allowsMultipleSelection: true)
                  { result in
                    switch result {
                        case .success:  store.onFCSPicked(_result: result)       // gain access to the directory
                        case .failure(let error):  print(error)         // handle error
                    }
                }
                DisplayModePicker(mode: $mode)
        }

        .navigationTitle(Text(experiment.name))         //        .navigationSubtitle("\(experiment.displayYear)")
        .importsItemProviders(selectedSamples.isEmpty ? [] : Sample.importImageTypes) { providers in
            Sample.importImageFromProviders(providers) { url in
                for sampleID in selectedSamples {
                    experiment[sampleID].imageURL = url
                }
            }
         }
    }

//--------------------------------------------------------
// table sorting

     struct BoolComparator: SortComparator {
        typealias Compared = Bool

        func compare(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
            switch (lhs, rhs) {
            case (true, false):    return order == .forward ? .orderedDescending : .orderedAscending
            case (false, true):    return order == .forward ? .orderedAscending : .orderedDescending
            default: return .orderedSame
            }
        }

        var order: SortOrder = .forward
        }
    
    
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
                            let theSizes = FileInfo().reportSizes(url: url)
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

