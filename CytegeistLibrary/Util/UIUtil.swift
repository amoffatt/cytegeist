//
//  UIViews.swift
//  CytegeistCore
//
//  Created by Aaron Moffatt on 7/30/24.
//

import Foundation
import SwiftUI

private func progressViewEase(_ visible: Bool) -> Animation {
    visible ? .easeInOut.delay(0.5) : .easeInOut
}


public struct LoadingOverlay<Content: View>: View {
    
    let isLoading: Bool
    let scale: CGFloat
    let dimming: Bool
    
    let content: () -> Content

    public init(isLoading: Bool, scale:CGFloat = 1, dimming:Bool = false, content: @escaping () -> Content) {
        self.isLoading = isLoading
        self.scale = scale
        self.dimming = dimming
        self.content = content
    }
    
    public var body: some View {
        // Delay fade in so indicator doesn't appear if loading only takes a moment
        
        
        ZStack {
            content()
            
            if isLoading {
                if dimming {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                }
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(scale)
                    .frame(minWidth: 10, maxWidth: 10)
            }
        }
        .animation(progressViewEase(isLoading), value: isLoading)
    }
}

public struct CProgressView: View {
    let visible:Bool
    public init(visible: Bool) {
        self.visible = visible
    }
    
    public var body: some View {
        ZStack {
            if visible {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                //            .scaleEffect(scale)
                //            .frame(minWidth: 10, maxWidth: 10)
            }
        }
        .animation(progressViewEase(visible), value: visible)
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
    
    func onArrowKeys(_ handler:@escaping (CGPoint) -> Void) -> some View {
        self
        .onKeyPress(.leftArrow)     { handler(CGPoint(x: -1.0, y: 0)); return .handled }
        .onKeyPress(.rightArrow)    { handler(CGPoint(x: 1.0, y: 0)); return .handled }
        .onKeyPress(.upArrow)       { handler(CGPoint(x: 0, y: -1.0)); return .handled }
        .onKeyPress(.downArrow)     { handler(CGPoint(x: 0, y: 1.0)); return .handled }
    }
}


public struct Icon {
    public static let
    add = Icon("plus", scaling:1.4),
    delete = Icon("trash")
    
    let systemImage:String
    let scaling: CGFloat
    
    public init(_ systemImage: String, scaling: CGFloat = 1) {
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

public func readOnlyBinding<T>(_ value:@escaping @autoclosure () -> T) -> Binding<T> {
    .init {
        value()
    } set: { _ in }
}



public extension View {
    func onPress(pressed: @escaping (Bool) -> Void) -> some View {
        modifier(OnPressGestureModifier(pressed: { p, _ in pressed(p) }))
    }
    
    func onPress(pressed: @escaping (Bool, CGPoint) -> Void) -> some View {
        modifier(OnPressGestureModifier(pressed: pressed))
    }
}

private struct OnPressGestureModifier: ViewModifier {
    @State private var isPressed = false
    let pressed: (Bool, CGPoint) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { info in
                    if !self.isPressed {
                        self.isPressed = true
                        self.pressed(true, info.startLocation)
                    }
                }
                .onEnded { info in
                    if self.isPressed {
                        self.isPressed = false
                        self.pressed(false, info.location)
                    }
                })
    }
}

public extension View {
    /// from: https://www.avanderlee.com/swiftui/conditional-view-modifier/
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

public extension Path {
    init(points:[CGPoint]) {
        self.init() { path in
            guard let firstPoint = points.first else { return }
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
    }
}


//public extension FocusedValues {
//
//    struct DeleteValueKey: FocusedValueKey {
//        public typealias Value = () -> Void
//    }
//
//    /// Fix for Delete command handling in SwiftUI
//    /// from: https://stackoverflow.com/questions/74429687/swiftui-ondeletecommand-doesnt-work-with-navigationsplitview-on-macos
//    var delete: DeleteValueKey.Value? {
//        get { self[DeleteValueKey.self] }
//        set { self[DeleteValueKey.self] = newValue }
//    }
//}


public extension String {
    func sizeOfString(usingFont font: Font) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size
    }
}
