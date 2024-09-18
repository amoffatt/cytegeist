///*
//See LICENSE folder for this sample’s licensing information.
//
//Abstract:
//The garden history outline view.
//*/
//
//import SwiftUI
//
//fileprivate struct HistoryLabel: View {
//    var year: Int
//    var body: some View {
//        let current = year == Date.currentYear
//        Label(String(year), systemImage: current ? "chart.bar.doc.horizontal" : "clock")
//            .fontWeight(current ? .bold : .black)
//    }
//}
//
//
//struct ExperimentHistoryOutline: View {
//    @Environment(App.self) var app: App
////    var range: ClosedRange<Int>
//    @Binding var expansionState: ExpansionState
//    
//    var body: some View {
//        ForEach(app.experimentsByYearCreated, id: \.year) { (year, experiments) in
////            DisclosureGroup(isExpanded: $expansionState[year]) {
////                ForEach(experiments) { experiment in
////                    SidebarLabel(experiment: experiment, section: .history)
////                }
////            } label: {
////                HistoryLabel(year: year)
////            }
//        }
//    }
//}
