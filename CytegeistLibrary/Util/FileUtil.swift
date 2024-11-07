//
//  FileUtil.swift
//  Cytegeist
//
//  Created by AM on 11/3/24.
//

public func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
}

public func createTemporaryFileURL() -> URL {
    return temporaryDirectory().appendingPathComponent(UUID().uuidString)
}

public func isTemporaryFileURL(_ file: URL) -> Bool {
    return file.path.hasPrefix(temporaryDirectory().path)
}


    // Recursive iteration
public func walkDirectory(at url: URL, options: FileManager.DirectoryEnumerationOptions ) -> AsyncStream<URL> {
    AsyncStream { continuation in
        Task {
            defer {
                continuation.finish()
            }
            
            let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: options)
            while let fileURL = enumerator?.nextObject() as? URL {
                print(fileURL)
                if fileURL.hasDirectoryPath {
                    for await item in walkDirectory(at: fileURL, options: options) {
                        continuation.yield(item)
                    }
                } else {  continuation.yield( fileURL )    }
            }
        }
    }
}

public extension URL {
    func withSecurityScopedAccess<T>(_ body: () async throws -> T) async rethrows -> T? {
        guard startAccessingSecurityScopedResource() else { return nil }
        defer { stopAccessingSecurityScopedResource()}
        
        return try await body()
    }
    
}
