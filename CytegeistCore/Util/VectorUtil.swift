//
//  VectorUtil.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/18/24.
//

import Foundation


extension SIMD where Scalar: FloatingPoint {
    func lerp(to: Self, t: Scalar) -> Self {
        return self + t * (to - self)
    }
    
    var clamped01: Self {
        self.clamped(lowerBound: .zero, upperBound: .one)
    }
}
