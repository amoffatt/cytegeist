//
//  CDocument.swift
//  Cytegeist
//
//  Created by AM on 11/4/24.
//

import SwiftUI
import CObservation
import UniformTypeIdentifiers

/// A wrapper for Experiment, managing file handling logic
@Observable
@MainActor
public class CDocument {

    public static let readableContentTypes: [UTType] = [.cge]
    public static let writableContentTypes: [UTType] = [.cge]
    
    public let id:UUID

    public private(set) var content: Experiment!
    public let context = CObjectContext(nil)
    public private(set) var isTemporaryURL: Bool = true
    private var _url: URL
    public var url: URL {
        get { _url }
        set { _url = newValue; isTemporaryURL = false }
    }
    public init(url:URL, isTemporaryUrl:Bool=false) {
        let content = self.context.withContext {
             Experiment()
        }
        self.content = content
        _url = url
        id = content.id
        self.isTemporaryURL = isTemporaryUrl
    }
    
    private func snapshot() throws -> Any? {
        print("Beginning document snapshot...")
        
        // We can serialize from outside the MainActor because the main actor is waiting on this function, so the model will not be changed or read at the same time
        let result = try content.serialize()
        print(" ==> document snapshot complete.")
        return result
    }
    
    public func fileWrapper(snapshot: Any?) throws -> FileWrapper {
        guard let snapshot else {
            fatalError("Document not serialized")
        }
        let options = JSONSerialization.WritingOptions.prettyPrinted
        let data = try JSONSerialization.data(withJSONObject: snapshot, options: options)
        print("Serialized document:\n\(String(decoding: data, as: Unicode.UTF8.self))")
        return FileWrapper(regularFileWithContents: data)
    }

    func save(_ callback: @escaping (CDocument, Error?) -> Void) {
        do {
            try fileWrapper(snapshot: try snapshot()).write(to: url, options: .atomic, originalContentsURL: nil)
            callback(self, nil)
        } catch {
            print("Error saving document: \(error)")
            callback(self, error)
        }
    }

}
