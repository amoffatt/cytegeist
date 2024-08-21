/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample's side bar view.
*/

import SwiftUI

struct Sidebar: View {
    @Binding var selection: Experiment.ID?

    @EnvironmentObject var store: Store
    @SceneStorage("expansionState") var expansionState = ExpansionState()

    var body: some View {
//        Text("SIDEBAR")
        List(selection: $selection) {
            DisclosureGroup(isExpanded: $expansionState[store.currentYear]) {
                ForEach(store.experiments(in: store.currentYear)) { experiment in
                    SidebarLabel(experiment: experiment)  //
//                        .badge(experiment.numberOfPlantsNeedingWater)
                }
            } label: {
                Label("Current", systemImage: "chart.bar.doc.horizontal")
            }

            Section("History") {
                ExperimentHistoryOutline(range: store.previousYears, expansionState: $expansionState)
            }
        }
        .frame(minWidth: 125)
        .background(.blue)
    }
}

struct SidebarLabel: View {
    var experiment: Experiment

    var body: some View {
        let name = experiment.name
        Label(name, systemImage: "leaf")   //experiment.name
    }
}
