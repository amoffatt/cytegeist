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


public actor CSemaphore {
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


public class BackgroundUpdater<UpdateData> {
    
    public private(set) var updateError:Error?
    private var latestUpdateData: UpdateData?
    private var updateHandler: (UpdateData) async throws -> Void
    private var isProcessing = false
    private var priority: TaskPriority
    private var task: Task<Void, Never>?
    private let lock = NSLock()
    
    
    public init(priority: TaskPriority = .background, updateHandler: @escaping (UpdateData) async throws -> Void) {
        self.updateHandler = updateHandler
        self.priority = priority
    }
    
    public func update(data: UpdateData, cancelRunningTask: Bool = false) {
        lock.withLock {
            latestUpdateData = data
            
            if cancelRunningTask, let task {
                task.cancel()
            }
            
            if !isProcessing {
                isProcessing = true
                task = Task(priority: priority) { [weak self] in
                    while let updateData = self?.getAndClearLatestUpdateData() {
                        do {
                            try await self?.updateHandler(updateData)
                        } catch {
                            print("Error in background update: \(error)")
                            self?.lock.withLock { self?.updateError = error }
                        }
                        
                    }
                    self?.lock.withLock {
                        self?.isProcessing = false
                    }
                }
            }
        }
    }
    
    private func getAndClearLatestUpdateData() -> UpdateData? {
        lock.withLock {
            defer { latestUpdateData = nil }
            return latestUpdateData
        }
    }
}

