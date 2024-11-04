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
