//
//  BindingButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 5/2/25.
//

import SwiftUI

/// A button style that exposes the pressed state through a binding.
///
/// `BindingButtonStyle` provides a way to track when a button is being pressed by
/// binding the pressed state to an external boolean value. This is useful for custom
/// button implementations that need to respond to press state changes.
///
/// ## Usage
/// ```swift
/// struct CustomButton: View {
///     @State private var isPressed = false
///     
///     var body: some View {
///         Button("Press Me") {
///             // Action
///         }
///         .buttonStyle(BindingButtonStyle(isPressed: $isPressed))
///         .background(isPressed ? .blue : .gray)
///     }
/// }
/// ```
///
/// ## Internal Usage
/// This style is primarily used internally by `ListButton` to track pressed state
/// for immediate visual feedback while the button is being pressed.
public struct BindingButtonStyle: ButtonStyle {
    /// A binding to track the button's pressed state.
    @Binding public var isPressed: Bool

    /// Creates a binding button style.
    ///
    /// - Parameter isPressed: A binding that will be updated with the button's pressed state.
    public init(isPressed: Binding<Bool>) {
        _isPressed = isPressed
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { new in
                isPressed = new
            }
    }
}
