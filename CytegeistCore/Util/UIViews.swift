//
//  UIViews.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/30/24.
//

import Foundation
import SwiftUI


struct LoadingOverlay<Content: View>: View {
    let isLoading: Bool
    let content: () -> Content

    var body: some View {
        ZStack {
            content()
            
            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(3)
            }
        }
        .animation(.easeInOut, value: isLoading)
    }
}
