//
//  ChartView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/27/24.
//

import SwiftUI

public struct ChartView: View {
//    todofileRef() //?
//    todoFileQueryAPI() // ?
    let core: CytegeistCoreAPI
    @State var sample: SampleRef
    @State var parameterName: String
    
    public init(_ core: CytegeistCoreAPI, sample: SampleRef, parameterName: String) {
        self.core = core
        self.sample = sample
        self.parameterName = parameterName
    }
    
    public var body: some View {
        VStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            HistogramView(data: core.histogram(sampleRef: sample, parameterName: parameterName))
//            Selector()
        }
        .frame(width: 400, height: 400)
    }
}

#Preview {
    let core = CytegeistCoreAPI()
//    return VStack { Text("Test world")}
    let sample = SampleRef(url: DemoData.facsDivaSample0!)
    let parameter = "FSC-H"
//
    return ChartView(core, sample: sample, parameterName: parameter)
}
