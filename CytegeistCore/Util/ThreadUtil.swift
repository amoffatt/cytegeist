//
//  ThreadUtil.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/30/24.
//

import Foundation


public func sleep(_ seconds:Float) async {
    do {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1e9))
    } catch {
        print("Task.sleep() failed: \(error)")
    }
}
