//
//  HapticOpacityButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 6/25/25.
//

import SwiftUI

/// Convenience button style that provides opacity-based visual feedback.
///
/// Built on top of `UnionButtonStyle` with universal movement detection. The button fades to 50% 
/// opacity when pressed and provides haptic feedback. Automatically cancels when scrolling or 
/// other parent movement is detected.
///
/// ## Basic Usage
/// ```swift
/// Button("Simple Opacity Button") {
///     print("Tapped!")
/// }
/// .buttonStyle(.hapticOpacity)
/// ```
///
/// ## In a ScrollView
/// ```swift
/// ScrollView {
///     LazyVStack {
///         ForEach(1...50, id: \.self) { item in
///             Button("Item \(item)") {
///                 print("Selected item \(item)")
///             }
///             .buttonStyle(.hapticOpacity)
///             .padding(.horizontal)
///         }
///     }
/// }
/// ```
///
/// ## Custom Haptics
/// ```swift
/// Button("Soft Haptic") {
///     // Action
/// }
/// .buttonStyle(HapticOpacityButtonStyle(.impact(flexibility: .soft)))
/// ```
@available(iOS 17, *)
public struct HapticOpacityButtonStyle: PrimitiveButtonStyle {
    private let haptic: SensoryFeedback?
    private let scrollViewOnly: Bool

    // MARK: Init
    
    /// Creates a haptic opacity button style.
    ///
    /// - Parameters:
    ///   - haptic: The haptic feedback to play when pressed. Defaults to `.impact(flexibility: .rigid)`. Pass `nil` to disable haptics.
    ///   - scrollViewOnly: If `true`, uses legacy scroll view detection instead of universal movement detection. Defaults to `false`.
    ///
    /// ## Basic Usage
    /// ```swift
    /// Button("Tap me") {
    ///     print("Button tapped!")
    /// }
    /// .buttonStyle(.hapticOpacity)
    /// ```
    ///
    /// ## Disable Haptics
    /// ```swift
    /// Button("Silent Button") {
    ///     // Action
    /// }
    /// .buttonStyle(HapticOpacityButtonStyle(nil))
    /// ```
    public init(
        _ haptic: SensoryFeedback? = nil,
        scrollViewOnly: Bool = false
    ) {
        self.haptic = haptic
        self.scrollViewOnly = scrollViewOnly
    }

    public func makeBody(configuration: Configuration) -> some View {
        UnionButtonStyle(
            haptic,
            scrollViewOnly: scrollViewOnly
        ) { label, isPressed in
            label
                .opacity(isPressed ? 0.5 : 1)
                .animation(.spring(duration: isPressed ? 0.1 : 0.3), value: isPressed)
        }
        .makeBody(configuration: configuration)
    }
}

extension PrimitiveButtonStyle where Self == HapticOpacityButtonStyle {
    /// Opacity-based button with universal movement detection and haptic feedback.
    ///
    /// Fades to 50% opacity when pressed and provides haptic feedback. Works with scroll views,
    /// sheets, and any moving container with automatic cancellation during movement.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Fade Button") {
    ///     print("Faded!")
    /// }
    /// .buttonStyle(.hapticOpacity)
    /// ```
    public static var hapticOpacity: Self { .init() }
    
    /// Opacity-based button with custom haptic feedback.
    ///
    /// Fades to 50% opacity when pressed and provides the specified haptic feedback. Works with 
    /// scroll views, sheets, and any moving container with automatic cancellation during movement.
    ///
    /// - Parameter haptic: The haptic feedback to play when the button is pressed.
    ///
    /// ## Usage Examples
    /// ```swift
    /// // Success haptic for positive actions
    /// Button("Save") {
    ///     // Save action
    /// }
    /// .buttonStyle(.hapticOpacity(.success))
    ///
    /// // Warning haptic for destructive actions  
    /// Button("Delete") {
    ///     // Delete action
    /// }
    /// .buttonStyle(.hapticOpacity(.warning))
    ///
    /// // Soft impact for gentle interactions
    /// Button("Like") {
    ///     // Like action
    /// }
    /// .buttonStyle(.hapticOpacity(.impact(flexibility: .soft)))
    /// ```
    public static func hapticOpacity(_ haptic: SensoryFeedback) -> Self { 
        .init(haptic) 
    }
    
    /// Legacy opacity button with scroll view only detection.
    ///
    /// Uses the original scroll view specific detection instead of universal movement detection.
    /// Only recommended for specific compatibility cases.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Legacy Button") {
    ///     print("Legacy tapped!")
    /// }
    /// .buttonStyle(.hapticOpacityScrollViewOnly)
    /// ```
    public static var hapticOpacityScrollViewOnly: Self { .init(scrollViewOnly: true) }
}

// MARK: - Preview

#Preview {
    Button("Tap me") {

    }
    .buttonStyle(.hapticOpacity)
}

