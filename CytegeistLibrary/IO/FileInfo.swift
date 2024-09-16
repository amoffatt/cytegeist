//
//  FileInfo.swift
//  Dropera
//
//  Created by Howard Oakley on 19/05/2024.
//  By Martin R at https://stackoverflow.com/questions/38343186/write-extend-file-attributes-swift-example
//

import Foundation


public extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}



public extension URL {
    
    /// Get list of all extended attributes.
    func listExtendedAttributes() throws -> [String] {
        
        let list = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
            let length = listxattr(fileSystemPath, nil, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }
            
            // Create buffer with required size:
            var namebuf = Array<CChar>(repeating: 0, count: length)
            
            // Retrieve attribute list:
            let result = listxattr(fileSystemPath, &namebuf, namebuf.count, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
            
            // Extract attribute names:
            let list = namebuf.split(separator: 0).compactMap {
                $0.withUnsafeBufferPointer {
                    $0.withMemoryRebound(to: UInt8.self) {
                        String(bytes: $0, encoding: .utf8)
                    }
                }
            }
            return list
        }
        return list
    }
    
    /// Get size of extended attributes
    func getExtendedAttributeSize() throws -> Int {
        var theSize = 0
        let theList = try listExtendedAttributes()
        if theList.count > 0 {
            for item in theList {
                theSize += try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Int in
                    // Determine attribute size:
                    let length = getxattr(fileSystemPath, item, nil, 0, 0, 0)
                    guard length >= 0 else { throw URL.posixError(errno) }
                    return length
                }
            }
        }
        return theSize
    }

    /// Helper function to create an NSError from a Unix errno.
    private static func posixError(_ err: Int32) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
                       userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
    }
}

public class FileInfo: NSObject {
    
    public static func reportSizes(url: URL) -> String {
        var theStr = ""
        var theResSize = 0
        var theDataSize = 0
        do {
            theResSize = try url.getExtendedAttributeSize()
            let theRes = try url.resourceValues(forKeys: [.fileSizeKey])
            if let theData = theRes.fileSize {
                theDataSize = theData
            }
            theStr = "Data \(theDataSize), xattrs \(theResSize), total \(theDataSize + theResSize) bytes."
        } catch {
            theStr = "Sizes not available."
        }
        return theStr
    }
}


