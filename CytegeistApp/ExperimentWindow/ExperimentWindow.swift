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
    @State var experiment: Experiment?
    
    var body: some View {
        VStack {
            if let experiment {
                ExperimentView(experiment: experiment)
            } else {
                Text("Loading...")      // Awaiting the UndoManager being set
            }
        }
        .onChange(of: undoManager, initial: true) {
            if experiment == nil && undoManager != nil {
                let context = CObjectContext(undoManager: undoManager)
                context.withContext {
                    experiment = Experiment()
                }
            }
        }
    }
}

#Preview {
    ExperimentWindow()
}
