//
//  UnionButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 6/25/25.
//

import SwiftUI
import UnionHaptics

/// Core movement‑aware button style with universal parent movement detection.
///
/// Works with scroll views, sheets, and any moving container. Provides a transform closure
/// for complete customization of pressed state appearance.
///
/// The button automatically detects when its parent view is moving (scrolling, dragging, etc.)
/// and delays visual/haptic feedback to prevent accidental activation during scroll gestures.
///
/// ## Basic Usage
/// ```swift
/// Button("Tap me") {
///     print("Tapped!")
/// }
/// .buttonStyle(UnionButtonStyle { label, isPressed in
///     label
///         .foregroundStyle(isPressed ? .secondary : .primary)
///         .scaleEffect(isPressed ? 0.95 : 1.0)
/// })
/// ```
///
/// ## Custom Effects
/// ```swift
/// Button("Custom Button") {
///     // Handle action
/// }
/// .buttonStyle(UnionButtonStyle(
///     .impact(flexibility: .soft),
///     delay: .milliseconds(150)
/// ) { label, isPressed in
///     label
///         .padding()
///         .background(isPressed ? .blue : .gray, in: .capsule)
///         .rotationEffect(.degrees(isPressed ? 5 : 0))
/// })
/// ```
@available(iOS 17, *)
public struct UnionButtonStyle<Transformed: View>: PrimitiveButtonStyle {
    public typealias Transform = (PrimitiveButtonStyleConfiguration.Label, /* pressed */ Bool) -> Transformed

    private let haptic: SensoryFeedback?
    private let grace: TimeInterval
    private let delay: Duration
    private let scrollViewOnly: Bool
    private let transform: Transform

    // MARK: Init

    /// Creates a new UnionButtonStyle with custom transform.
    ///
    /// - Parameters:
    ///   - haptic: The haptic feedback to play when pressed. Defaults to `.impact(flexibility: .rigid)`. Pass `nil` to disable haptics.
    ///   - delay: Time to wait before showing visual/haptic feedback during interaction. Defaults to `.milliseconds(100)`.
    ///   - scrollViewOnly: If `true`, uses legacy scroll view detection instead of universal movement detection. Defaults to `false`.
    ///   - transform: A closure that transforms the button label based on pressed state.
    ///
    /// ## Example with Custom Haptics and Delay
    /// ```swift
    /// Button("Gentle Tap") {
    ///     // Action
    /// }
/// .buttonStyle(UnionButtonStyle(
///     .impact(flexibility: .soft, intensity: 0.5),
///     delay: .milliseconds(50)
/// ) { label, isPressed in
///     label.opacity(isPressed ? 0.6 : 1.0)
/// })
    /// ```
    ///
    /// ## Example with No Haptics
    /// ```swift
    /// Button("Silent Button") {
    ///     // Action
    /// }
/// .buttonStyle(UnionButtonStyle(nil) { label, isPressed in
///     label.brightness(isPressed ? -0.3 : 0)
/// })
    /// ```
    ///
    /// ## Example with Custom Delay
    /// ```swift
    /// Button("Quick Response") {
    ///     // Action
    /// }
/// .buttonStyle(UnionButtonStyle(
///     delay: .milliseconds(25)
/// ) { label, isPressed in
///     label.scaleEffect(isPressed ? 0.95 : 1.0)
/// })
    /// ```
    ///
    /// ## Example with Custom Haptic Delay
    /// ```swift
    /// Button("Quick Response") {
    ///     // Action
    /// }
    /// .buttonStyle(UnionButtonStyle(
    ///     delay: .milliseconds(25)
    /// ) { label, isPressed in
    ///     label.scaleEffect(isPressed ? 0.95 : 1.0)
    /// })
    /// ```
    public init(
        _ haptic: SensoryFeedback? = .impact(flexibility: .rigid),
        delay: Duration = .milliseconds(100),
        scrollViewOnly: Bool = false,
        @ViewBuilder transform: @escaping Transform
    ) {
        self.haptic = haptic
        self.grace = 0.15
        self.delay = delay
        self.scrollViewOnly = scrollViewOnly
        self.transform = transform
    }

