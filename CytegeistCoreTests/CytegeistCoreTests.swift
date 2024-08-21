//
//  CytegeistTests.swift
//  CytegeistTests
//
//  Created by Aaron Moffatt on 7/27/24.
//

import XCTest
import CytegeistCore

final class CytegeistCoreTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    func testFCSReader() throws {
//        print("Testing FCS Reader...")
//        let reader = FCSReader()
//
//        let testDataURL = Bundle(for: type(of: self)).url(forResource: "TestData", withExtension: nil)!
//        let fileManager = FileManager.default
//        let testFilesURLs = func testFCSReader() throws {
        print("Testing FCS Reader...")
        let reader = FCSReader()

        let testDataURL = Bundle(for: FCSReader.self).url(forResource: "TestData", withExtension: nil)!
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: testDataURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        var errors = 0
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "fcs" {
                let filePath = fileURL.path
                print("FCS File Path: \(filePath)")
                do {
//                    try ExceptionCatcher.catchException {
//                        do {
                            let fcsFile = try reader.readFCSFile(at: fileURL)
                            print(" ==> Event Count: \(fcsFile.meta.eventCount)")
                        }catch {
                            print(" ==> Caught file read error: \(error)")
                        }
                    }
                } catch {
                    print(" ==> Error reading FCS file: \(error)")
                    errors += 1
                }
            }
        }

        if errors > 0 {
            XCTFail("Error reading FCS \(errors) files")
        }
// }try fileManager.contentsOfDirectory(at: testDataURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
//         var errors = 0
        
//         for fileURL in testFilesURLs {
//             if fileURL.pathExtension == "fcs" {
//                 let filePath = fileURL.path
//                 print("FCS File Path: \(filePath)")
//                 do {
//                     let fcsFile = try reader.readFCSFile(at: fileURL)
//                     print(" ==> Event Count: \(fcsFile.eventCount)")
//                 } catch {
//                     print(" ==> Error reading FCS file: \(error)")
//                     errors += 1
//                 }
//             }
//         }

//         if errors > 0 {
//             XCTFail("Error reading FCS \(errors) files")
//         }
        
        // let fcsFile = try reader.readFCSFile(at: URL(filePath: "../TestData/FCS/FlowCytometers/FACS_Diva/facs_diva_test.fcs"))
        // print("FCS Event Count: \(fcsFile.eventCount)")
    }

}
