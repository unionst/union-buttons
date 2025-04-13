//
//  MenuButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 4/9/25.
//

import SwiftUI

/// A button style that provides menu-like behavior with immediate feedback and gesture support.
///
/// `MenuButtonStyle` highlights when touched and supports sliding gestures, making it ideal for menu items
/// in lists or navigation components. Use with `enableMenuButtonGestures()` for full gesture support.
///
/// Example:
/// ```swift
/// List {
///     Button("Menu Option 1") { print("Option 1 selected") }
///         .buttonStyle(MenuButtonStyle())
///     
///     Button("Menu Option 2") { print("Option 2 selected") }
///         .buttonStyle(MenuButtonStyle(haptics: true))
/// }
/// .enableMenuButtonGestures()
/// ```
@available(iOS 17.0, macOS 14.0, *)
public struct MenuButtonStyle: PrimitiveButtonStyle {
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat
    let haptics: Bool
    let animation: Animation?
    
    /// Creates a new menu button style instance with the specified parameters.
    ///
    /// - Parameters:
    ///   - horizontalPadding: The horizontal padding to apply to the button content. Defaults to 0.
    ///   - verticalPadding: The vertical padding to apply to the button content. Defaults to 0.
    ///   - haptics: Whether to provide haptic feedback when sliding onto the button. Defaults to true.
    ///   - animation: The animation to use when highlighting the button. Defaults to nil (no animation).
    ///
    /// Example:
    /// ```swift
    /// Button("Customized Menu Item") { action() }
    ///     .buttonStyle(MenuButtonStyle(
    ///         horizontalPadding: 16,
    ///         verticalPadding: 12,
    ///         haptics: true,
    ///         animation: .easeOut(duration: 0.2)
    ///     ))
    /// ```
    public init(
        horizontalPadding: CGFloat = 0,
        verticalPadding: CGFloat = 0,
        haptics: Bool = true,
        animation: Animation? = nil
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.haptics = haptics
        self.animation = animation
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        MenuButtonStyleView(configuration: configuration, style: self)
    }
} 
