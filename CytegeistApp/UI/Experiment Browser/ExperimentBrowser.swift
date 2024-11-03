//
//  ExperimentBrowser.swift
//  CytegeistApp
//
//  Created by Adam Treister on 9/17/24.
//

import Foundation
import SwiftUI
import CytegeistLibrary
import CytegeistCore
import UniformTypeIdentifiers

struct ExperimentBrowser : View {
    
    @Environment(App.self) var app: App

    var body: some View {
        NavigationSplitView {    browserSidebar    }
        content:        {
            panelA.navigationSplitViewColumnWidth(min: 200, ideal: 700, max: .infinity)
        }
        detail: {
            panelB.navigationSplitViewColumnWidth(min: 300, ideal: 600, max: .infinity)
            
        }
        .task {   getDataFromSheet()     }
    }
    //-------------------------------------------------------------------
    @State var showImporter = false
    @State var firstManuscript = false
    @State var hasWorkspace = false
    @State var useCytof = false
    @State var cytof = false
    @State var searchText: String = ""
 
  //-------------------------------------------------------------------
    var browserSidebar :  some View {

        VStack {
            Text("FlowRepository").font(.title3)
            Text("\(filteredExperiments.count) of \(experimentDB.count)")
            HStack {
                Toggle("Unique manuscipts", isOn:  $firstManuscript)
                Spacer()
            }
            HStack {
                Toggle("Mass Cytometry", isOn: $useCytof)
                Toggle("Include", isOn: $cytof)
                Spacer()
            }
            HStack {
                Toggle("Workspace Included", isOn:  $hasWorkspace)
                Spacer()
            }
            HStack {
                TextField("Search:", text: $searchText)
                    .font(.body)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing, 24)
                Spacer()
            }
        }.padding(20)
    }
    
    var panelA: some View {
        FRExperimentTable(selection:$selectedExperiment, sortOrder: $sortOrder, experiments:filteredExperiments)
    }
    @ViewBuilder
    var panelB : some View {
         let experiment = experimentDB.first { selectedExperiment == $0.id }
        
        if let experiment {
            FlowRepoDetailView(exp: experiment)
                .offset(x: 16, y: 16)
        } else {
            Text("Select an experiment")
        }
        
    }
 
//    }
        //---------------------------------------------------------------------------
    func getDataFromSheet() {
        let urlString = "https://docs.google.com/spreadsheets/d/1qn1K2usdhI1wMEagrTcWWhsFMWEDwy2HG2WykMT0KPY?output=csv"
        
        guard let url = URL(string: urlString) else { print("error"); return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let content = String(data: data, encoding: .utf8) {
                 
                    let str = content.withoutHtmlTags()
                    print(str.prefix(3000))
                        parseCSV(content)
                }
            }
        }.resume()
