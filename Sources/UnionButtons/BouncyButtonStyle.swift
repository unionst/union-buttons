//
//  BouncyButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 5/5/25.
//

import SwiftUI
import UnionHaptics

/// Convenience button style that provides scale-based visual feedback.
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
/// ## Custom Transform
/// ```swift
/// Button("Custom Bounce") {
///     // Action
/// }
/// .buttonStyle(BouncyButtonStyle { label, isPressed in
///     label
///         .scaleEffect(isPressed ? 1.1 : 1.0)
///         .rotationEffect(.degrees(isPressed ? 3 : 0))
/// })
/// ```
///
/// ## In ScrollView with Custom Animation
/// ```swift
/// ScrollView {
///     LazyVStack {
///         ForEach(1...20, id: \.self) { item in
///             Button("Bouncy Item \(item)") {
///                 print("Selected \(item)")
///             }
///             .buttonStyle(BouncyButtonStyle(
///                 animationDuration: 0.2
///             ) { label, isPressed in
///                 label
///                     .padding()
///                     .background(.blue, in: .capsule)
///                     .scaleEffect(isPressed ? 0.95 : 1.0)
///             })
///         }
///     }
/// }
/// ```
@available(iOS 17, *)
public struct BouncyButtonStyle<Transformed: View>: PrimitiveButtonStyle {
    public typealias Transform = (PrimitiveButtonStyleConfiguration.Label, /* pressed */ Bool) -> Transformed

    private let haptics: Bool
    private let animationDuration: CGFloat
    private let transform: Transform

    // MARK: – Initialisers

    /// Deprecated: `scrollView` is ignored; the style auto‑detects any enclosing scroll view.
    @available(*, deprecated, message: "scrollView parameter is deprecated and ignored.")
    public init(
        scrollView: Axis? = nil,
        haptics: Bool = true,
        animationDuration: CGFloat = 0.15,
        @ViewBuilder transform: @escaping Transform = { label, _ in label }
    ) {
        self.init(haptics: haptics, animationDuration: animationDuration, transform: transform)
    }

    /// Creates a bouncy button style with custom animation and transform.
    ///
    /// - Parameters:
    ///   - haptics: Whether to enable haptic feedback. Defaults to `true`.
    ///   - animationDuration: Duration of the bounce animation in seconds. Defaults to 0.15.
    ///   - transform: A closure that transforms the button label based on pressed state.
    ///
    /// ## Example with Custom Animation Duration
    /// ```swift
    /// Button("Slow Bounce") {
    ///     // Action
    /// }
    /// .buttonStyle(BouncyButtonStyle(animationDuration: 0.3) { label, isPressed in
    ///     label.scaleEffect(isPressed ? 1.2 : 1.0)
    /// })
    /// ```
    ///
    /// ## Example with No Haptics
    /// ```swift
    /// Button("Silent Bounce") {
    ///     // Action
    /// }
    /// .buttonStyle(BouncyButtonStyle(haptics: false) { label, isPressed in
    ///     label.scaleEffect(isPressed ? 0.9 : 1.0)
    /// })
    /// ```
    public init(
        haptics: Bool = true,
        animationDuration: CGFloat = 0.15,
        @ViewBuilder transform: @escaping Transform = { label, _ in label }
    ) {
        self.haptics = haptics
        self.animationDuration = animationDuration
        self.transform = transform
    }

    // MARK: – PrimitiveButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        UnionButtonStyle(
            haptics ? .impact(flexibility: .rigid) : nil
        ) { label, isPressed in
            transform(label, isPressed)
                .animation(.bouncy(duration: animationDuration), value: isPressed)
        }
        .makeBody(configuration: configuration)
    }
}

// MARK: Sugar
extension PrimitiveButtonStyle where Self == BouncyButtonStyle<AnyView> {
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
    public static var bouncy: Self { 
        BouncyButtonStyle { label, isPressed in
            AnyView(label.scaleEffect(isPressed ? 1.05 : 1))
        }
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