    public func makeBody(configuration: Configuration) -> some View {
        Content(
            configuration: configuration,
            haptic: haptic,
            grace: grace,
            delay: delay,
            scrollViewOnly: scrollViewOnly,
            transform: transform
        )
    }

    // MARK: Internal view
    private struct Content: View {
        let configuration: PrimitiveButtonStyleConfiguration
        let haptic: SensoryFeedback?
        let grace: TimeInterval
        let delay: Duration
        let scrollViewOnly: Bool
        let transform: Transform
        
        @Environment(\.isEnabled) private var isEnabled

        // Universal movement detection (default)
        @State private var lastGlobalFrame = CGRect.zero
        @State private var lastLocalFrame = CGRect.zero
        @State private var lastMove = Date.distantPast

        // Legacy scroll view detection (scrollViewOnly = true)
        @State private var inHoriz = false
        @State private var inVert = false
        @State private var lastPoint = CGPoint.zero

        // UI + haptic state
        @State private var flash = false
        @State private var pressed = false
        @State private var scrollCancelled = false
        @State private var setPressedTask: Task<Void, Never>?
        @State private var buttonBounds = CGRect.zero

        private struct Info: Equatable {
            var globalFrame: CGRect
            var localFrame: CGRect
            var point: CGPoint
            var inHoriz: Bool
            var inVert: Bool
        }
        private var dimmed: Bool { pressed || flash }

