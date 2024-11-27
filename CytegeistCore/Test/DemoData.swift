//
//  DemoData.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/29/24.
//

import Foundation


public class DemoData {
    public static let testsBundleId = "com.cytegeist.visionos.2.CytegeistTests"
    public static let testDataRoot = Bundle(for: DemoData.self).url(forResource: "TestData", withExtension: nil)
    
    public static let facsDivaSample0 = testDataRoot?.appendingPathComponent("facs_diva_test.fcs")
}
