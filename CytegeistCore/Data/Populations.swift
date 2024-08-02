//
//  Populations.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/30/24.
//

import Foundation


public class Population {
    let sample: SampleRef
    let gating: [Gate]
    
    public init(sample: SampleRef, gating: [Gate] = []) {
        self.sample = sample
        self.gating = gating
    }
}


public class Gate {
    
}
