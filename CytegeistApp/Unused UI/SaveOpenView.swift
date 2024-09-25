//
//  ContentView.swift
//  SaveAndOpenPanelsSwiftUI
//
//  Created by Gabriel Theodoropoulos.
//  https://serialcoder.dev
//

#if os(macOS)

import SwiftUI
import UniformTypeIdentifiers

struct SaveOpenView: View {
    @State private var text: String = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    """
    
    var body: some View {
        VStack {
            TextEditor(text: $text)
                .font(.title)
                .frame(minWidth: 700, minHeight: 500)
            
            HStack {
                // New text button.
                Button(action: { text = ""
                }, label: { HStack { Image(systemName: "plus") ; Text("New") }
                    .frame(width: 80)
                })
                
                Spacer()
                
                // Save button.
                Button(action: {
                    let saveURL = showSavePanel()
                    writeText(to: saveURL)
                }, label: { HStack {  Image(systemName: "square.and.arrow.down"); Text("Save")  }
                    .frame(width: 80)
                })
                
                // Open button.
                Button(action: {
                    let openURL = showOpenPanel()
                    readText(from: openURL)
                }, label: {  HStack { Image(systemName: "square.and.arrow.up");  Text("Open")  }
                    .frame(width: 80)
                })
            }
            .padding(20)
        }
    }
    
    
    func showSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.text]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save your text"
        savePanel.message = "Choose a folder and a name to store your text."
        savePanel.nameFieldLabel = "File name:"
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
    
    
    func writeText(to url: URL?) {
        guard let url = url else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
    
    
    func showOpenPanel() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.text]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        return response == .OK ? openPanel.url : nil
    }
    
    
    func readText(from url: URL?) {
        guard let url = url else { return }
        guard let loadedText = try? String(contentsOf: url) else { return }
        text = loadedText
    }
}

struct SaveOpenView_Previews: PreviewProvider {
    static var previews: some View {
        SaveOpenView()
    }
}
#endif
