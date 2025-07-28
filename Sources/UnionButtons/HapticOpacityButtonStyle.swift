//
//  HapticOpacityButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 6/25/25.
//

import Foundation
import SwiftUI
import UnionHaptics

public struct HapticOpacityButtonStyle: ButtonStyle {
    @State private var isPressed = false

    var haptic: SensoryFeedback?

    public init(haptic: SensoryFeedback? = nil) {
        self.haptic = haptic
    }

    var unwrappedHaptic: SensoryFeedback {
        haptic ?? .impact(flexibility: .rigid)
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    withAnimation(.spring(duration: 0.1)) {
                        isPressed = true
                    }
                } else {
                    withAnimation(.spring(duration: 0.3)) {
                        isPressed = false
                    }
                }

                if pressed {
                    Task.detached(priority: .high) {
                        try await Task.sleep(for: .seconds(0.1))
                        await Haptics.play(unwrappedHaptic)
                    }
                }
            }
    }
}

extension ButtonStyle where Self == HapticOpacityButtonStyle {
    public static var hapticOpacity: Self { .init() }

    public static func hapticOpacity(_ haptic: SensoryFeedback? = nil) -> Self {
        .init(haptic: haptic)
    }
}

// MARK: - Preview

#Preview {
    Button("Tap me") {

    }
    .buttonStyle(.hapticOpacity)
}
