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


public actor Semaphore {
    private var waiters: [CheckedContinuation<Void, Never>] = []

    public init() {
    }

    public func wait() async {
        await withCheckedContinuation {
            waiters.append($0)
        }
    }
    
    public func release() {
        for waiter in waiters {
            waiter.resume()
        }
        waiters.removeAll()
    }
}