        var body: some View {
            transform(configuration.label, dimmed)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                buttonBounds = proxy.frame(in: .local)
                            }
                            .onChange(of: proxy.frame(in: .local)) { _, newBounds in
                                buttonBounds = newBounds
                            }
                    }
                }
                .onGeometryChange(for: Info.self) { proxy in
                    let globalFrame = proxy.frame(in: .global)
                    let localFrame = proxy.frame(in: .local)
                    let horiz = proxy.bounds(of: .scrollView(axis: .horizontal)) != nil
                    let vert = proxy.bounds(of: .scrollView(axis: .vertical)) != nil
                    let point = CGPoint(x: globalFrame.minX, y: globalFrame.minY)
                    return Info(globalFrame: globalFrame, localFrame: localFrame, point: point, inHoriz: horiz, inVert: vert)
                } action: { info in
                    // Always track scroll view presence for both modes
                    inHoriz = info.inHoriz
                    inVert = info.inVert

                    if scrollViewOnly {
                        // Legacy scroll view detection
                        if (inHoriz || inVert) && info.point != lastPoint {
                            lastPoint = info.point
                            lastMove = Date()
                            setPressedTask?.cancel()
                            setPressedTask = nil
                            pressed = false
                            flash = false
                        }
                    } else {
                        // Universal movement detection (default)
                        let globalMoved = info.globalFrame != lastGlobalFrame
                        let localMoved = info.localFrame != lastLocalFrame

                        // If global moved but local didn't (or they moved differently),
                        // it suggests the whole view is being moved by a parent
                        if globalMoved && (!localMoved ||
                            (info.globalFrame.origin.distance(to: lastGlobalFrame.origin) >
                             info.localFrame.origin.distance(to: lastLocalFrame.origin))) {
                            lastMove = Date()
                            setPressedTask?.cancel()
                            setPressedTask = nil
                            pressed = false
                            flash = false
                        }

                        lastGlobalFrame = info.globalFrame
                        lastLocalFrame = info.localFrame
                    }
                }
                .onChange(of: isEnabled) { oldValue, newValue in
                    if !newValue {
                        print("🟣 [\(Date().timeIntervalSince1970)] isEnabled changed to false - cancelling pending Task")
                        setPressedTask?.cancel()
                        setPressedTask = nil
                        pressed = false
                        flash = false
                    }
                }
                .contentShape(.rect)
                .applyDragGesture(drag: drag, simultaneousDrag: simultaneousDrag)
        }
        
        // MARK: Drag gesture (iOS 26+)
        private var drag: SimultaneousDragGesture {
            SimultaneousDragGesture()
                .onChanged { value in
                    handleDragChanged(location: value.location, translation: value.translation)
                }
                .onEnded { value in
                    handleDragEnded(location: value.location, translation: value.translation)
                }
        }
        
        // MARK: Fallback drag gesture (iOS 18)
        private var simultaneousDrag: some Gesture {
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDragChanged(location: value.location, translation: value.translation)
                }
                .onEnded { value in
                    handleDragEnded(location: value.location, translation: value.translation)
                }
        }
        
        // MARK: Shared drag handlers
        private func handleDragChanged(location: CGPoint, translation: CGSize) {
            guard isEnabled, !scrollCancelled else { return }

            // Check if we're inside button bounds
            let insideBounds = buttonBounds.contains(location)

            // Check for movement-based cancellation
            if scrollViewOnly {
                // Legacy: only cancel if in scroll view and dragging along axis
                let dx = abs(translation.width)
                let dy = abs(translation.height)
                if (inHoriz && dx > 5) || (inVert && dy > 5) {
                    cancelForScroll()
                    return
                }
            } else {
                // Universal: respect scroll directions when available, otherwise cancel on any significant drag
                let dx = abs(translation.width)
                let dy = abs(translation.height)

                let shouldCancel: Bool
                if inHoriz || inVert {
                    // We detected scroll views - only cancel drags along those axes
                    shouldCancel = (inHoriz && dx > 5) || (inVert && dy > 5)
                } else {
                    // No scroll views detected - cancel on any significant movement for sheets/popovers
                    let dragDistance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
                    shouldCancel = dragDistance > 5
                }

                if shouldCancel {
                    cancelForScroll()
                    return
                }
            }

            // Set pressed state based on bounds
            if insideBounds {
                setPressed(true)
            } else {
                // Outside bounds - cancel any pending press and un-highlight
                setPressedTask?.cancel()
                setPressedTask = nil
                pressed = false
                flash = false
            }
        }
        
        private func handleDragEnded(location: CGPoint, translation: CGSize) {
            guard !scrollCancelled else {
                resetAfterScrollCancel()
                return
            }
            
            let insideBounds = buttonBounds.contains(location)
            let still = Date().timeIntervalSince(lastMove) > grace
            let dragDistance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
            
            if scrollViewOnly {
                // Legacy behavior
                if inHoriz || inVert {
                    if dragDistance < 5 && still && insideBounds {
                        guard isEnabled else { 
                            setPressed(false)
                            return 
                        }
                        // If task is still pending, this is a quick tap - trigger immediately with haptic
                        if setPressedTask != nil {
                            pressed = true
                            setPressedTask?.cancel()
                            setPressedTask = nil
                            flash = true
                            Task { 
                                try? await Task.sleep(for: .milliseconds(150))
                                flash = false 
                            }
                            if let haptic {
                                Task.detached {
                                    await Haptics.play(haptic)
                                }
                            }
                        }
                        configuration.trigger()
                    }
                    Task { 
                        try? await Task.sleep(for: .seconds(1.0 / 60.0))
                        setPressed(false) 
                    }
                } else {
                    if pressed && insideBounds { 
                        guard isEnabled else { 
                            setPressed(false)
                            return 
                        }
                        configuration.trigger() 
                    }
                    setPressed(false)
                }
            } else {
                // Universal behavior
                // For small drags that end inside bounds and view hasn't been moving
                if dragDistance < 5 && still && insideBounds {
                    guard isEnabled else { 
                        setPressed(false)
                        return 
                    }
                    // If task is still pending, this is a quick tap - trigger immediately with haptic
                    if setPressedTask != nil {
                        pressed = true
                        setPressedTask?.cancel()
            setPressedTask = nil
                        flash = true
                        Task { 
                            try? await Task.sleep(for: .milliseconds(150))
                            flash = false 
                        }
                        if let haptic {
                            guard isEnabled else { return }
                            Task.detached {
                                await Haptics.play(haptic)
                            }
                        }
                    }
                    // If task already completed, just trigger (haptic already played)
                    configuration.trigger()
                } else if pressed && insideBounds && still {
                    guard isEnabled else { 
                        setPressed(false)
                        return 
                    }
                    configuration.trigger()
                }
                
                Task { 
                    try? await Task.sleep(for: .seconds(1.0 / 60.0))
                    setPressed(false) 
                }
            }
        }

        // MARK: Interaction lifecycle
        private func setPressed(_ pressing: Bool) {
            // Allow unpressing even when disabled to fix stuck state
            if !pressing {
                print("🟣 [\(Date().timeIntervalSince1970)] setPressed(false) called")
                setPressedTask?.cancel()
                setPressedTask = nil
                pressed = false
                return
            }
            
            print("🟣 [\(Date().timeIntervalSince1970)] setPressed(true) called - isEnabled: \(isEnabled)")
            guard isEnabled else { return }
            
            // We already know pressing == true here, so no need for "if pressing"
            guard setPressedTask == nil, !pressed else { return }

            if scrollViewOnly {
                // Legacy behavior: only delay if in scroll view
                if inHoriz || inVert {
                    setPressedTask = Task {
                        let delayTime: TimeInterval = Double(delay.components.seconds) + Double(delay.components.attoseconds) / 1e18
                        try? await Task.sleep(for: .seconds(delayTime))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            let still = Date().timeIntervalSince(lastMove) > grace
                            if !still {
                                setPressedTask = nil
                                return
                            }

                            pressed = true
                            setPressedTask = nil
                            flash = true
                            Task { 
                                try? await Task.sleep(for: .milliseconds(150))
                                flash = false 
                            }

                            if let haptic {
                                guard isEnabled else { return }
                                Task.detached {
                                    await Haptics.play(haptic)
                                }
                            }
                        }
                    }
                } else {
                    // Not in scroll view, immediate feedback
                    pressed = true
                    if let haptic {
                        guard isEnabled else { return }
                        Task.detached {
                            await Haptics.play(haptic)
                        }
                    }
                }
            } else {
                // Universal behavior: always delay to allow movement detection
                setPressedTask = Task {
                    print("🟣 [\(Date().timeIntervalSince1970)] Task created - starting delay")
                    let delayTime: TimeInterval = Double(delay.components.seconds) + Double(delay.components.attoseconds) / 1e18
                    try? await Task.sleep(for: .seconds(delayTime))
                    guard !Task.isCancelled else { 
                        print("🟣 [\(Date().timeIntervalSince1970)] Task cancelled")
                        return 
                    }
                    await MainActor.run {
                        print("🟣 [\(Date().timeIntervalSince1970)] Task fired after delay - isEnabled: \(isEnabled)")
                        
                        // Check if movement was recent
                        let still = Date().timeIntervalSince(lastMove) > grace
                        if !still {
                            print("🟣 [\(Date().timeIntervalSince1970)] Movement detected - cancelling")
                            setPressedTask = nil
                            return
                        }

                        print("🟣 [\(Date().timeIntervalSince1970)] About to set pressed=true and play haptic")
                        pressed = true
                        setPressedTask = nil
                        flash = true
                        Task { 
                            try? await Task.sleep(for: .milliseconds(150))
                            flash = false 
                        }

                        if let haptic {
                            guard isEnabled else { 
                                print("🟣 [\(Date().timeIntervalSince1970)] Haptic BLOCKED - isEnabled is false")
                                return 
                            }
                            print("🟣 [\(Date().timeIntervalSince1970)] PLAYING HAPTIC")
                            Task.detached {
                                try? await Task.sleep(for: .seconds(0.1))
                                await Haptics.play(haptic)
                            }
                        }
                    }
                }
            }
        }

        private func cancelForScroll() {
            setPressedTask?.cancel()
            setPressedTask = nil
            pressed = false
            flash = false
            scrollCancelled = true
        }

        private func resetAfterScrollCancel() {
            scrollCancelled = false
            Task {
                try? await Task.sleep(for: .seconds(1.0 / 60.0))
                pressed = false
                flash = false
            }
        }
    }
}

