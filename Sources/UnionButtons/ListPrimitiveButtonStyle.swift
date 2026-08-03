//
//  ListButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 4/9/25.
//

import SwiftUI

public struct ListPrimitiveButtonStyle: PrimitiveButtonStyle {

    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat

    // MARK: - Scroll Handling

    /// If provided, indicates this button is in a scroll view that scrolls along the given axis.
    /// The button press will cancel if the user moves too far along that scroll axis.
    var scrollView: Axis?
    var inScrollView: Bool {
        scrollView != nil
    }

    // MARK: - Properties

    let haptics: Bool
    let animationDuration: Double
    let animation: Animation?

    // MARK: - Initializer

    public init(
        horizontalPadding: CGFloat = 0,
        verticalPadding: CGFloat = 0,
        haptics: Bool = false,
        scrollView: Axis? = .vertical,
        animationDuration: Double = 0.12,
        animation: Animation? = nil
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.haptics = haptics
        self.scrollView = scrollView
        self.animationDuration = animationDuration
        self.animation = animation
    }

    // MARK: - PrimitiveButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        ListButtonStyleView(configuration: configuration, style: self)
    }
}

// MARK: - Private Nested View

/// The internal view that holds state and renders the button style.
private struct ListButtonStyleView: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let style: ListPrimitiveButtonStyle

    @State private var isPressed: Bool = false
    @State private var isExpanded: Bool = false
    @State private var lastTap: Date? = nil
    @State private var longPressActive: Bool = false

    // Scroll-state tracking
    @State private var scrollCancelled: Bool = false
    @State private var setIsPressedTask: Task<Void, Never>? = nil

    /// Computes whether the button should appear pressed.
    private var pressed: Bool {
        isExpanded || isPressed
    }

    // MARK: - Body

    var body: some View {
        configuration.label
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .animation(nil, value: pressed)
            .background(pressed ? AnyShapeStyle(.secondary.opacity(0.2)) : AnyShapeStyle(.clear))
            // Under the finger at once, faded on release: a highlight that
            // animates in lags the touch, and one that cuts out reads as a
            // flicker rather than a row letting go.
            .animation(pressed ? nil : (style.animation ?? .default), value: pressed)
            .contentShape(.rect)
            .simultaneousGesture(longPressResetGesture)
            .simultaneousGesture(dragGesture)
            .onChange(of: isPressed) { _ in
                handlePressed(isPressed)
            }
    }

    // MARK: - Gestures

    /// A gesture to detect long presses and reset state if interrupted (e.g., by context menu).
    private var longPressResetGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.45)
            .onEnded { _ in
                longPressActive = true
                setIsPressedTask?.cancel()
                setIsPressedTask = nil
                isPressed = false
                isExpanded = false
                scrollCancelled = false
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    isPressed = false
                    isExpanded = false
                    longPressActive = false
                }
            }
    }

    /// The drag gesture that tracks press state, including scroll-cancellation logic.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !scrollCancelled else { return }

                if let axis = style.scrollView {
                    switch axis {
                    case .horizontal:
                        if abs(value.translation.width) > 5 {
                            setIsPressed(false)
                            scrollCancelled = true
                            return
                        }
                    case .vertical:
                        if abs(value.translation.height) > 5 {
                            setIsPressed(false)
                            scrollCancelled = true
                            return
                        }
                    }
                }

                if abs(value.translation.height) > 150 {
                    setIsPressed(false)
                } else {
                    setIsPressed(true)
                }
            }
            .onEnded { value in
                guard !scrollCancelled else {
                    scrollCancelled = false
                    Task {
                        try? await Task.sleep(nanoseconds: 16_667)
                        isPressed = false
                    }
                    return
                }

                if style.inScrollView {
                    if abs(value.translation.height) < 5 && !longPressActive {
                        isPressed = true
                        setIsPressedTask?.cancel()
                        setIsPressedTask = nil
                        configuration.trigger()
                    }

                    Task {
                        try? await Task.sleep(nanoseconds: 16_667)
                        isPressed = false
                        longPressActive = false
                    }
                } else {
                    if isPressed && !longPressActive {
                        configuration.trigger()
                    }
                    isPressed = false
                    longPressActive = false
                }
            }
    }

    // MARK: - Internal Press Handling

    /// Schedules or cancels setting `isPressed` with a delay (if in a scrollView).
    private func setIsPressed(_ pressing: Bool) {
        if pressing {
            // Only set isPressed if we're not already pressed or scheduled
            guard setIsPressedTask == nil, !isPressed else { return }
            setIsPressedTask = Task {
                // If we're in a scrollView, impose a small delay
                let delay = style.inScrollView ? 0.2 : 0.0
                try? await Task.sleep(nanoseconds: UInt64(Double(1_000_000_000) * delay))
                guard !Task.isCancelled else { return }
                isPressed = true
                setIsPressedTask?.cancel()
                setIsPressedTask = nil
            }
        } else {
            // Cancel any pending press tasks and reset state
            setIsPressedTask?.cancel()
            setIsPressedTask = nil
            isPressed = false
        }
    }

    /// Handles press state changes, triggering haptics and delaying the release animation.
    private func handlePressed(_ pressed: Bool) {
        if pressed {
            isExpanded = true
            lastTap = Date()
            if style.haptics {
                Task.detached(priority: .high) {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            }
        } else {
            let timeSinceLastTap = lastTap.map { Date().timeIntervalSince($0) } ?? 0
            let delay = max(0, Double(style.animationDuration) - timeSinceLastTap)
            Task {
                try? await Task.sleep(nanoseconds: UInt64(Double(1_000_000_000) * delay))
                isExpanded = false
            }
        }
    }
}
