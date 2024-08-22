/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample's side bar view.
*/

import SwiftUI
import CytegeistLibrary

enum ListSection: String, Identifiable, Hashable {
    var id: String { rawValue }
    
    case current
    case history
}

struct MainAppSidebar: View {

    @Environment(App.self) var app: App
    @SceneStorage("expansionState") var expansionState = ExpansionState()
    @State var lastSelectedSection:ListSection = .current
//    @State var selection: SidebarSelection? = nil
    @State var showDeleteConfirmation: Bool = false
    

    var body: some View {
        
        // AM Important: Selection needs to differentiate the same experiment between
        // different sections in order to support SwiftUI renaming behavior
        let selection:Binding<SidebarSelection?> = .init {
            let s = app.getSelectedExperiment().map {
                SidebarSelection(lastSelectedSection, $0.id)
            }
            return s
        } set: {
            lastSelectedSection = $0?.section ?? .current
            app.selectedExperiment = $0?.experiment
        }

        List(selection: selection) {
//            SidebarLabel(experiment: e)
            DisclosureGroup(isExpanded: $expansionState[-1]) {
                ForEach(app.recentExperiments) { experiment in
                    SidebarLabel(experiment: experiment, section: .current)  //
//                        .badge(experiment.numberOfPlantsNeedingWater)
                }
            } label: {
                Label("Current Experiments", systemImage: "chart.bar.doc.horizontal")
            }

            Section("History") {
                ExperimentHistoryOutline(expansionState: $expansionState)
            }
        }
        .frame(minWidth: 200, idealWidth: 350, maxWidth: 1200)
//        .toolbar {
//        }
        .safeAreaInset(edge: .top) {
            
            HStack(spacing: 16) {
                Spacer()
                //            ToolbarItem {
                Buttons.icon("New Experiment", .add) {
                    app.createNewExperiment()
                }
                //                EmptyView().padding()
                
                //            Spacer(minLength: 10)
                //            }
                Buttons.icon("Delete Experiment", .delete) {
                    showDeleteConfirmation = true
                }
                .disabled(app.getSelectedExperiment() == nil)
            }
            .font(.title3)
            .padding(.horizontal, 12)
        }
        .confirmationDialog(
            "Delete experiment '\(app.getSelectedExperiment()?.name ?? "<no selection>")' ?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let selected = app.getSelectedExperiment() {
                    app.removeExperiment(selected)
                }
            }
        }
    }
}

struct SidebarSelection : Identifiable, Hashable, Equatable {
    var id: String { "\(section) - \(experiment)"}
//    var id: UUID { experiment }

    let section:ListSection
    let experiment: Experiment.ID
    init(_ section: ListSection, _ experiment: Experiment.ID) {
        self.section = section
        self.experiment = experiment
    }
}

struct SidebarLabel: View, Identifiable {
    var id: SidebarSelection { SidebarSelection(section, experiment.id) }
    
    let experiment: Experiment
    let section:ListSection

    var body: some View {
        @Bindable var experiment = experiment
        
        // AM Important: tag() is for selection, id() is for the list to track unique items
        // It is important that even if the same experiment shows up twice in
        // the List, that each list item has a unique id and tag
        TextField(text: $experiment.name) {}
            .tag(id)
            .id(id)
    }
}
