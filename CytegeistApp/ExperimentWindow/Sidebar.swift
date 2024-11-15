/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample's side bar view.
*/

import SwiftUI
import CytegeistCore
import CytegeistLibrary


struct Sidebar : View {
 
    enum ListSection: String, Identifiable, Hashable {
        var id: String  { rawValue }
        
        case current
        case history
    }

    @Environment(App.self) var app: App
    @Environment(\.undoManager) var undoManager
    @SceneStorage("expansionState1") var expansionState1 = ExpansionState()
    @SceneStorage("expansionState2") var expansionState2 = ExpansionState()
    @SceneStorage("expansionState3") var expansionState3 = ExpansionState()
//    @State var lastSelectedSection:ListSection = .current
        //    @State var selection: SidebarSelection? = nil
    @State var showDeleteConfirmation: Bool = false
    @State var groupName = "My Group"
    @State var keyword = "$PATIENT"
    @State var value = "MOUSE 1"
    @State var  groupColor = Color.brown
    
    
    var body: some View {
        
        VStack {
            HStack {
                if let undoManager {
                        Button("Undo") {
                            undoManager.undo()
                        }
                        .disabled(!undoManager.canUndo)
                        Button("Redo") {
                            undoManager.redo()
                        }
                        .disabled(!undoManager.canRedo)
                }
                
            }
            
//            toprowButtons
  
            HStack
            { Button("All", action: allSamples)
                    .dropDestination(for: AnalysisNode.self) { (items, position) in
                        addNodesToGroup(items, "All Samples")
                        return true
                    }
                Button("Controls", action: controls)
                    .dropDestination(for: AnalysisNode.self) { (items, position) in
                        addNodesToGroup(items, "Controls")
                        return true
                    }
                Button("Tests", action: tests)
                    .dropDestination(for: AnalysisNode.self) { (items, position) in
                        addNodesToGroup(items, "Tests")
                        return true
                    }
            }
            VSplitView {
                VStack {
//                    VSplitView {
//                        VStack {
                            @State var panelselection: SidebarPanelSelection? = nil
                            List(selection: $panelselection) {
                                if  let exp = app.getSelectedExperiment()  {
                                    DisclosureGroup("Panels", isExpanded: $expansionState1[-1]) {
                                        ForEach(exp.panels) { panel in
                                            SidebarPanelLabel(sidebar: self, panel: panel, section: .current)
                                        }
                                    }
                                }
                            }
//                        }
//                        VStack {

                }
                
                
                    //            groupDefinitionDivider
                
                    //            let menuitems: [MenuItem] = [MenuItem("a")]
                VStack {
                    HStack  {
                        Button("Add", systemImage: "plus", action: addGroup)
                        TextField("Name", text: $groupName).frame(width: 80)
                        ColorPicker("", selection: $groupColor, supportsOpacity: false).frame(maxWidth: 20, maxHeight: 20)
                    }
                    HStack {
                        TextField("Key", text: $keyword).frame(width: 80)
                        Menu(""){
                            Button("Patient", action: {})
                            Button("SampleID", action: {})
                            Button("Date", action: {})
                            Menu("Advanced") {
                                Button("FITC", action: {})
                                Button("PE", action: {})
                                Button("APC", action: {})
                                Button("APC-Cy7", action: {})
                            }
                        }.frame(width: 20, height: 30, alignment: .topLeading)
                        TextField("Value", text: $value).frame(width: 80)
                    }
                }.opacity(0.9)
                    .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
                    .border(.black.opacity(0.66))
 
                @State var groupselection: SidebarGroupSelection? = nil
                List(selection: $groupselection) {
                    if  let exp = app.getSelectedExperiment() {
                        DisclosureGroup("Groups", isExpanded: $expansionState2[-1]) {
                            ForEach(exp.groups) { group in
                                SidebarGroupLabel(sidebar: self, group: group, section: .current)  //
                            }
                        }
                    }
                        //                            }
                }
                    //                .draggable(any Transferable())
                
//                @State var experimentselection: SidebarExperimentSelection? = nil
//                List(selection: $experimentselection) {
//                    DisclosureGroup(isExpanded: $expansionState3[-1]) {
//                        ForEach(app.recentExperiments) { experiment in
//                            SidebarExperimentLabel(sidebar: self, experiment: experiment, section: .current)  //
//                                                                                                              //                        .badge(experiment.numberOfPlantsNeedingWater)
//                        }
//                    }
//                label: {    Label("History", systemImage: "arrow.swap")     }
//                }
//                .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 800)
          }.opacity(0.7)

        }.opacity(0.8)
    }
//--------------------------------------------------------------------------------------------------------------
//    
//    var toprowButtons :   View {
//        var body :  any View {
//            HStack
//            { Button("All", action: allSamples)
//                    .dropDestination(for: AnalysisNode.self) { (items, position) in
//                        addNodesToGroup(items, "All Samples")
//                        return true
//                    }
//                Button("Controls", action: controls)
//                    .dropDestination(for: AnalysisNode.self) { (items, position) in
//                        addNodesToGroup(items, "Controls")
//                        return true
//                    }
//                Button("Tests", action: tests)
//                    .dropDestination(for: AnalysisNode.self) { (items, position) in
//                        addNodesToGroup(items, "Tests")
//                        return true
//                    }
//            }
//        }
//    }
    
//    
//    var groupDefinitionDivider: any View {
//        var body : any View {
//          VStack {
//                HStack  {
//                    Button("Add", systemImage: "plus", action: addGroup)
//                    TextField("Name", text: $groupName).frame(width: 80)
//                    ColorPicker("", selection: $groupColor, supportsOpacity: false).frame(maxWidth: 20, maxHeight: 20)
//                }
//                HStack {
//                    TextField("Key", text: $keyword).frame(width: 80)
//                    TextField("Value", text: $value).frame(width: 80)
//                }
//            }.background(.black.opacity(0.04))
//        }
//    }
        //--------------------------------------------------------------------------------------------------------------
    
