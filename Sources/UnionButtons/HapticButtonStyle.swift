//
//  HapticButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 6/25/25.
//

import SwiftUI

/// Button style that provides haptic feedback only - no visual changes.
///
/// Built on top of `UnionButtonStyle` with universal movement detection. The button provides
/// haptic feedback on press but no visual transformation. Useful when you want haptic feedback
/// without changing the button's appearance.
///
/// ## Basic Usage
/// ```swift
/// Button("Invisible Press") {
///     print("Pressed!")
/// }
/// .buttonStyle(.haptic)
/// ```
///
/// ## Custom Haptic
/// ```swift
/// Button("Success Sound") {
///     // Save action
/// }
/// .buttonStyle(HapticButtonStyle(.success))
/// ```
///
/// ## Silent Button
/// ```swift
/// Button("Silent") {
///     // Action
/// }
/// .buttonStyle(HapticButtonStyle(nil))
/// ```
@available(iOS 17, *)
public struct HapticButtonStyle: PrimitiveButtonStyle {
    private let haptic: SensoryFeedback?

    // MARK: Init
    
    /// Creates a haptic-only button style.
    ///
    /// - Parameter haptic: The haptic feedback to play when pressed. Defaults to `.impact(flexibility: .rigid)`. Pass `nil` to disable haptics.
    public init(_ haptic: SensoryFeedback? = .impact(flexibility: .rigid)) {
        self.haptic = haptic
    }

    public func makeBody(configuration: Configuration) -> some View {
        UnionButtonStyle(haptic) { label, _ in
            label
        }
        .makeBody(configuration: configuration)
    }
}

extension PrimitiveButtonStyle where Self == HapticButtonStyle {
    /// Button with haptic feedback only - no visual changes.
    ///
    /// Provides default impact haptic feedback on press but no visual transformation.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Invisible Press") {
    ///     print("Pressed!")
    /// }
    /// .buttonStyle(.haptic)
    /// ```
    public static var haptic: Self { .init() }
    
    /// Button with custom haptic feedback only - no visual changes.
    ///
    /// Provides the specified haptic feedback on press but no visual transformation.
    ///
    /// - Parameter haptic: The haptic feedback to play when pressed.
    ///
    /// ## Usage Examples
    /// ```swift
    /// // Success haptic with no visual change
    /// Button("Save") {
    ///     // Save action
    /// }
    /// .buttonStyle(.haptic(.success))
    ///
    /// // Silent button with no haptic or visual change
    /// Button("Silent") {
    ///     // Action
    /// }
    /// .buttonStyle(.haptic(nil))
    /// ```
    public static func haptic(_ haptic: SensoryFeedback?) -> Self {
        .init(haptic)
    }
}

// MARK: - Preview

#Preview {
    Button("Haptic Test") {

    }
    .buttonStyle(.haptic)
} 
