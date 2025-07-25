//
//  NickButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 6/4/25.
//

import Foundation
import SwiftUI
import UnionHaptics

@available(iOS 17, *)
public struct NickButtonStyle: PrimitiveButtonStyle {
    public enum Priority { case high, regular }

    var haptics: Bool
    var priority: Priority
    var scrollView: Axis?

    fileprivate let animationDuration: CGFloat = 0.15
    var animation: Animation { .smooth(duration: animationDuration) }

    public init(
        haptics: Bool = true,
        priority: Priority = .regular,
        scrollView: Axis? = nil,
    ) {
        self.haptics = haptics
        self.priority = priority
        self.scrollView = scrollView
    }

    public func makeBody(configuration: Configuration) -> some View {
        NickButtonStyleView(configuration: configuration, style: self)
    }
}

@available(iOS 17, *)
private struct NickButtonStyleView: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let style: NickButtonStyle

    @State private var isPressed = false
    @State private var isExpanded = false
    @State private var lastTap: Date? = nil
    @State private var scrollCancelled = false
    @State private var setIsPressedTask: Task<Void, Never>? = nil

    private var pressed: Bool { isExpanded || isPressed }

    var body: some View {
        configuration.label
            .scaleEffect(pressed ? 1.05 : 1)
            .animation(style.animation, value: pressed)
            .simultaneousGesture(dragGesture, isEnabled: style.priority == .regular)
            .highPriorityGesture(dragGesture, isEnabled: style.priority == .high)
            .onChange(of: isPressed) { _, new in
                handlePressed(new)
            }
    }

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
                    Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); isPressed = false }
                    return
                }

                if style.scrollView != nil {
                    if abs(value.translation.height) < 5 {
                        isPressed = true
                        setIsPressedTask?.cancel()
                        setIsPressedTask = nil
                        configuration.trigger()
                    }
                    Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); isPressed = false }
                } else {
                    if isPressed { configuration.trigger() }
                    isPressed = false
                }
            }
    }

    private func setIsPressed(_ pressing: Bool) {
        if pressing {
            guard setIsPressedTask == nil, !isPressed else { return }
            setIsPressedTask = Task {
                let delay = style.scrollView != nil ? 0.2 : 0.0
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                isPressed = true
                setIsPressedTask?.cancel()
                setIsPressedTask = nil
            }
        } else {
            setIsPressedTask?.cancel()
            setIsPressedTask = nil
            isPressed = false
        }
    }

    private func handlePressed(_ pressed: Bool) {
        if pressed {
            isExpanded = true
            lastTap = Date()
            if style.haptics {
                Task.detached(priority: .high) {
                    try? await Task.sleep(for: .seconds(0.1))
                    await Haptics.heavy()
                }
            }
        } else {
            let delta = Date().timeIntervalSince(lastTap ?? Date())
            let delay = max(0, Double(style.animationDuration) - delta)
            Task { try? await Task.sleep(for: .seconds(delay)); isExpanded = false }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Button("Tap Me") { }
            .buttonStyle(NickButtonStyle())

        ScrollView(.horizontal) {
            HStack {
                ForEach(0..<10) { i in
                    Button("Item \(i)") { }
                        .buttonStyle(NickButtonStyle(scrollView: .horizontal))
                }
            }
            .padding()
        }
    }
    .padding()
}







