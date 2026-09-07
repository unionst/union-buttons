import SwiftUI

/// The press feedback of a transport control — play, pause, skip, a timer’s
/// “set done”: a soft fill blooms under the label and it dips to 90% while the
/// finger is down, and a quick tap still plays the whole down-and-up because
/// `UnionButtonStyle` holds the pressed state for a beat.
///
/// ```swift
/// Button { player.togglePlayPause() } label: {
///     Image(systemName: "pause.fill").font(.system(size: 48))
/// }
/// .buttonStyle(.transport(diameter: 96))
/// ```
///
/// Silent by default — transport controls fire on every skip, so a haptic on
/// each one buzzes. Pass `haptic:` to opt in.
@available(iOS 17, *)
public struct TransportButtonStyle: PrimitiveButtonStyle {
    private let diameter: Double?
    private let shape: AnyShape
    private let fill: Color
    private let pressedScale: Double
    private let haptic: SensoryFeedback?

    /// - Parameters:
    ///   - diameter: A fixed circular hit area. `nil` sizes the control from its label plus the shape’s own padding.
    ///   - shape: The highlight shape. Defaults to a circle; pass `.capsule` or `.rect(cornerRadius:)` for wide controls.
    ///   - fill: The highlight color at full press. Defaults to a 15% primary tint.
    ///   - pressedScale: How far the control dips while pressed. Defaults to 0.9; a wide bar wants something nearer 0.97.
    ///   - haptic: Feedback on activation. Defaults to none.
    public init(
        diameter: Double? = nil,
        shape: some Shape = .circle,
        fill: Color = .primary.opacity(0.15),
        pressedScale: Double = 0.9,
        haptic: SensoryFeedback? = nil
    ) {
        self.diameter = diameter
        self.shape = AnyShape(shape)
        self.fill = fill
        self.pressedScale = pressedScale
        self.haptic = haptic
    }

    public func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(UnionButtonStyle(haptic) { label, isPressed in
                label
                    .frame(width: diameter.map { CGFloat($0) }, height: diameter.map { CGFloat($0) })
                    .background(shape.fill(isPressed ? fill : fill.opacity(0)))
                    .scaleEffect(isPressed ? pressedScale : 1)
                    .contentShape(shape)
                    .animation(.snappy(duration: 0.22), value: isPressed)
            })
    }
}

@available(iOS 17, *)
public extension PrimitiveButtonStyle where Self == TransportButtonStyle {
    /// A circular transport control of a fixed diameter.
    static func transport(diameter: Double) -> TransportButtonStyle {
        TransportButtonStyle(diameter: diameter)
    }

    /// A transport control shaped by its label, highlighted in `shape`.
    static func transport(shape: some Shape = .circle, fill: Color = .primary.opacity(0.15), pressedScale: Double = 0.9) -> TransportButtonStyle {
        TransportButtonStyle(shape: shape, fill: fill, pressedScale: pressedScale)
    }
}
