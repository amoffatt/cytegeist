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
        return samples.sorted(using: sortOrder)
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

public class FCSKeys {
    public static let
    fil = "$FIL", btim = "$BTIM",
    cyt = "$CYT", sys = "$SYS", src = "$SRC",
    setup = "SETUP", creator = "$Creator"
}

enum ImportFileType {
    case Sample, Workspace
}

struct SampleList: View {
    var experiment: Experiment
    @State var columnCustomization = TableColumnCustomization<Sample>()

    @Environment(App.self) var app: App
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) var modelContext
    @Environment(\.openWindow) var openWindow
    
    @State private var isCompact = false

        
    @SceneStorage("viewMode") private var mode: SampleListMode = .table
    @State var searchText: String = ""
    @State var sortOrder: [KeyPathComparator<Sample>] = [    .init(\.id, order: SortOrder.forward) ]
    @State private var draggedItem: String?
    @State private var showFCSImporter = false
//    @State private var showWSPImporter = false
    @State private var fileImporterInfo:(type:ImportFileType, contentTypes:[UTType], multiselect:Bool)? = nil
    @State private var isDragging = false
    @State private var isDropTargeted = false
    @State private var fileInfo: [String] = []
    
    @State private var columns:[TableColumnField<Sample>] = [
        .init("Name", \.tubeName),
        .init(keyword: FCSKeys.fil),
//        .init("Count", \.eventCountString ),
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
//            Toggle("<>", isOn: $isCompact)
//                .onChange(of: isCompact) {
//                    print("Action")
//                }
            
//            SampleListModePicker(mode: $mode)
        }
    }


    var table: some View
    {
        @Bindable var experiment = experiment
        
        return Table(filteredSamples, selection: $experiment.selectedSamples, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumnForEach(columns) { column in
                column.defaultColumn()
                    .customizationID(column.name)
                    .defaultVisibility(column.hidden ? Visibility.hidden : Visibility.visible)
            }
            TableColumn("Count", value:\.eventCount) { item in
                Text("\(item.eventCount)")
            }
        }
        .onDeleteCommand {
            experiment.samples.removeAll { experiment.selectedSamples.contains($0.id) }
            experiment.selectedSamples.removeAll()
        }
        .onChange(of: experiment.id) {
            experiment.selectedSamples.removeAll()
        }
        .contextMenu(forSelectionType: Sample.ID.self) { items in
                // ...  AT -- adding SampleInspectorView to double click of sample row
        } primaryAction: { items in

            for i in items {
                print(i)
//                SampleInspectorView(experiment, sample: i.ref)
                if let sample = experiment[i] {
                    openWindow(id: "sample-inspector", value:ExperimentSamplePair(sample: sample, experiment: experiment))
                }
             }
            
        }  }
    
    var footer: some View {
        let totalCount = filteredSamples.map { $0.eventCount }.sum()
        let selectedText = selection.isEmpty ? "" : " (\(selection.count) selected)"
        return HStack {
            Spacer()
            Text("\(filteredSamples.count) samples \(selectedText) (\(totalCount) total events)")
        }
    }
 
    var body: some View
    {
        @Bindable var experiment = experiment
        let dropDelegate = CDropDelegate(fileInfo: $fileInfo)
        let showImporter = Binding(get: {
            fileImporterInfo != nil
        }, set: {
            fileImporterInfo = nil
        })
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
        .navigationSubtitle("\(experiment.creationDate)")
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
                case .success:  onFCSPicked(_result: result)       // gain access to the directory
                case .failure(let error):  print(error)         // handle error
            }
        }

