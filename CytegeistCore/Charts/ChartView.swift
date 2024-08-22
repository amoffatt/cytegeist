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
    @Environment(CytegeistCoreAPI.self) var core: CytegeistCoreAPI
//    @State var sample: SampleRef
    let population: PopulationRequest
//    @State var parameterNames: Tuple2<String>
    
    public init(population: PopulationRequest, chart:ChartDef) {
//        self.sample = sample
        self.population = population
//        self.parameterNames = parameterNames
    }
    
    public var body: some View {
        VStack {
//            HistogramView(query: core.histogram(.init(population, .init(parameterNames.x))))
//            Histogram2DView(data: core.histogram2D(sampleRef: sample, parameterNames: parameterNames))
//            Selector()
        }
        .frame(width: 400, height: 400)
    }
}

//#Preview {
//    let core = CytegeistCoreAPI()
////    return VStack { Text("Test world")}
//    let sample = SampleRef(url: DemoData.facsDivaSample0!)
//    let population = PopulationRequest(sample)
//    let parameters = Tuple2("FSC-A", "PacificBlue-A")
///
//    return ChartView(population: population, parameterNames: parameters)
//        .environment(core)
//}
