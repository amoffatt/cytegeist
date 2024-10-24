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
    @State var showImporter = false

    var body: some View {
//        @Bindable var app = app
        
        NavigationSplitView {
            BrowserSidebar()
        }
    content:
        {
            PanelA()
//            TableBuilder()
                .navigationSplitViewColumnWidth(min: 200, ideal: 700, max: .infinity)
        }
    detail: {
        VStack {
            Button("Read DB", systemImage: "xmark.circle", action: { showImporter = true })
                   .fileImporter(
                       isPresented: $showImporter,
                        allowedContentTypes: [.item]
                   ) { result in processDB(result: result)   }
            PanelB()
         }
        .navigationSplitViewColumnWidth(min: 300, ideal: 600, max: .infinity)
        
    }      .onAppear {
//            readCSV()
//        let fileUrl = URL(fileURLWithPath: "/path/to/your/csv/file.csv")
//        do {
//            let parsedData = try parseCSV(fileUrl: fileUrl, experimentDB: experimentDB)
//            print(parsedData)
//        } catch {
//            print("Error parsing CSV file: \(error)")
//        }
        
    }
    }
    
        //
    struct BrowserSidebar :  View {
        
        var body : some View   {
            Text("Servers").font(.title2)
            Text("Local").font(.title3)
            Text("OMIPS").font(.title3)
            Text("FlowRepository").font(.title3)
        }
        
    }
    
    struct PanelA :  View {
        
        var body : some View
        {
            XTableView()
        }
        
    }
    struct PanelB :  View {
        
        var body : some View
        {
            MIFlowCytView().offset(x: 36, y: 36)
        }
        
    }
        //---------------------------------------------------------------------------
