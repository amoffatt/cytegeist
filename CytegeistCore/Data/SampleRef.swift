//
//  SampleRef.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/28/24.
//

import Foundation


public struct SampleRef: Codable, Hashable {
    public let url:URL
    
    public var filename:String { url.lastPathComponent }
    
    public init(filePath:String) {
        url = URL(filePath: filePath)
    }
    
    public init(url:URL) {
        self.url = url
    }
}
