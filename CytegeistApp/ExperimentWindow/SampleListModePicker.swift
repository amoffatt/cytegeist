/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The experiment display mode picker found in the toolbar.
*/

import SwiftUI

struct SampleListModePicker: View {
    @Binding var mode: SampleListMode

    var body: some View {
        Picker("", selection: $mode) {
            ForEach(SampleListMode.allCases) { viewMode in
                viewMode.label
                    .labelStyle(.iconOnly)
            }
        }
        .pickerStyle(.segmented)
        .frame(minWidth: 72, maxWidth: 72)
        .padding(4)
    }
}

extension SampleListMode {

    var labelContent: (name: String, systemImage: String) {
        switch self {
        case .table:        return ("Table", "cart.fill")
        case .gallery:      return ("Gallery", "photo")
        case .compact:      return ("Table", "gauge")
        }
    }

    var label: some View {
        let content = labelContent
        return Label(content.name, systemImage: content.systemImage)
    }
}
