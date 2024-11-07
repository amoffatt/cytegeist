//
//  Sample.swift
//  filereader
//
//  Created by Adam Treister on 7/19/24.
//

import Foundation
import CytegeistLibrary
import SwiftUI
import CObservation

//---------------------------------------------------------
// CDimension is the analog of a samples parameter
//
// is biexDimension a subclass or does it include a transform
  
public enum SampleError : Error {
    case noRef
    case queryError(Error)
}

//---------------------------------------------------------
//@Model
//@MainActor
@CObservable
public class Sample : CObject
{
    var sampleId = ""
    
    public var ref:SampleRef? = nil
    
//    @CodableIgnored
//    @ObservationIgnored
    // AM DEBUGGING @Transient
    var error:Error? = nil
    
//    var attributes = AttributeStore()
//    var dimensions = [CDimension]()
    //    var matrix = CMatrix()
    //    var membership =  [String : PValue]()
    //    var validity = SampleValidityCheck ()
    
    public var imageURL: URL?
    public var meta:FCSMetadata?
    
//    var keywords:AttributeStore { meta?.keywordLookup ?? [:] }
    public subscript(_ keyword:String) -> String { (meta?.keywordLookup[keyword]).nonNil }

    public var eventCount: Int { meta?.eventCount ?? 0 }
 
    public var tubeName: String { self["TUBE NAME"] }
    public var experimentName:  String { self["EXPERIMENT NAME"] }
    public var date: String { self["$DATE"] }
    public var btime:  String = ""//{ meta?.keywordLookup["$BTIM"] ?? "" }
    public var filename:  String { self["$FIL"] }
    public var creator:  String { self["CREATOR"] }
    public var apply:  String { self["APPLY COMPENSATION"] }
    public var threshold:  String { self["THRESHOLD"] }
    public var src:  String { self["$SRC"] }
    public var sys:  String { self["$SYS"] }
    public var cytometer:  String { self["$CYT"] }
    public var setup1:  String { self["CST SETUP STATUS"] }

    //-------------------------------------------------------------------------
    //read from JSON
    
    
        //-------------------------------------------------------------------------
    public init(
        ref: SampleRef
    ) {
        super.init()
        self.ref = ref
        print("Sample \(ref)")
    }
    
//    @MainActor required init(from decoder: any Decoder) async throws {
//        try await super.init(from:decoder)
//    }
    
//    convenience init(_ xml: TreeNode)
//    {
//        assert(xml.value == "Sample")
//        self.init()
//    }
    
    private func handleError(_ error:SampleError) {
        print("Error: cannot load sample: \(error.localizedDescription)")
        self.error = error
    }
        //-------------------------------------------------------------------------
        //  iniitialize based on a new FCS File added
    
    public func setUp( core: CytegeistCoreAPI)
    {
        debug("in SetUp")
        guard let ref else {
            handleError(.noRef)
            return
        }
        
        Task {
            do {
                meta = try await core.loadSample(SampleRequest(ref, includeData: false)).getResult().meta
                btime = meta?.keywordLookup["$BTIM"] ?? ""
                print("Loaded metadata")
            } catch {
                print(error)
                handleError(.queryError(error))
            }
        }
        print("sample validity check")
    }
    
    // AM DEBUGGING
//    @Transient
    private var _tree:AnalysisNode = AnalysisNode()
    public func getTree() -> AnalysisNode {
        _tree.sampleID = self.id
        return _tree

//        if _tree == nil {
//            _tree = AnalysisNode(sample:self)
//        }
//        return _tree!
    }

//    public func addTree(_ node: AnalysisNode)           //, _ deep: Bool = true
//    {
//        print ("addTree")
//        getTree().addChild(node)
//            //        if tree.name != node.name {
//            //        }
//            //        if deep {
//            //            for child in node.children {
//            //                clone.addTree(child, deep)
//            //            }
//            //        }
//    }
    
//    internal func testWithMutation<Member, MutationResult>(
//        keyPath: ReferenceWritableKeyPath<Sample, Member>,
//        _ mutation: () throws -> MutationResult
//    ) rethrows -> MutationResult {
//        let initialValue = self[keyPath: keyPath]
//        let result = try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
//        let finalValue = self[keyPath: keyPath]
//
//        self[keyPath: keyPath] = initialValue
//      if let undoManager = _context?.undoManager {
//          undoManager.registerUndo(withTarget:self) { target in
//          target[keyPath: keyPath] = initialValue
//        }
//      }
//        return result
//    }
//    
    
}

// AM DEBUGGING
//}: Observation.Observable, AnyObject {
//class TestObject {
//    internal nonisolated mutating func testWithMutation<Member>(
//        keyPath: ReferenceWritableKeyPath<TestObject, Member>,
//        _ mutation: () throws -> Void
//    ) rethrows {
//        let initialValue = self[keyPath: keyPath]
//        try mutation()
//        let finalValue = self[keyPath: keyPath]
//
//        self[keyPath: keyPath] = initialValue
//    }
//}


import UniformTypeIdentifiers

extension Sample {
    static var draggableType = UTType(exportedAs: "com.cytegeist.CyteGeistApp.sample")
    
        /// Extracts encoded sample data from the specified item providers.
        /// The specified closure will be called with the array of  resulting`Sample` values.
        ///
        /// Note: because this method uses `NSItemProvider.loadDataRepresentation(forTypeIdentifier:completionHandler:)`
        /// internally, it is currently not marked as `async`.
    static func fromItemProviders(_ itemProviders: [NSItemProvider], completion: @escaping ([Sample]) -> Void) {
        // AM DEBUGGING
        print("Sample transfer not implemented")
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
    }
    
    var itemProvider: NSItemProvider {
        print("Sample transfer not implemented")
        let provider = NSItemProvider()
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
        return provider
    }
}
