/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant extension to support drag and drop.
*/

import Foundation
import UniformTypeIdentifiers
//
//extension Sample {
//    static var draggableType = UTType(exportedAs: "com.cytegeist.CyteGeistApp.sample")
//
//    /// Extracts encoded sample data from the specified item providers.
//    /// The specified closure will be called with the array of  resulting`Sample` values.
//    ///
//    /// Note: because this method uses `NSItemProvider.loadDataRepresentation(forTypeIdentifier:completionHandler:)`
//    /// internally, it is currently not marked as `async`.
//    static func fromItemProviders(_ itemProviders: [NSItemProvider], completion: @escaping ([Sample]) -> Void) {
//        let typeIdentifier = Self.draggableType.identifier
//        let filteredProviders = itemProviders.filter {
//            $0.hasItemConformingToTypeIdentifier(typeIdentifier)
//        }
//
//        let group = DispatchGroup()
//        var result = [Int: Sample]()
//
//        for (index, provider) in filteredProviders.enumerated() {
//            group.enter()
//            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { (data, error) in
//                defer { group.leave() }
//                guard let data = data else { return }
//                let decoder = JSONDecoder()
//                guard let plant = try? decoder.decode(Sample.self, from: data)
//                else { return }
//                result[index] = plant
//            }
//        }
//
//        group.notify(queue: .global(qos: .userInitiated)) {
//            let plants = result.keys.sorted().compactMap { result[$0] }
//            DispatchQueue.main.async {
//                completion(plants)
//            }
//        }
//    }
//
//    var itemProvider: NSItemProvider {
//        let provider = NSItemProvider()
//        provider.registerDataRepresentation(forTypeIdentifier: Self.draggableType.identifier, visibility: .all) {
//            let encoder = JSONEncoder()
//            do {
//                let data = try encoder.encode(self)
//                $0(data, nil)
//            } catch {
//                $0(nil, error)
//            }
//            return nil
//        }
//        return provider
//    }
//}
