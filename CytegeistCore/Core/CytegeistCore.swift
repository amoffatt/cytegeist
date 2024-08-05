//
//  CytegeistCore.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/28/24.
//

import Foundation

public struct APIError : Error {
    public let message: String
    public let internalError: Error?
    
    init(_ message: String, _ internalError: Error? = nil) {
        self.message = message
        self.internalError = internalError
    }
}

@Observable
public class APIQuery<T> {
    public private(set) var isLoading:Bool = true
    public private(set) var data:T? = nil
    public private(set) var error:APIError?
    public private(set) var viewPriority: Int = 1
    
    init() {
        
    }
    
    public func dispose() {
        viewPriority = 0
    }
    
    @MainActor
    func progress(_ result:T) {
        data = result
    }

    @MainActor
    func success(_ result:T) {
        data = result
        isLoading = false
    }
    
    @MainActor
    func error(_ message:String, _ internalError:Error) {
        isLoading = false
        error = .init(message, internalError)
        print("APIQuery error: \(message): \(internalError)")
    }
}

//func resultOf<T>(_ closure:() throws -> T) -> T? {
//    do {
//        return try closure()
//    } catch {
//        print("Error")
//    }
//}

//public class TaskUtil {
//    @discardableResult
//    static func safeDetached<Success>(
//        priority: TaskPriority? = nil,
//        operation: @escaping () async -> Success
//    ) -> Task<Success, Failure> {
//        
//    }
//}


@MainActor
public class CytegeistCoreAPI {
    private let fcsReader:FCSReader = .init()
    
    public var histogramResolution:Int = 256
    
//    private var samples:[String:FCSFile]
    
    public init() {
        
    }
    
    public func histogram(sampleRef:SampleRef, parameterName:String) -> APIQuery<HistogramData> {
        let result:APIQuery<HistogramData> = APIQuery()
        let resolution = self.histogramResolution

        Task.detached {
            do {
                print("Loading data for '\(sampleRef.filename)'")
                let sample = try self.loadSample(ref: sampleRef)
                let meta = sample.meta
                
                print("  ==> Data loaded. \(meta.eventCount) events, \(String(describing: meta.parameters?.count)) parameters")
                guard let parameter = sample.parameter(named: parameterName) else {
                    print(sample.meta.parameterLookup.debugDescription)
                    throw APIError("Parameter '\(parameterName) not found")
                }
                
                print("  ==> Parameter loaded")

                let histogram = HistogramData(data: parameter.data, resolution: resolution, xAxis: parameter.meta.normalizer)
                
                await MainActor.run {
                    result.success(histogram)
                }
                
            } catch {
                print("Error creating histogram: \(error)")
                await MainActor.run {
                    result.error("Error creating chart", error)
                }
            }
        }
        
        return result
    }
    
    public func loadSample(sampleRef:SampleRef, includeData:Bool = true) -> APIQuery<FCSFile> {
        let result = APIQuery<FCSFile>()

        Task.detached {
            do {
                print("Loading data for '\(sampleRef.filename)'")
                let sample = try self.loadSample(ref: sampleRef, includeData: includeData)
                
                await MainActor.run {
                    result.success(sample)
                }
                
            } catch {
                await MainActor.run {
                    result.error("Error creating chart", error)
                }
            }
        }
        
        return result
    }

    
    
    nonisolated private func loadSample(ref:SampleRef, includeData:Bool = true) throws -> FCSFile {
        try self.fcsReader.readFCSFile(at: ref.url, includeData: includeData)
    }
    
}
