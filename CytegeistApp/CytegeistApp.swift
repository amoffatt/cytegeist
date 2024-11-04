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
    // Global list of open documents. Cannot be a @State because WindowGroup closure may run a second time consecutively before the @State has updated with recent changes
    private static var openDocuments: [CDocument] = []
    private static var urlChanges: [URL:URL] = [:]

    @State private var appModel = App()
    @FocusedValue(\.analysisNode) var focusedAnalysisNode
    @Environment(\.openWindow) var openWindow
    @FocusedValue(CDocument.self) private var focusedDocument
    


    var body: some Scene {        
        WindowGroup("Experiment", for: URL.self) { $url in
            let document = getDocument(url)
            ExperimentWindow(document: document)
                .environment(appModel)
                .focusedSceneValue(document)
                .onOpenURL { url in
                    print("URL opened: \(url)")
                }
                .onChange(of: document.url) {
                    let oldUrl = $url.wrappedValue
                    // If the document URL changes (e.g. via "Save As"), update the windows URL binding
                    $url.wrappedValue = document.url

                    // Clean up the URL change tracking once the window is updated. But ensure the record isn't removed until SwiftUI will stop asking for the old URL
                    Task {
                        await MainActor.run {
                            Self.urlChanges.removeValue(forKey: oldUrl)
//                            print("Removed url change tracking for \(oldUrl)")
                        }
                    }
                }
        } defaultValue: {
            createNewDocument().url
        }
        .commands {
            CommandGroup(after: .newItem) {
                
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
                    
                    Divider()
                    Button("Clear Menu") {
                        appModel.recentDocuments.removeAll()
                    }
                    .disabled(appModel.recentDocuments.isEmpty)
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

     }
    
    private func createNewDocument() -> CDocument {
        let document = CDocument(url: createTemporaryFileURL(), isTemporaryUrl: true)
        Self.openDocuments.append(document)
        return document
    }
    
    private func getDocument(_ url:URL) -> CDocument {
        if let document = Self.openDocuments.first(where: { url == $0.url }) {
            print(" ==> Found document url \(document.url)")
            return document
        }
        
        // Then check if this URL is in our changes dictionary
        if let newUrl = Self.urlChanges[url],
           let document = Self.openDocuments.first(where: { newUrl == $0.url }) {
            print(" ==> Found document with updated url \(document.url)")
            return document
        }
        
        let document = CDocument(url: url, isTemporaryUrl: isTemporaryFileURL(url))
//        document.load()
        print(" ==> Created new document with url \(document.url)")
        print(" TODO: Load content")
        Self.openDocuments.append(document)
        return document
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
        let document = CDocument(url: url, isTemporaryUrl: false)
        openDocument(document)
    }

    private func openDocument(_ document:CDocument) {
        Self.openDocuments.append(document)
        openWindow(value: document.url)
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
                let oldUrl = document.url
                document.url = saveUrl
                Self.urlChanges[oldUrl] = saveUrl  // Track the URL change
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
        print(" == save callback for document \(document.url). Any error?: \(error?.localizedDescription ?? "no")")
    }
}
