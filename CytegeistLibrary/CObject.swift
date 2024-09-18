//
//  CObject.swift
//  CytegeistLibrary
//
//  Created by Aaron Moffatt on 9/10/24.
//

import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers.UTType

public extension UTType {
    static var cytegeistObject = UTType(exportedAs: "cytegeist.object")
}


@MainActor
open class CObject : ObservableObject, Identifiable, Equatable, Hashable, Transferable, Codable {
    public static func == (lhs: CObject, rhs: CObject) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: UTType.cytegeistObject)
    }
    

    public private(set) var id = UUID()
    
    required public init() {
    }

    open func clone() -> Self {
        let clone = Self()
        for child in Mirror(reflecting: self).children {
            if let label = child.label, label != "id" {
                (clone as AnyObject).setValue(child.value, forKey: label)
            }
        }
        return clone
    }
}

open class CNamedObject : CObject {
    @Published public var name:String = ""
}