//        do {
//            let html = "<html><head><title>First parse</title></head>"
//            + "<body><p>Parsed HTML into a doc.</p></body></html>"
//            let doc: Document = try SwiftSoup.parse(html)
//            return try doc.text()
//        } catch Exception.Error(let type, let message) {
//            print(message)
//        } catch {
//            print("error")
//        }
//        do {
//            let attributed = try NSAttributedString(data: str,
//                                                    options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
//            print(attributed.string)
//            
//        } catch () {}
//        
        
 
        let fileUrl = DemoData.testDataRoot?.appendingPathComponent("flowrepo.csv")
        do {
            let csvData = try String(contentsOf: fileUrl!)
            parseCSV(csvData)
        } catch {
            print("Error reading FlowRepo CSV data: \(error)")
        }
    }
 
    
    @State private var experimentDB = [FRExperiment]()
    @State private var selectedExperiment:FRExperiment.ID?
    @State  var sortOrder: [KeyPathComparator<FRExperiment>] =
    [
        .init(\.LastUpdate, order: .reverse),
        .init(\.MifScore, order: .reverse),
        .init(\.Design_FCS_Count, order: .reverse),
        .init(\.Cytometer, order: .forward),
        .init(\.hasWSP, order: .forward)
    ]
    func addFRExperiment(exp: FRExperiment)
    {
        experimentDB.append(exp)
    }
    func addRecord(_ currentRow: String)
    {
        let fields = parseLine(currentRow)
        if fields.count > 30 {         // && fields[0].starts(with: "FR-FCM"))
            
            let record = FRExperiment(tokens: fields)
            let cytof = searchCytof(currentRow)
            let firstManuscript = searchUniqueManuscript(record)
            record.setFlags(cytof: cytof, firstManuscript: firstManuscript, fulltext: currentRow)
            experimentDB.append(record )
        }
        
    }
    let debug = false
    var filteredExperiments: [FRExperiment] {
        
        var   experiments = experimentDB.filter {
               
            if (!debug && $0.RepID.prefix(6) != "FR-FCM") {  return false  }
            if (hasWorkspace && $0.hasWSP.isEmpty) {  return false  }
            if (useCytof && ($0.cytof != cytof)) {  return false  }
            if (firstManuscript && !$0.firstManuscript) {  return false  }
            if (searchText.count > 2 && !$0.fulltext.containsIgnoringCase(searchText))  {  return false  }
            return true
        }
        
        return experiments.sorted(using: sortOrder)
    }
 
    public struct FRExperimentTable : View {
        
        static let columnDefs:[TableColumnField<FRExperiment>] = [
            TableColumnField("RepID", \.RepID),
            TableColumnField("LastUpdate", \.LastUpdate),
            TableColumnField("MifScore", \.MifScore),
            TableColumnField("ExpName", \.ExpName),
            TableColumnField("Researcher", \.PResearcher),
            TableColumnField("PubmedID", \.ManuscriptUrl),
            TableColumnField("Cytometer", \.Cytometer),
            TableColumnField("#Files", \.FCS_count),
            TableColumnField("FCS_total_MB", \.FCS_total_MB),
            TableColumnField("Event_mean_K", \.Event_mean_K),
            TableColumnField("Workspace", \.hasWSP),
            TableColumnField("Keywords", \.Keywords),
            TableColumnField("Investigator", \.PInvestigator),
            TableColumnField("ExpEnd", \.ExpEnd),
            TableColumnField("FCSVers", \.FCSVers)
         ]
            //        TableColumnField("Design_FCS_Count", \.Design_FCS_Count),
            //        TableColumnField("Purpose", \.Purpose),
            //        TableColumnField("Conclusion", \.Conclusion),
            //        TableColumnField("Comments", \.Comments),
            //        TableColumnField("Manuscripts", \.Manuscripts),
            //        TableColumnField("Design", \.Design),
            //        TableColumnField("UploadAuth", \.UploadAuth),
            //        TableColumnField("ExpDates", \.ExpDates),
            //        TableColumnField("ExpStart", \.ExpStart),
            //        TableColumnField("UploadDate", \.UploadDate),
            //        TableColumnField("Organizations", \.LastUpdate),
            //        TableColumnField("Funding", \.Funding),
            //        TableColumnField("QualControl", \.QualControl),
            //        TableColumnField("QualControlUrl", \.QualControlUrl),
            //        TableColumnField("Attachments", \.Attachments),
            //        TableColumnField("Event_total_K", \.Event_total_K),
            //        TableColumnField("ExpID", \.ExpID)

        
        @Binding var selection:FRExperiment.ID?
        @Binding var sortOrder:[KeyPathComparator<FRExperiment>]
        @State var columnCustomization = TableColumnCustomization<FRExperiment>()
        
        let experiments:[FRExperiment]
  
        
        public var body: some View {
            Table (experiments, 
                   selection: $selection,
                   sortOrder: $sortOrder,
                   columnCustomization: $columnCustomization)
            {
                TableColumnForEach(Self.columnDefs) { def in
                    def.defaultColumn().customizationID(def.name)
                }
            }
            .frame(minWidth: 300, idealWidth: 600)
        }
    }
    //--------------------------------------------------------------------------------------
    @MainActor
    func  processDB(result: Result<URL, any Error> ) {
        switch result {
            case .success(let file):
                Task {
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    if !gotAccess { return }
                    do {
                        let csvData = try Data(contentsOf: file)
                        let csvString = String(data: csvData, encoding: .utf8)!
                        allManuscripts.removeAll()
                        parseCSV(csvString)
                    } catch {
                        print("Error fetching CSV file: \(error)")
                    }
                    file.stopAccessingSecurityScopedResource()     // release access
                }
            case .failure(let error):
                print(error)         // handle error
        }
    }
    
    
   func parseCSV(_ csvString: String)   {
        var currentRow = ""
       var inQuotes = false
//       var backslashed = false
//        var parsedLines: [String] = []
        for char in csvString {
//            if backslashed  { backslashed = false; continue}
//            if char == "\\" { backslashed = true; continue }
            if char == "\"" { inQuotes.toggle()            }
            
                // note that \r\n is one character which doesnt match \n
            if (char == "\r\n" || char == "\n") && !inQuotes {
//                parsedLines.append(currentRow)
                addRecord(currentRow)
                currentRow = ""
            } else {
                currentRow.append(char)
            }
        }
        
       if !currentRow.isEmpty {
           addRecord(currentRow)
       }
    }
   
    func parseLine(_ csvString : String) -> [String]
    {
        var fields: [String] = []
        var inQuotes = false
//        var backslashed = false
        var currentBuffer = ""
        
        for char in csvString {
//            if backslashed  { backslashed = false; continue}
//            if char == "\\" { backslashed = true; continue }
            if char == "\"" { inQuotes.toggle() }
            else if char == "," && !inQuotes {
                fields.append(currentBuffer)
                currentBuffer = ""
            } else { currentBuffer.append(char)  }
        }
        if currentBuffer.count > 0 {
            fields.append(currentBuffer)
        }
        return fields
        
    }
 

}
    //--------------------------------------------------------------------------------------

func searchCytof(_ s: String) -> Bool{
    if s.containsIgnoringCase("mass cytometry"){  return true}
    if s.containsIgnoringCase("DVSSciences"){  return true}
    if s.containsIgnoringCase("cytof") &&  !s.containsIgnoringCase("cytoflex")
    {  return true}
    return false

}

var allManuscripts = [String]()
func searchUniqueManuscript(_ exp: FRExperiment) -> Bool{
    if exp.Manuscripts.isEmpty { return false   }
    if (allManuscripts.contains(exp.Manuscripts)){ return false   }
    allManuscripts.append(exp.Manuscripts)
    return true
}