//    func getDataFromSheet() {
//        let urlString = "https://docs.google.com/spreadsheets/d/1qn1K2usdhI1wMEagrTcWWhsFMWEDwy2HG2WykMT0KPY?output=csv"
//        
//        
//        guard let url = URL(string: urlString) else { print("error"); return }
//        
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            if let data = data {
//                if let content = String(data: data, encoding: .utf8) {
//                    let parsedCSV: [String] = content.components(separatedBy: "\n")
//                     
//                    for line in parsedCSV {
//                        print (readTokens(line))
//                    }
//                }
//            }
//        }.resume()
//    }
// 
//    
//    func readTokens(_ s: String) -> [String]
//    {
//        var str = s
//        var tokens = [String]()
//        
//        while str.count > 0 {
//            var token = ""
//            let peek = str[str.startIndex]
//            switch peek {
//                case "\"":      let end: String.Index = str.firstIndex(of: "\"") ?? str.endIndex
//                                token = String(str[str.startIndex..<end])           // should be +1
//                                str = String(str[end..<str.endIndex])
//                                str.remove(at: str.startIndex)  // drop the quote
//                    
//                default:        let end = str.firstIndex(of: ",")  ?? str.endIndex
//                                token = String(str[str.startIndex..<end])
//                                str.removeSubrange(str.startIndex..<end)
//
//                    
//            }                                
//            if str.count > 0            { str.remove(at: str.startIndex) }
//            tokens.append(token)
//
//        }
//        return tokens
//    }
//                                                      
//    func readCSV()  {
////        getDataFromSheet()
//        let file = "/Users/adamtreister/Documents/aaron-cytegeist-1/CytegeistCore/TestData/flowrepo.csv"
//        
//        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//            
//            let fileURL = dir.appendingPathComponent(file)
//        
//            do {
//                let block = try String(contentsOf: fileURL, encoding: .utf8)
//                let lines = block.split(separator: "\n")
////                let lines: [String] = readTokens(block, delim: "\r\n")
//                for line in lines {
//                    print (readTokens(String(line)))
//                }
//        }
//            catch {   print(error)
//            }
//        }
//        
//    }
    public var experimentDB = [FRExperiment]()

    mutating func addFRExperiment(exp: FRExperiment)
    {
        experimentDB.append(exp)
    }
    
    func  processDB(result: Result<URL, any Error> ) {
        switch result {
            case .success(let file):
                Task {
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    if !gotAccess { return }
                    do {
                        try parseCSV(fileUrl: file)
                            //                                    print(parsedData)
                    } catch {
                        print("Error parsing CSV file: \(error)")
                    }
                    file.stopAccessingSecurityScopedResource()     // release access
                }
            case .failure(let error):
                print(error)         // handle error
        }
    }
    
    
   mutating func parseCSV(fileUrl: URL) throws  {
        let csvData = try Data(contentsOf: fileUrl)
        let csvString = String(data: csvData, encoding: .utf8)!
        var currentRow = ""
        var inQuotes = false
        var parsedLines: [String] = []
            //        var parsedData: [[String]] = []
        for char in csvString {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "\r\n" || char == "\n" && !inQuotes {
                parsedLines.append(currentRow)
//                parsedData.append()
                let fields = parseLine(currentRow)
                if (fields.count > 12 && fields[0].starts(with: "FR-FCM")) {
                    addFRExperiment(exp: FRExperiment(tokens: fields))
                }
                currentRow = ""
            } else {
                currentRow.append(char)
            }
        }
        
       if !currentRow.isEmpty {
            parsedLines.append(currentRow)
           let fields = parseLine(currentRow)
           if (fields.count > 12 && fields[0].starts(with: "FR-FCM")) {
               experimentDB.append( FRExperiment(tokens: fields))
           }
        }
    }
   
    func parseLine(_ csvString : String) -> [String]
    {
        var fields: [String] = []
        var inQuotes = false
        var currentBuffer = ""
        
        for char in csvString {
            if char == "\""     { inQuotes.toggle() }
            else if char == "," && !inQuotes {
                fields.append(currentBuffer)
                currentBuffer = ""
            } else { currentBuffer.append(char)  }
        }
        return fields
        
    }
        // Example usage:
        
            //        if let filepath = Bundle.main.path(forResource: inputFile, ofType: nil) {
//            do {
//                let fileContent = try String(contentsOfFile: filepath)
//                let lines = fileContent.components(separatedBy: "\n")
//                var results: [String:String] = [:]
//                lines.dropFirst().forEach { line in
//                    let data = line.components(separatedBy: ",")
//                    if data.count == 2 {
//                        results[data[0]] = data[1]
//                    }
//                }
//                return results
//            } catch {
//                print("error: \(error)") // to do deal with errors
//            }
//        } else {
//            print("\(inputFile) could not be found")
//        }
//        return [:]
     
  
         
            //        }
//    func retrieveDB(_ file: URL){
//    
//        var experimentDB = [FRExperiment]()
////        var fileRoot = Bundle.main.path(forResource: "flowrepo", ofType: "csv")
////
////      if let bundleURL =  Bundle.main.url(forResource: "flowrepo", withExtension: "csv")
////        {
//            guard let data = try? Data(contentsOf: file) else {
//                fatalError("Unable to load data")
//            }
//            if let decoder = String(data: data, encoding: .utf8)
////            if  let dataArr = decoder?.components(separatedBy: "\n") //.map({ $0.components(separatedBy: ",") })
//            {
//                let lines = decoder.components(separatedBy: .newlines).compactMap( {$0.trim().isEmpty ? nil : $0})
//                for line in lines
//                {
//                    let tokens: [String] = readTokens(String(line))
//                    experimentDB.append( FRExperiment(tokens: tokens))
//            }
//        }
//     else  { print("cant find repo")   }
//    }

    
        //---------------------------------------------------------------------------
        // Model
    
    @Observable
    public class XTable : Usable  //, Hashable
    {
        public static func == (lhs: XTable, rhs: XTable) -> Bool {
            lhs.id == rhs.id
        }
        
//        public func hash(into hasher: inout Hasher) {
//            hasher.combineMany(id, primary,keywords, experiement, species, date )
//        }
        
        public var id = UUID()
        public  var name = "Untitled Table"
        public var items = [FRExperiment]()
        
        init() {    }
    }
    


//    public struct XColumn : Identifiable, Hashable, Codable
//    {
//        public var id = UUID()
//        var primary: String = " "
//        var keywords: String = " "
//        var experiement: String = " "
//        var species: String = " "
//        var date: String = " "
//
//        init(_ name: String, parm: String, stat: String, arg: String = " ")
//        {
//            self.date = name
//            self.primary = parm
//            self.keywords = stat
//            self.experiement = arg
//            self.species = arg
//        }
//        
//        public func hash(into hasher: inout Hasher) {
//            hasher.combineMany(date, primary, keywords, experiement, species)
//        }
//        
//        static var draggableType = UTType(exportedAs: "com.cytegeist.CyteGeistApp.tablecolumn")
//        var itemProvider: NSItemProvider {
//            let provider = NSItemProvider()
//            provider.registerDataRepresentation(forTypeIdentifier: Self.draggableType.identifier, visibility: .all) {
//                let encoder = JSONEncoder()
//                do {
//                    let data = try encoder.encode(self)
//                    $0(data, nil)
//                } catch {
//                    $0(nil, error)
//                }
//                return nil
//            }
//            return provider
//        }
//    }

    
    public struct XTableView : View {
  
        @State var selection = Set<FRExperiment.ID>()
        @State var sortOrder = [KeyPathComparator(\FRExperiment.ExpName, order: .forward),
                                KeyPathComparator(\FRExperiment.Purpose, order: .forward),
                                KeyPathComparator(\FRExperiment.Keywords, order: .forward),
                                KeyPathComparator(\FRExperiment.Conclusion, order: .forward),
                                KeyPathComparator(\FRExperiment.Comments, order: .forward)   ]
        @State var columnCustomization = TableColumnCustomization<FRExperiment>()
        
        let table =  XTable()
        
        public var body: some View {
                //            Table (of: TColumn.Type, selection: $selectedColumns)
            Table (selection: $selection, sortOrder: $sortOrder, columnCustomization: $columnCustomization)
            {
                TableColumn("RepID", value: \.RepID){ col in Text(col.RepID)}
                    .width(min: 130, ideal: 180)
                    .customizationID("RepID")
//                TableColumn("RepIDurl", value: \.RepIDurl){ col in Text(col.RepIDurl)}
//                    .width(min: 130, ideal: 180)
//                    .customizationID("RepIDurl")
                TableColumn("ExpID", value: \.ExpID){ col in Text(col.ExpID)}
                    .width(min: 30, ideal: 80, max: 160)
                    .customizationID("ExpID")
                TableColumn("ExpName", value: \.ExpName){ col in Text(col.ExpName)}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("ExpName")
                TableColumn("Purpose", value: \.Purpose){ col in Text(col.Purpose)}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("Purpose")
                TableColumn("Conclusion", value: \.Conclusion){ col in Text(col.Conclusion)}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("Conclusion")
                TableColumn("Comments", value: \.Comments){ col in Text(col.Comments)}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("Comments")
                TableColumn("Keywords", value: \.Keywords){ col in Text(col.Keywords)}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("Keywords")
                TableColumn("PResearcher", value: \.PResearcher){ col in Text(col.PResearcher)}
                    .width(min: 30, ideal: 50, max: 60)
                    .customizationID("PResearcher")
//                TableColumn("ManuscriptUrl", value: \.ManuscriptUrl){ col in Text(col.ManuscriptUrl)}
//                    .width(min: 30, ideal: 50, max: 60)
//                    .customizationID("ManuscriptUrl")
//                TableColumn("Manuscripts", value: \.Manuscripts){ col in Text(col.Manuscripts)}
//                    .width(min: 30, ideal: 50, max: 60)
//                    .customizationID("Manuscripts")
//                TableColumn("Design", value: \.Design){ col in Text(col.Design)}
//                    .width(min: 30, ideal: 50, max: 60)
//                    .customizationID("Design")
//                TableColumn("Design_FCS_Count", value: \.Design_FCS_Count){ col in Text(col.Design_FCS_Count)}
//                    .width(min: 30, ideal: 50, max: 60)
//                    .customizationID("Design_FCS_Count")
//                TableColumn("MifScore", value: \.MifScore){ col in Text(col.MifScore)}
//                    .width(min: 30, ideal: 50, max: 60)
//                    .customizationID("MifScore")
//                TableColumn("PInvestigator", value: \.PInvestigator){ col in Text(col.PInvestigator)}
//                    .width(min: 30, ideal: 50, max: 60)
//                    .customizationID("PInvestigator")

//                
//                init( RepID: String, RepIDurl: String, ExpID: String, ExpName: String, Purpose: String, Conclusion: String, Comments: String, Keywords: String, ManuscriptUrl: String, Manuscripts: String, Design: String, Design_FCS_Count: String, MifScore: String, PResearche: String, PInvestigator: String, UploadAuth: String, ExpDates: String, ExpStart: String, ExpEnd: String, UploadDate: String, LastUpdate: String, Organizations: String, Funding: String, QualControl: String, QualControlUrl: String, hasWSP: String, Attachments: String, Event_total_K:String, Event_mean_K:String, FCS_count: String, FCS_total_MB: String, FCSVers: String, Cytometer: String )
//                
                
            }
        rows: {
            ForEach(table.items)  { col in TableRow(col) }
                //                ForEach(cols) { col in TableRow(TColumn).itemProvider { TColumn.itemProvider }  }
                //                    .onInsert(of: [TColumn.draggableType]) { index, providers in
                //                        TColumn.fromItemProviders(providers) { cols in
                ////                            let experiment = store.getSelectedExperiment()
                ////                            experiment.samples.insert(contentsOf: samples, at: index)
                //                        }
                //                    }
            
        }.frame(minWidth: 300, idealWidth: 600)
//                .dropDestination(for: AnalysisNode.self) { (items, position) in
//                    for item in items {print(item.name)  }
//                    
//                    for item in items { newTableItem(node: item, position:position)  }
//                    return true
//                }
                //            .opacity(mode == .table ? 1.0 : 0.3)
        }
//
//        func newTableItem(node:AnalysisNode, position:CGPoint)
//        {
//            table.items.append(TColumn("", parm: "Keyword", stat: "Date"))
//            table.items.append(TColumn(node.name, parm: "CD3", stat: "Median"))
//            table.items.append(TColumn(node.name, parm: "CD3", stat: "CV"))
//            print("new table item: ", node.name)
//        }
//        
        
    }
}
