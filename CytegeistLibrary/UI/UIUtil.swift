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
        // Delay fade in so indicator doesn't appear if loading only takes a moment
        let ease:Animation = isLoading ? .easeInOut.delay(0.5) : .easeInOut
        
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
        .animation(ease, value: isLoading)
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

    public static func text<S:PrimitiveButtonStyle>(_ name:LocalizedStringKey, _ style:S = .plain, role:ButtonRole? = nil, action: @escaping Action) -> some View {
        Button(name, role: role, action: action)
            .buttonStyle(style)
    }
    
    public static func ok(_ titleKey: LocalizedStringKey = "Ok", action: @escaping () -> Void) -> some View {
        text(titleKey, action:action)
            .keyboardShortcut(.defaultAction)
    }
    
    public static func cancel(action: @escaping () -> Void = {}) -> some View {
        text("Cancel", role:.cancel, action:action)
            .keyboardShortcut(.cancelAction)
    }
    
    public static func delete(action: @escaping () -> Void = {}) -> some View {
        text("Delete", role:.destructive, action:action)
            .keyboardShortcut(.defaultAction)
    }

//    public static func
    
}



public extension ControlSize {
    var scaling: Double {
        switch self {
        case .mini:
                0.5
        case .small:
                0.75
        case .regular:
            1
        case .large:
            1.5
        case .extraLarge:
            2
        @unknown default:
            1
        }
    }
}


public func castBinding<SrcType, DstType>(_ src:Binding<SrcType?>) -> Binding<DstType?> {
    .init(get: {
        src.wrappedValue as? DstType
    }, set: {
        src.wrappedValue = $0 as? SrcType
    })
}

/// Binding which returns true when src Binding is non nil, otherwise false.
/// Setting the binding's value writes nil to the src value.
/// Used for UI popup isPresented:Binding<Bool>
public func isNonNilBinding<T>(_ src:Binding<T?>) -> Binding<Bool> {
    .init(get: {
        src.wrappedValue != nil
    }, set: { _ in
        src.wrappedValue = nil
    })
}



public extension View {
    func onPress(pressed: @escaping (Bool) -> Void) -> some View {
        modifier(OnPressGestureModifier(pressed: pressed))
    }
}

private struct OnPressGestureModifier: ViewModifier {
    @State private var isPressed = false
    let pressed: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !self.isPressed {
                        self.isPressed = true
                        self.pressed(true)
                    }
                }
                .onEnded { _ in
                    if self.isPressed {
                        self.isPressed = false
                        self.pressed(false)
                    }
                })
    }
}
