//
//  ExperimentStore.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import Foundation
import CytegeistLibrary
import CytegeistCore



// switch between table and gallery views
enum ViewMode: String, CaseIterable, Identifiable {
    var id: Self { self }
    case gallery
    case table
}

    // switch between table and gallery views
enum ReportMode: String, CaseIterable, Identifiable {
    var id: Self { self }
    case gating
    case table
    case layout
}


final class Store: ObservableObject {
    var experiments: [Experiment] = []
    var selectedExperiment: Experiment.ID?
    @Published var mode: ViewMode = .table
    @Published var reportMode: ReportMode = .gating
    
//    private var applicationSupportDirectory: URL {
//        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//    }

    private var databaseFileUrl: URL? {
            //        applicationSupportDirectory.appendingPathComponent(filename)
            //        let data = Data(contents : <#T##URL#>)
        return Bundle.main.url(forResource:"database", withExtension: "json")           //private var filename = "database.json"
    }
    
        //-------------------------------------------------------------------------
   init() {
        do {
//            if let databaseUrl = databaseFileUrl {
//                let data = try Data(contentsOf: databaseUrl)
//                experiments = loadExperiments(from: data)
//            } else {
//                if let bundledDatabaseUrl = Bundle.main.url(forResource: "database", withExtension: "json") {
//                    if let data = FileManager.default.contents(atPath: bundledDatabaseUrl.path) {
//                        experiments = loadExperiments(from: data)
//                    }
//                } else {
//                    experiments = []
//                }
//            }
//        } catch {
//            print("Error loading Store database: \(error)")
        }
    }
        //-------------------------------------------------------------------------
    private func loadExperiments(from storeFileData: Data) -> [Experiment] {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
                //            print(storeFileData([)in: [0, 300])
            return try decoder.decode([Experiment].self, from: storeFileData)
        } catch {
            print(error)
            return []
        }
    }
        //-------------------------------------------------------------------------
        //------------------------------------------------------
        // gain access to the directory and call readFCSFile
    
    
    func onFCSPicked(_result: Result<[URL], any Error>)
    {
        Task {
            do {
                try print("FCSPicked urls: ", _result.get())
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
    
   var fcsWaitList: [URL] = []
    func readFCSFileLater(_ url:URL)
    {
        fcsWaitList.append(url)
    }
    func processWaitList() async
    {
        for url in fcsWaitList {
           await readFCSFile(url)
        }
    }
    
    func readFCSFile(_ url:URL) async
    {
        let exp = getSelectedExperiment()
        await exp.readFCSFile(url)
    }

    func readFCSFiles(_ urls:[URL]) async
    {
        for url in urls  {
            await readFCSFile(url)
        }
    }
    
        //-------------------------------------------------------------------------
// subscript(experimentID: Experiment.ID?) -> Experiment? {
//        get {
//            if let id = experimentID {
//                return experiments.first(where: { $0.id == id })// ?? .placeholder
//            }
//            return nil//.placeholder
//        }
//        
//        set(newValue) {
//            if let id = experimentID {
//                experiments[experiments.firstIndex(where: { $0.id == id })!] = newValue
//            } else {
////                experiments.append(newValue)
//            }
//        }
//    }
    
        //-------------------------------------------------------------------------
  func append(_ experiment: Experiment) {
        experiments.append(experiment)
    }
    
        //-------------------------------------------------------------------------
   func getSelectedExperiment() -> Experiment
    {
        if let exp = experiments.first(where: { $0.id == selectedExperiment}) {
            return exp
        }
        let exp = createNewExperiment()
        selectedExperiment = exp.id
        
        return exp
//        ?? .placeholder
    }
    
    func createNewExperiment() -> Experiment {
        let exp = Experiment()
        experiments.append(exp)
        return exp
    }
    
    
        //-------------------------------------------------------------------------
   func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(experiments)
            if let databaseFileUrl {
                if FileManager.default.fileExists(atPath: databaseFileUrl.path) {
                    try FileManager.default.removeItem(at: databaseFileUrl)
                }
                try data.write(to: databaseFileUrl)
            }
            else {
                print("Database file url is nil")
            }
            
        } catch {
                //..
        }
    }
 }



extension Store {

    func experiments(in year: Int) -> [Experiment] {
        experiments.filter({ $0.year == year })
    }

    var currentYear: Int { 2021 }

    var previousYears: ClosedRange<Int> { (2018...2021) }
}