/*
        .fileImporter( isPresented: fileImporterInfo?.showImporter,           // || $showWSPImporter
                       allowedContentTypes: fileImporterInfo?.types ?? [],
                       allowsMultipleSelection: fileImporterInfo?.multiselect ?? false)
        { result in
            switch fileImporterInfo.type {
                case Sample:
                    switch result {
                        case .success:   onFCSPicked(_result: result)      // gain access to the directory
                        case .failure(let error):  print(error)         // handle error
                    }
                case Workspace:
                    switch result {
                        case .success:  onWSPPicked(_result: result)       // gain access to the directory
                        case .failure(let error):  print(error)         // handle error
                    }
                default: print (":")
                }
                    
            }
*/
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Buttons.toolbar("Open FCS Files", .add) { showFCSImporter = true }//{ fileImporterInfo?.type = .Sample }
//                    Buttons.toolbar("Dictionary", Icon("pencil")) {      experiment.buildVaribleKeyDictionary()    }
                    Buttons.toolbar("Dictionary", Icon("pencil")) {   fileImporterInfo?.type = .Workspace   }
//                    Buttons.toolbar("Clear", Icon("delete.left")) { doClear() }
                  Buttons.toolbar("XML", Icon("cloud")) {
                        print(experiment.xml())
                    }
                } }

        }

    }
    func onWSPPicked(_result: Result<[URL], any Error>)
    {
        Task {
            do {
                    //                try print("FCSPicked urls: ", _result.get().map(editStr($0.description)))
                for url in try _result.get()
                {
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    if !gotAccess { break }
                    await readWorkspaceFile(url)
                    url.stopAccessingSecurityScopedResource()     // release access
                }
            }
            catch let error as NSError {
                debug("Ooops! Something went wrong: \(error)")
            }
        }
    }
    
    func onFCSPicked(_result: Result<[URL], any Error>)
    {
        Task {
            do {
                    //                try print("FCSPicked urls: ", _result.get().map(editStr($0.description)))
                for url in try _result.get()
                {
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    if !gotAccess { break }
                    await readFCSFile(url)
                    url.stopAccessingSecurityScopedResource()     // release access
                }
            }
            catch let error as NSError {
                debug("Ooops! Something went wrong: \(error)")
            }
        }
    }

    public func readFCSFile(_ url: URL) async
    {
        if  url.isDirectory
        {
            let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
            let fcsFiles = walkDirectory(at: url, options: options).filter {  $0.pathExtension == "fcs"  }
            for await item in fcsFiles { await readFCSFile(item) }
            return
        }
        
        do  {
            let sample = Sample(ref: SampleRef(url: url))
            sample.setUp(core: experiment.core)
            addSample(sample)
        }
            //        catch let err as NSError {
            //            debug("Ooops! Something went wrong: \(err)")
            //        }
        debug("FCS Read")
    }
 
    func readWorkspaceFile(_ url:URL) async
    {
        let reader = WorkspaceReader()
        do {
            let ws = try await  reader.readWorkspaceFile(at: url)
            let _ = Experiment(ws: ws )
            print("WS of length: ", ws.text.count)
        }
        catch let error as NSError {
            debug("Ooops! Something went wrong: \(error)")
        }
    }
        
    public func addSample(_ sample: Sample)   {
//        modelContext.insert(sample)
        experiment.samples.append(sample)
    }

    
        // Recursive iteration
    func walkDirectory(at url: URL, options: FileManager.DirectoryEnumerationOptions ) -> AsyncStream<URL> {
        AsyncStream { continuation in
            Task {
                let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: options)
                while let fileURL = enumerator?.nextObject() as? URL {
                    print(fileURL)
                    if fileURL.hasDirectoryPath {
                        for await item in walkDirectory(at: fileURL, options: options) {
                            continuation.yield(item)
                        }
                    } else {  continuation.yield( fileURL )    }
                }
                continuation.finish()
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
//            fileInfo = []
            var gotFile = false
            
            for itemProvider in info.itemProviders(for: ["public.file-url"]) {
                itemProvider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data {
                        if let url = URL(dataRepresentation: data, relativeTo: nil) {
//                            let theInfo = "File: \(url.lastPathComponent) \nPath: \(url.path)\n"
//                            let theSizes = FileInfo.reportSizes(url: url)
                            DispatchQueue.main.async {
//                                fileInfo.append(theInfo + theSizes)        // 
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
           if !url.isFileURL
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

