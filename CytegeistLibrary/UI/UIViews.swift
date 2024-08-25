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

public extension View {
    func fillAvailableSpace() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



//Button("Open FCS Files", systemImage: "plus", action: { showFCSImporter = true } )

//public struct IconButton : View{
//    let name:String
//    let icon:String
//    let action: () -> Void
//    
//    public init(_ name: String, icon: String, action: @escaping () -> Void) {
//        self.name = name
//        self.icon = icon
//        self.action = action
//    }
//    
//    public var body: some View {
//        Button(name, systemImage: icon, action:action)
//    }
//}



public struct Icon {
    public static let
    add = Icon("plus", scaling:1.4),
    delete = Icon("trash")
    
    let systemImage:String
    let scaling: Float
    
    public init(_ systemImage: String, scaling: Float = 1) {
        self.systemImage = systemImage
        self.scaling = scaling
    }
}

public typealias Action = () -> Void

public class Buttons {
    public static func icon(_ name:LocalizedStringKey, _ icon:Icon, action: @escaping Action) -> some View {
        Button(name, systemImage: icon.systemImage, action: action)
            .scaleEffect(CGSize(icon.scaling))
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
    }
    
//    public static func normal(_ name:LocalizedStringKey, _ icon:Icon, action: @escaping Action) -> some View {
//        Button(action: action) {
//            Label(name) {
//                Image(systemName: icon.systemImage)
//                    .scaleEffect(CGSize(icon.scaling))
//            }
//        }
//    }

    public static func toolbar(_ name:LocalizedStringKey, _ icon:Icon, action: @escaping Action) -> some View {
        Button(name, systemImage: icon.systemImage, action: action)
    }

    
//    public static func
    
}


