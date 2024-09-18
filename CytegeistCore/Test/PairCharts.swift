//
//  PairCharts.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 8/19/24.
//

import SwiftUI
import CytegeistLibrary



struct PairChartView: View {
    let core: CytegeistCoreAPI
    let sampleRef: SampleRef
    let parameters: Tuple2<CDimension>
    
    var body: some View {
        VStack {
            if parameters.x.name != parameters.y.name {
                Text("\(parameters.x.name) vs \(parameters.y.name)")
                    .font(.headline)
                
                Histogram2DView(query: core.histogram2D(
                    .init(
                        .sample(sampleRef),
                        parameters.map { $0.name }
                    )
                ))
                    .frame(width: 200, height: 200)
                    .scaledToFit()
            }
        }
        .padding()
    }
}

public struct PairChartsView: View {
    let includeTransposes = false
    
    let core: CytegeistCoreAPI
    let sampleRef: SampleRef
    let parameters: ArraySlice<CDimension>
    
    init<C:Collection>(core: CytegeistCoreAPI, sampleRef: SampleRef, parameters: C) where C.Element == CDimension {
        self.core = core
        self.sampleRef = sampleRef
        self.parameters = ArraySlice(parameters)
    }
    
    public var body: some View {
        let columns = Array(repeating:GridItem(.fixed(250)), count: parameters.count)
        return ScrollView([.horizontal, .vertical]) {
            LazyVGrid(columns: columns) {
                ForEach(0..<parameters.count, id: \.self) { x in
                    ForEach(0..<parameters.count, id: \.self) { y in
                        let parameterPair = Tuple2(parameters[x], parameters[y])
                        VStack {
                            if !includeTransposes && y > x {
                                EmptyView()
                            } else {
                                PairChartView(core:core,
                                              sampleRef: sampleRef,
                                              parameters: parameterPair)
                            }
                        }
                        .id("\(parameterPair)")

                    }
                }
            }
            .padding()
        }
    }
}


@MainActor
public struct PairChartsPreview: View {
    let sampleRef = SampleRef(url:DemoData.facsDivaSample0!)
    @State var core = CytegeistCoreAPI()
    @State var query:APIQuery<FCSFile>? = nil
    
    public init() {}
    
    public var body: some View {
        VStack {
            if let query {
                if let meta = query.data?.meta,
                   let parameters = meta.parameters
                {
                    //        Histogram2DView(data: core.histogram2D(sampleRef: sampleRef, parameterNames: .init("FSC-A", "PacificBlue-A")))
                    PairChartsView(core:core, sampleRef:sampleRef, parameters: parameters)
                }
                else {
                    Text("No Data Yet...")
                }
            }
            else {
                Text("No query yet...")
            }
        }
        .onAppear {
//            query = core.histogram(sampleRef: sampleRef, parameterName: "FSC-A")
            query = core.loadSample(.init(sampleRef, includeData: false))
        }

    }
}

#Preview {
    PairChartsPreview()
}
