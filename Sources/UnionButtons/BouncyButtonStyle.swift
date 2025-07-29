//
//  BouncyButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 5/5/25.
//

import SwiftUI
import UnionHaptics

/// Button style that provides scale-based visual feedback.
///
/// Built on top of `UnionButtonStyle` with universal movement detection. The button scales when 
/// pressed and provides haptic feedback. Automatically cancels when scrolling or other parent 
/// movement is detected.
///
/// ## Basic Usage
/// ```swift
/// Button("Bouncy Button") {
///     print("Bounced!")
/// }
/// .buttonStyle(.bouncy)
/// ```
///
/// ## Custom Haptic
/// ```swift
/// Button("Success Bounce") {
///     // Action
/// }
/// .buttonStyle(BouncyButtonStyle(.success))
/// ```
///
/// ## Silent Bounce
/// ```swift
/// Button("Silent Bounce") {
///     // Action
/// }
/// .buttonStyle(BouncyButtonStyle(nil))
/// ```
@available(iOS 17, *)
public struct BouncyButtonStyle: PrimitiveButtonStyle {
    private let haptic: SensoryFeedback?

    // MARK: – Initialisers

    /// Creates a bouncy button style with scale effect.
    ///
    /// - Parameter haptic: The haptic feedback to play when pressed. Defaults to `.impact(flexibility: .rigid)`. Pass `nil` to disable haptics.
    ///
    /// ## Example with Success Haptic
    /// ```swift
    /// Button("Save Changes") {
    ///     // Save action
    /// }
    /// .buttonStyle(BouncyButtonStyle(.success))
    /// ```
    ///
    /// ## Example with No Haptics
    /// ```swift
    /// Button("Silent Bounce") {
    ///     // Action
    /// }
    /// .buttonStyle(BouncyButtonStyle(nil))
    /// ```
    public init(_ haptic: SensoryFeedback? = .impact(flexibility: .rigid)) {
        self.haptic = haptic
    }

    // MARK: – PrimitiveButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        UnionButtonStyle(haptic) { label, isPressed in
            label
                .scaleEffect(isPressed ? 1.05 : 1)
                .animation(.bouncy(duration: 0.15), value: isPressed)
        }
        .makeBody(configuration: configuration)
    }
}

// MARK: Sugar
extension PrimitiveButtonStyle where Self == BouncyButtonStyle {
    /// Bouncy button with scale effect and universal movement detection.
    ///
    /// Provides a 1.05x scale effect when pressed with haptic feedback and automatic
    /// scroll/movement cancellation.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Quick Bounce") {
    ///     print("Bounced!")
    /// }
    /// .buttonStyle(.bouncy)
    /// ```
    public static var bouncy: Self { .init() }
    
    /// Bouncy button with custom haptic feedback.
    ///
    /// Provides a 1.05x scale effect when pressed with the specified haptic feedback and 
    /// automatic scroll/movement cancellation.
    ///
    /// - Parameter haptic: The haptic feedback to play when pressed.
    ///
    /// ## Usage Examples
    /// ```swift
    /// // Success haptic for positive actions
    /// Button("Save") {
    ///     // Save action
    /// }
    /// .buttonStyle(.bouncy(.success))
    ///
    /// // Warning haptic for destructive actions
    /// Button("Delete") {
    ///     // Delete action
    /// }
    /// .buttonStyle(.bouncy(.warning))
    ///
    /// // Silent bouncy button
    /// Button("Silent Bounce") {
    ///     // Action
    /// }
    /// .buttonStyle(.bouncy(nil))
    /// ```
    public static func bouncy(_ haptic: SensoryFeedback?) -> Self {
        .init(haptic)
    }
}

#Preview {
    Button {

    } label: {
        Text("Hello world")
            .frame(maxWidth: .infinity)
            .padding()
            .background(.quaternary, in: .capsule)
    }
    .buttonStyle(.bouncy)
}


