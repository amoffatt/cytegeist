/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The focused value definitions.
*/

import SwiftUI
import CytegeistCore

extension FocusedValues {
    var experiment: Binding<Experiment>? {
        get { self[FocusedExperimentKey.self] }
        set { self[FocusedExperimentKey.self] = newValue }
    }

    var selection: Binding<Set<Sample.ID>>? {
        get { self[FocusedExperimentSelectionKey.self] }
        set { self[FocusedExperimentSelectionKey.self] = newValue }
    }

    private struct FocusedExperimentKey: FocusedValueKey {
        typealias Value = Binding<Experiment>
    }

    private struct FocusedExperimentSelectionKey: FocusedValueKey {
        typealias Value = Binding<Set<Sample.ID>>
    }
    
    var analysisNode: AnalysisNode?? {
        get { self[FocusedAnalysisNodeKey.self] }
        set { self[FocusedAnalysisNodeKey.self] = newValue }
    }
    
    private struct FocusedAnalysisNodeKey: FocusedValueKey {
        typealias Value = AnalysisNode?
    }
}
