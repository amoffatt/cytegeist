/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The store extension file support.
*/

import SwiftUI
import UniformTypeIdentifiers
//
//extension App: ReferenceFileDocument {
//    typealias Snapshot = [Experiment]
//
//    static var readableContentTypes = [UTType.commaSeparatedText]
//
//    convenience init(configuration: ReadConfiguration) throws {
//        self.init()
//    }
//
//    func snapshot(contentType: UTType) throws -> Snapshot {
//        experiments
//    }
//
//    func fileWrapper(snapshot: Snapshot, configuration: WriteConfiguration) throws -> FileWrapper {
//        var exportedData = Data()
//        if let header = Bundle.main.localizedString(forKey: "CSV Header", value: nil, table: nil).data(using: .utf8) {
//            exportedData.append(header)
//            exportedData.append(newline)
//        }
//        for experiment in snapshot {
//            for sample in experiment.samples {
//                experiment.append(to: &exportedData)
//                sample.append(to: &exportedData)
//                exportedData.append(newline)
//            }
//        }
//        return FileWrapper(regularFileWithContents: exportedData)
//    }
//}
//
//extension Experiment {
//    fileprivate func append(to csvData: inout Data) {
//        if let data = name.utf8Data {
//            csvData.append(data)
//            csvData.append(comma)
//        } else {
//            csvData.append(comma)
//        }
//        let yearString = numberFormatter.string(from: NSNumber(value: self.modifiedDate[.year])).nonNil
//        if let data = yearString.utf8Data {
//            csvData.append(data)
//            csvData.append(comma)
//        } else {
//            csvData.append(comma)
//        }
//    }
//}

//extension Sample {
//    fileprivate func append(to csvData: inout Data) {
//        if let data = variety.data(using: .utf8) {
//            csvData.append(data)
//            csvData.append(comma)
//        } else {
//            csvData.append(comma)
//        }
//        if let data = numberFormatter.string(from: (plantingDepth ?? 0) as NSNumber)?.data(using: .utf8) {
//            csvData.append(data)
//            csvData.append(comma)
//        } else {
//            csvData.append(comma)
//        }
//        if let data = numberFormatter.string(from: daysToMaturity as NSNumber)?.data(using: .utf8) {
//            csvData.append(data)
//            csvData.append(comma)
//        } else {
//            csvData.append(comma)
//        }
//        let datePlantedString = datePlanted == nil ? "" : dateFormatter.string(from: datePlanted!)
//        if let data = datePlantedString.data(using: .utf8) {
//            csvData.append(data)
//            csvData.append(comma)
//        } else {
//            csvData.append(comma)
//        }
//        if let data = favorite.description.data(using: .utf8) {
//            csvData.append(data)
//            csvData.append(comma)
//        } else {
//            csvData.append(comma)
//        }
//        if let data = dateFormatter.string(from: lastWateredOn).data(using: .utf8) {
//            csvData.append(data)
//            csvData.append(comma)
//        } else {
//            csvData.append(comma)
//        }
//        if let data = numberFormatter.string(from: (wateringFrequency ?? 0) as NSNumber)?.data(using: .utf8) {
//            csvData.append(data)
//        }
//    }
//}

//
//https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image
//
//extension View {
//    var asImage: UIImage {
//            // Must ignore safe area due to a bug in iOS 15+ https://stackoverflow.com/a/69819567/1011161
//        let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.top))
//        let view = controller.view
//        let targetSize = controller.view.intrinsicContentSize
//        view?.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: targetSize)
//        view?.backgroundColor = .clear
//        
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = 3 // Ensures 3x-scale images. You can customise this however you like.
//        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
//        return renderer.image { _ in
//            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
//        }
//    }
//}
