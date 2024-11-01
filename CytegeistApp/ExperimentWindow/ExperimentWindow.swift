//
//  ExperimentWindow.swift
//  CytegeistApp
//
//  Created by AM on 10/14/24.
//

import SwiftUI
import CObservation

struct ExperimentWindow: View {
    @Environment(\.undoManager) var undoManager
    var document: CDocument
    
    var body: some View {
        VStack {
//            if let experiment {
            ExperimentView(experiment: document.content)
//            } else {
//                Text("Loading...")      // Awaiting the UndoManager being set
//            }
        }
        .onChange(of: undoManager, initial: true) {
            document.context.undoManager = undoManager
//            if experiment == nil && undoManager != nil {
//                let context = CObjectContext(undoManager: undoManager)
//                context.withContext {
//                    experiment = Experiment()
//                }
//            }
        }
    }
}

//#Preview {
//    ExperimentWindow()
//}
