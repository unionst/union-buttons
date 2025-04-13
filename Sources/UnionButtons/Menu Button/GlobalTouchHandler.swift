//
//  GlobalTouchHandler.swift
//  union-buttons
//
//  Created by Ben Sage on 4/9/25.
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
internal struct GlobalTouchHandler: ViewModifier {
    @State private var touchTracker = GlobalTouchTracker.shared
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if touchTracker.touchLocation == nil {
                            touchTracker.beginTouch(at: value.location)
                        } else {
                            touchTracker.updateTouch(to: value.location)
                        }
                    }
                    .onEnded { value in
                        touchTracker.endTouch(at: value.location)
                    }
            )
    }
}

@available(iOS 17.0, macOS 14.0, *)
public extension View {
    /// Enables gesture tracking for menu buttons within this view hierarchy.
    ///
    /// Apply this modifier to a container view that holds buttons styled with `MenuButtonStyle`
    /// to enable touch tracking across the entire container. This allows buttons to respond
    /// to touches that start outside their bounds and slide onto them.
    ///
    /// Example:
    /// ```swift
    /// List {
    ///     ForEach(menuItems) { item in
    ///         Button(item.title) {
    ///             selectedItem = item
    ///         }
    ///         .buttonStyle(MenuButtonStyle())
    ///     }
    /// }
    /// .enableMenuButtonGestures() // Enable gesture tracking for the entire list
    /// ```
    ///
    /// - Returns: A view with menu button gesture tracking enabled.
    func enableMenuButtonGestures() -> some View {
        modifier(GlobalTouchHandler())
    }
} 
