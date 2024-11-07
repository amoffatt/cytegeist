//
//  CObjectTransferRepresentation.swift
//  CObservation
//
//  Created by AM on 11/6/24.
//

import Foundation
import SwiftUI

/// A transfer representation for CObjects that handles serialization and deserialization
//@MainActor
//public struct CObjectTransferRepresentation : TransferRepresentation {
//    
//    /// Serializes a CObject into a dictionary format suitable for transfer
//    /// - Parameter object: The CObject to serialize
//    /// - Returns: A dictionary containing the serialized data
//    public static func serialize(_ object: CObject) throws -> [String: Any] {
//        guard let serialized = try object.serialize() as? [String: Any] else {
//            throw SerializationError.invalidSerializedFormat
//        }
//        
//        return [
//            "id": object.id.uuidString,
//            "type": String(describing: type(of: object)),
//            "data": serialized
//        ]
//    }
//    
//    /// Error cases that can occur during serialization/deserialization
//    public enum SerializationError: Error {
//        case invalidSerializedFormat
//        // case missingRequiredFields
//        // case invalidObjectType
//    }
//}

