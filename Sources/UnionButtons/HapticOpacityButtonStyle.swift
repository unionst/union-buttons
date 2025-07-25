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
                        await Haptics.rigid()
                    }
                }
            }
    }
}

extension ButtonStyle where Self == HapticOpacityButtonStyle {
    static var hapticOpacity: Self { .init() }
}