    func addGroup()
    {
        app.getSelectedExperiment()!.groups.append(
            CGroup(name: groupName, color: groupColor, keyword: keyword, value: value))
        print (app.getSelectedExperiment()!.groups.count)
            //        showAlert = true
    }
    func addNodesToGroup(_ nodes: [AnalysisNode], _ groupName: String)
    {
        print ("Adding \(nodes.count) to the group: " + groupName)
    }

        //    func makePanel()
        //    {
        //        print ("makePanel")
        //
        //    }
    func allSamples()
    {
        print ("allSamples")
    }
    func controls()
    {
        print ("controls")
    }
    func tests()
    {
        print ("tests")
    }
        //--------------------------------------------------------------------------------------------------------------
    
    struct SidebarExperimentSelection : Identifiable, Hashable, Equatable {
        var id: String { "\(section) - \(experiment)"}
            //    var id: UUID { experiment }
        
        public static func == (lhs: SidebarExperimentSelection, rhs: SidebarExperimentSelection) -> Bool {
            lhs.id == rhs.id
        }
        let section:ListSection
        let experiment: Experiment.ID
        init(_ section: ListSection, _ experiment: Experiment.ID) {
            self.section = section
            self.experiment = experiment
        }
    }
    struct SidebarPanelSelection : Identifiable, Hashable, Equatable {
        var id: String { "\(section) - \(panel)"}
            //    var id: UUID { experiment }
        public static func == (lhs: SidebarPanelSelection, rhs: SidebarPanelSelection) -> Bool {
            lhs.id == rhs.id
        }
        
        let section:ListSection
        let panel: CPanel.ID
        init(_ section: ListSection, _ panel: CPanel.ID) {
            self.section = section
            self.panel = panel
        }
    }
    struct SidebarGroupSelection : Identifiable, Hashable, Equatable {
        var id: String { "\(section) - \(group)"}
            //    var id: UUID { experiment }
        
        public static func == (lhs: SidebarGroupSelection, rhs: SidebarGroupSelection) -> Bool {
            lhs.id == rhs.id
        }
        let section:ListSection
        let group: CGroup.ID
        init(_ section: ListSection, _ group: CGroup.ID) {
            self.section = section
            self.group = group
        }
    }
        //--------------------------------------------------------------------------------------------------------------
    
    struct SidebarExperimentLabel: View, Identifiable {
        var id: SidebarExperimentSelection { SidebarExperimentSelection(section, experiment.id) }
        var sidebar: Sidebar
        let experiment: Experiment
        let section: ListSection
        
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
    
    struct SidebarGroupLabel: View, Identifiable  {
        var id: SidebarGroupSelection { SidebarGroupSelection(section, group.id) }
        var sidebar: Sidebar
        var group: CGroup
        let section: ListSection
        
        var body: some View {
            let name = group.name
            Label(name, systemImage: "leaf")
                .dropDestination(for: AnalysisNode.self) { (items, position) in
                    sidebar.addNodesToGroup(items, group.name)
                    return true
                }
        }
    }
    
    struct SidebarPanelLabel: View, Identifiable  {
        var id: SidebarPanelSelection { SidebarPanelSelection(section, panel.id) }
        var sidebar: Sidebar
        var panel: CPanel
        let section: ListSection
        
        var body: some View {
            let name = panel.name
            Label(name, systemImage: "cat")
        }
    }
    
}
//-----------------------------------
//
//    struct SidebarPanelLabel: View, Identifiable {
//        var id: SidebarPanelSelection { SidebarPanelSelection(section, panel.id) }
//        var sidebar: MainAppSidebar
//        var panel: CPanel
//        let section: ListSection
//        
//        
//        var body: some View {
//            @Bindable var panel = panel
//            
//                // AM Important: tag() is for selection, id() is for the list to track unique items
//                // It is important that even if the same experiment shows up twice in
//                // the List, that each list item has a unique id and tag
//            TextField(text: $panel.name) {}
//                .tag(id)
//                .id(id)
//        }
//    }


    //    }
    //            .frame(minWidth: 200, idealWidth: 350, maxWidth: 1200)
    //        .toolbar {
    //        }
    //            .safeAreaInset(edge: .top) {
    //
    //                HStack(spacing: 16) {
    //                    Spacer()
    //                    Buttons.icon("New Experiment", .add) {  app.createNewExperiment()    }
    //                    Buttons.icon("Delete Experiment", .delete) {  showDeleteConfirmation = true }
    //                        .disabled(app.getSelectedExperiment() == nil)
    //                }
    //                .font(.title3)
    //                .padding(.horizontal, 12)
    //            }
    //            .confirmationDialog(
    //                "Delete experiment '\(app.getSelectedExperiment()?.name ?? "<no selection>")' ?", isPresented: $showDeleteConfirmation) {
    //                    Button("Delete", role: .destructive) {
    //                        if let selected = app.getSelectedExperiment() {
    //                            app.removeExperiment(selected)
    //                        }
    //                    }
    //                }

        // AM Important: Selection needs to differentiate the same experiment between
        // different selections in order to support SwiftUI renaming behavior
        //        let selection:Binding<SidebarExperimentSelection?> = .init {
        //            let s = app.getSelectedExperiment().map {
        //                SidebarExperimentSelection(lastSelectedSection, $0.id)
        //            }
        //            return s
        //        } set: {
        //            lastSelectedSection = $0?.section ?? .current
        //            app.selectedExperiment = $0?.experiment
        //        }
        //
    
