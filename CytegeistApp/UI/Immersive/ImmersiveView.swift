//
//  ImmersiveView.swift
//  Cytegeist
//
//  Created by Aaron Moffatt on 7/13/24.
//
#if os(visionOS)

import SwiftUI
import RealityKit
import RealityKitContent


struct ImmersiveView: View {

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(App())
}

#endif
