//
//  CytegeistApp.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//

import SwiftUI
import CytegeistCore
import CytegeistLibrary
import SwiftData

@main
@MainActor
struct CytegeistApp: SwiftUI.App {

    @State private var appModel = App()
    @FocusedValue(\.analysisNode) var focusedAnalysisNode
    @Environment(\.openWindow) var openWindow
    @FocusedValue(CDocument.self) private var focusedDocument


    var body: some Scene {        
        WindowGroup(for: URL.self) { $url in
            if let url = url {
                let document = appModel.openDocuments.first(where: { $0.url == url }) ?? {
                    let doc = CDocument()
                    doc.url = url
                    appModel.openDocuments.append(doc)
                    return doc
                }()
                ExperimentWindow(document: document)
                    .environment(appModel)
                    .focusedSceneValue(document)
            } else {
                VStack {
                    Text("Launching...")
                }
                .onAppear() {
                    createNewDocument()
                }
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Experiment") {
                    createNewDocument()
                }
                .keyboardShortcut("n")
                
                Button("Open...") {
                    openDocument()
                }
                .keyboardShortcut("o")
                
                Menu("Open Recent") {
                    ForEach(appModel.recentDocuments, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            openDocument(at: url)
                        }
                    }
                    
                    if !appModel.recentDocuments.isEmpty {
                        Divider()
                        Button("Clear Menu") {
                            appModel.recentDocuments.removeAll()
                        }
                    }
                }
            }
            
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    saveDocument()
                }
                .keyboardShortcut("s")
                
                Button("Save As...") {
                    saveDocumentAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
        
        #if os(macOS)
        Window("Pair Charts", id: "pair-charts") {
            PairChartsPreview()
        }
        
        Window("Experiment Browser", id: "browse") {
            ExperimentBrowser().environment(appModel)
        }
        #endif

//       Window("SaveOpenView", id: "SaveOpen") {   SaveOpenView()  }
//        Settings {    SettingsView().environmentObject(store)    }

            //        ImmersiveSpace(id: appModel.immersiveSpaceID) {
//            ImmersiveView()
//                .environment(appModel)
//                .onAppear {
//                    appModel.immersiveSpaceState = .open
//                }
//                .onDisappear {
//                    appModel.immersiveSpaceState = .closed
//                }
//        }
//        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = CDocument.readableContentTypes
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                openDocument(at: url)
            }
        }
    }

    private func openDocument(at url: URL) {
        let document = CDocument()
        document.url = url
        appModel.openDocuments.append(document)
        openWindow(value: url)
        addToRecentDocuments(url)
    }

    private func saveDocument() {
        guard let document = focusedDocument else { return }
        
        if document.isTemporaryURL {
            saveDocumentAs()
            return
        }
        
        document.save(saveCallback)
    }

    private func saveDocumentAs() {
        guard let document = focusedDocument else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = CDocument.writableContentTypes
        
        if panel.runModal() == .OK {
            if let saveUrl = panel.url {
                document.url = saveUrl
                document.save(saveCallback)
                addToRecentDocuments(saveUrl)
            }
        }
    }

    private func addToRecentDocuments(_ url: URL) {
        if let index = appModel.recentDocuments.firstIndex(of: url) {
            appModel.recentDocuments.remove(at: index)
        }
        appModel.recentDocuments.insert(url, at: 0)
        if appModel.recentDocuments.count > 10 {
            appModel.recentDocuments.removeLast()
        }
    }
    
    private func saveCallback(_ document: CDocument, error: Error?) {
        print(" == save callback for document \(document.url). Error: \(error?.localizedDescription ?? "none")")
    }

    private func createNewDocument() {
        let document = CDocument()
        appModel.openDocuments.append(document)
        openWindow(value: document.url)
    }
}
