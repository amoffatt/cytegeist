////
////  ContentView.swift
////  filereader
////
////  Created by Adam Treister on 7/13/24.
////
//
//import SwiftUI
//import CytegeistLibrary
//
//struct ProtoStartupScreenView: View {
//    @State private var showFCSImporter = false
//    @State private var showWSImporter = false
//    @Environment(\.openWindow) var openWindow
//    @State var app: App = App()
//        //  @Environment var selectedExperiment: Experiment
//    
//    var body: some View {
//        
//        ZStack()
//        {
//            Spacer()
//            VStack {
//                Image(systemName: "star")
//                    .imageScale(.large)
//                    .foregroundStyle(.tint)
//                    .foregroundColor(.pink)
//                Text("Cytegeist Control Panel")
//                HStack {
//                    Button("Read FCS File", systemImage: "star",
//                           action: { showFCSImporter = true })
//                    .fileImporter(
//                        isPresented: $showFCSImporter,
//                        allowedContentTypes: [.item] ,  // TODO filter to .fcs extension
//                        allowsMultipleSelection: true
//                    ){ result in  app.onFCSPicked(_result: result) }
//                      
//                    Button("Read Workspace", systemImage: "xmark.circle",
//                           action: { showWSImporter = true })
//                    .fileImporter(
//                        isPresented: $showWSImporter,
//                        allowedContentTypes: [.item]
//                    ) { result in processWorkspace(result: result)
//                        
//                    }
//                    Button("New Table", systemImage: "person.crop.circle",
//                           action: { openWindow(id: "tables")})
//                    Button("New Layout", systemImage: "sunrise.fill",
//                           action: { openWindow(id: "layouts")})
//                    Button("Work on Gating", systemImage: "sunrise.fill",
//                           action: { openWindow(id: "gating")})
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(.mint)
//        
//    }
//    
//
////------------------------------------------------------
//    func processWorkspace(result: Result<URL, any Error> )
//    {
//        switch result {
//            case .success(let file):
//                Task {
//                    let gotAccess = file.startAccessingSecurityScopedResource()
//                    if !gotAccess { return }
//                    await readWorkspaceFile(file)
//                    file.stopAccessingSecurityScopedResource()     // release access
//                }
//            case .failure(let error):
//                print(error)         // handle error
//        }
//    }
//    
//    func readWorkspaceFile(_ url:URL) async
//    {
//        let reader = WorkspaceReader()
//        do {
////            let ws = try await  reader.readWorkspaceFile(at: url)
////            let _ = Experiment(ws: ws )
////            print("WS of length: ", ws.text.count)
//        }
//        catch let error as NSError {
//            debug("Ooops! Something went wrong: \(error)")
//        }
//    }
//    
//}
//
//
////------------------------------------------------------
////
////#Preview {
////    @Environment var store: Store
////    VStack
////    {
////        ContentView(store)
////    }
////}
