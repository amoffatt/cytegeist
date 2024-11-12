//
//  ReportPicker.swift
//  filereader
//
//  Created by Adam Treister on 8/1/24.
//

import SwiftUI

struct ReportModePicker: View {
    @Binding var mode: ReportMode
    
    var body: some View {
        Picker("Report Mode", selection: $mode) {
            ForEach(ReportMode.allCases) { reportMode in
                reportMode.label
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

extension ReportMode {
    
    var labelContent: (name: String, systemImage: String) {
        switch self {
            case .gating:      return ("Gating", "square.and.pencil")
            case .table:       return ("Table", "tablecells")
            case .layout:      return ("Layout", "door.french.closed")  //"square.grid.3x3.topleft.filled"
        }
    }
    
    var label: some View {
        let content = labelContent
        return Label(content.name, systemImage: content.systemImage)
    }
}
