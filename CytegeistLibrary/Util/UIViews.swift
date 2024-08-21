//
//  UIViews.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/30/24.
//

import Foundation
import SwiftUI


public struct LoadingOverlay<Content: View>: View {
    let isLoading: Bool
    let content: () -> Content

    public init(isLoading: Bool, content: @escaping () -> Content) {
        self.isLoading = isLoading
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            content()
            
            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
        .animation(.easeInOut, value: isLoading)
    }
}


public struct Print: View {
    let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public var body: some View {
        print(value)
        return EmptyView()
    }
}
