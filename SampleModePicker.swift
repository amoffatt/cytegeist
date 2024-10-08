//
//  SampleModePicker.swift
//  CytegeistApp
//
//  Created by Adam Treister on 10/7/24.
//

import Foundation


    //
    //  ReportPicker.swift
    //  filereader
    //
    //  Created by Adam Treister on 8/1/24.
    //

import SwiftUI

struct SampleModePicker: View {
    @Binding var mode: SampleListMode
    
    var body: some View {
        Picker("", selection: $mode) {
            ForEach(SampleListMode.allCases) { sampleMode in
                sampleMode.a
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(minWidth: 60, maxWidth: 60)
//        .onChange(of: mode,   { print("changed)")
//        })
    }
}

extension SampleListMode {
    
    var viewContent: (name: String, systemImage: String) {
        switch self {
            case .gallery:      return ("A", "person.3.sequence.fill")
            case .table:        return ("B", "tablecells")
            case .compact:      return ("C", "square.and.pencil")
        }
    }
    
    var a: some View {
        return Label(viewContent.name, systemImage: viewContent.systemImage)
    }
}
