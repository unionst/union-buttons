//
//  BouncyButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 5/5/25.
//

import SwiftUI

@available(iOS 17, *)
public struct BouncyButtonStyle<Transformed: View>: PrimitiveButtonStyle {
    public enum Priority { case high, regular }

    let priority: Priority
    let scrollView: Axis?
    let haptics: Bool
    let animationDuration: CGFloat
    let transform: (PrimitiveButtonStyleConfiguration.Label, Bool) -> Transformed

    public init(
        priority: Priority = .regular,
        scrollView: Axis? = nil,
        haptics: Bool = true,
        animationDuration: CGFloat = 0.15,
        @ViewBuilder transform: @escaping (PrimitiveButtonStyleConfiguration.Label, Bool) -> Transformed = { label, _ in label }
    ) {
        self.priority = priority
        self.scrollView = scrollView
        self.haptics = haptics
        self.animationDuration = animationDuration
        self.transform = transform
    }

    public func makeBody(configuration: Configuration) -> some View {
        InternalView(configuration: configuration, style: self)
    }

    private struct InternalView: View {
        let configuration: PrimitiveButtonStyleConfiguration
        let style: BouncyButtonStyle

        @State private var isPressed = false
        @State private var isExpanded = false
        @State private var lastTap: Date?
        @State private var scrollCancelled = false
        @State private var setPressedTask: Task<Void, Never>?

        private var pressed: Bool { isExpanded || isPressed }

        var body: some View {
            style.transform(configuration.label, pressed)
                .animation(.bouncy(duration: style.animationDuration), value: pressed)
                .simultaneousGesture(dragGesture, isEnabled: style.priority == .regular)
                .highPriorityGesture(dragGesture, isEnabled: style.priority == .high)
                .onChange(of: isPressed) { _, newValue in handlePressed(newValue) }
        }

        private var dragGesture: some Gesture {
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !scrollCancelled else { return }
                    if let axis = style.scrollView {
                        switch axis {
                        case .horizontal where abs(value.translation.width) > 5,
                             .vertical   where abs(value.translation.height) > 5:
                            setPressed(false)
                            scrollCancelled = true
                            return
                        default: break
                        }
                    }
                    if abs(value.translation.height) > 150 {
                        setPressed(false)
                    } else {
                        setPressed(true)
                    }
                }
                .onEnded { value in
                    guard !scrollCancelled else {
                        scrollCancelled = false
                        Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); isPressed = false }
                        return
                    }
                    if style.scrollView != nil {
                        if abs(value.translation.height) < 5 {
                            isPressed = true
                            setPressedTask?.cancel()
                            setPressedTask = nil
                            configuration.trigger()
                        }
                        Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); isPressed = false }
                    } else {
                        if isPressed { configuration.trigger() }
                        isPressed = false
                    }
                }
        }

        private func setPressed(_ pressing: Bool) {
            if pressing {
                guard setPressedTask == nil, !isPressed else { return }
                setPressedTask = Task {
                    let delay = style.scrollView == nil ? 0.0 : 0.2
                    try? await Task.sleep(for: .seconds(delay))
                    guard !Task.isCancelled else { return }
                    isPressed = true
                    setPressedTask?.cancel()
                    setPressedTask = nil
                }
            } else {
                setPressedTask?.cancel()
                setPressedTask = nil
                isPressed = false
            }
        }

        private func handlePressed(_ pressed: Bool) {
            if pressed {
                isExpanded = true
                lastTap = Date()
                if style.haptics {
                    Task.detached { try? await Task.sleep(for: .seconds(0.1)) }
                }
            } else {
                let elapsed = lastTap.map { Date().timeIntervalSince($0) } ?? 0
                let delay = max(0, Double(style.animationDuration) - elapsed)
                Task { try? await Task.sleep(for: .seconds(delay)); isExpanded = false }
            }
        }
    }
}
