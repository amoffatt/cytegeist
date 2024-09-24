//
//  ContentView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//

import SwiftUI
import RealityKit
import CytegeistCore
import Charts

@MainActor
struct AaronTestContentView: View {
    @State var showFCSSelector: Bool = false
    @State var sample:SampleRef = SampleRef(url:DemoData.facsDivaSample0!)
    
    @State var core:CytegeistCoreAPI = CytegeistCoreAPI()

    var body: some View {
        VStack {
            //            Model3D(named: "Scene", bundle: realityKitContentBundle)
            //                .padding(.bottom, 50)

            Text("Sample Inspector")
                .font(.headline)

            //            ToggleImmersiveSpaceButton()
            Button {
                showFCSSelector = true
            } label: {
                Text("Load FCS File")
            }
            let scale = ScaleType.log
//            ChartView(core, sample:SampleRef(url:DemoData.facsDivaSample0!), parameterName: "FSC-A")
            SampleInspectorView(core, sample: sample)
//            ChartView(core, sample: sample, parameterNames: <#T##String#>)
        }
        .padding()
        .fileImporter(
            isPresented: $showFCSSelector,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false,
            onCompletion: handleFCSFileSelected)
    }

    func handleFCSFileSelected(result:Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            sample = SampleRef(url:urls[0])

        case .failure(let err):
            print("Error selecting FCS file: ", err)
        }
    }

//    func importFCSFile(url:URL) {
//        do {
//            let reader = FCSReader()
//            let fcsFile = try reader.readFCSFile(at: url)
//            print("FCS file events: \(fcsFile.meta.eventCount)")
//        } catch {
//            print("Error reading FCS File at '\(url): \(error)")
//        }
//    }
}

#Preview() {
    AaronTestContentView()
        .environment(App())
}
