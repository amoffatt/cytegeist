//
//  ExperimentStore.swift
//  filereader
//
//  Created by Adam Treister on 7/28/24.
//

import Foundation
import CytegeistLibrary
import CytegeistCore
import SwiftUI



@Observable
final class App {
    
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
//    public var core = CytegeistCoreAPI()

    var experiments: [Experiment] = []
    var selectedExperiment: Experiment.ID?
//    var mode: SampleListMode = .table
//    var reportMode: ReportMode = .gating
    
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
//    private func loadExperiments(from storeFileData: Data) -> [Experiment] {
//        do {
//            let decoder = JSONDecoder()
//            decoder.dateDecodingStrategy = .iso8601
//                //            print(storeFileData([)in: [0, 300])
//            return try decoder.decode([Experiment].self, from: storeFileData)
//        } catch {
//            print(error)
//            return []
//        }
//    }
        //-------------------------------------------------------------------------
        //------------------------------------------------------
        // gain access to the directory and call readFCSFile
    
    
    
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
    
    /// If no experiment is selected, will return nil, unless:
    /// If autoselect is true, will selected and eturn the most recently modified experiment
    /// if createIfNil is true, will create a new experiment if none already exist
    // AM DEBUGGING DELETE this, replace with ModelList
    @discardableResult
    func getSelectedExperiment(autoselect:Bool = false, createIfNil:Bool = false) -> Experiment?
    {
        if let selectedExperiment {
            if let exp = experiments.first(where: { $0.id == selectedExperiment}) {
                return exp
            }
        }
//        if autoselect, let recent = recentExperiments.first {
//            selectedExperiment = recent.id
//            return recent
//        }
        if createIfNil {
            let exp = recentExperiments.first ?? createNewExperiment()
            selectedExperiment = exp.id
            return exp
        }
        return nil
    }
    
    @discardableResult
    func createNewExperiment() -> Experiment {
        let exp = Experiment()
        let names = experiments.map { $0.name }
        exp.name = exp.name.generateUnique(existing: names)
        experiments.append(exp)
        selectedExperiment = exp.id
        return exp
    }
    
    func removeExperiment(_ experiment:Experiment) {
        experiments.removeAll { $0.id == experiment.id }
        if selectedExperiment == experiment.id {
            selectedExperiment = experiments.sorted(by: \.modifiedDate).first?.id
        }
        
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

//
//
extension App {
    
    func experimentsModified(year: Int) -> [Experiment] {
        experiments.filter({ $0.modifiedDate[.year] == year })
    }
    
    var recentExperiments:[Experiment] {
        experiments.sorted(by: \.modifiedDate)
    }
//    
//    var experimentsByYearCreated:[(year:Int, experiments:[Experiment])] {
//        let calender = Calendar.current
//        let grouped = Dictionary(grouping: experiments, by: { $0.modifiedDate[.year] })
//        return grouped
//            // sort years
//            .sorted { $0.key < $1.key }
//            // Sort experiments within group
//            .map { (year, experiments) in
//                (year, experiments.sorted { $0.modifiedDate < $1.modifiedDate })
//            }
//    }

//    var currentYear: Int { 2021 }
//
//    var previousYears: ClosedRange<Int> { (2018...2021) }
}

