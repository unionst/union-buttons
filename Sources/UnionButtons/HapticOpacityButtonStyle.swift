//
//  HapticOpacityButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 6/25/25.
//

import SwiftUI
import UnionHaptics

public struct HapticOpacityButtonStyle: ButtonStyle {
    private let haptic: SensoryFeedback
    private let grace: TimeInterval = 0.15

    public init(_ haptic: SensoryFeedback? = nil) {
        self.haptic = haptic ?? .impact(flexibility: .rigid)
    }

    public func makeBody(configuration: Configuration) -> some View {
        BodyView(configuration: configuration, haptic: haptic, grace: grace)
    }

    private struct BodyView: View {
        let configuration: ButtonStyle.Configuration
        let haptic: SensoryFeedback
        let grace: TimeInterval

        @State private var inScroll = false
        @State private var lastMove: Date = .distantPast
        @State private var lastPoint: CGPoint = .zero
        @State private var flash = false

        private struct TapInfo: Equatable {
            var p: CGPoint
            var inside: Bool
        }

        private var dimmed: Bool {
            configuration.isPressed || flash
        }

        var body: some View {
            configuration.label
                .opacity(dimmed ? 0.5 : 1)
                .animation(
                    .spring(duration: dimmed ? 0.1 : 0.3),
                    value: dimmed
                )
                .onGeometryChange(for: TapInfo.self) { proxy in
                    let inside = proxy.bounds(of: .scrollView) != nil
                    let g = proxy.frame(in: .global)
                    return TapInfo(p: CGPoint(x: g.minX, y: g.minY), inside: inside)
                } action: { info in
                    Task { @MainActor in
                        inScroll = info.inside
                        if info.inside && info.p != lastPoint {
                            lastPoint = info.p
                            lastMove = Date()
                        }
                    }
                }
                .contentShape(.rect)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        let still = Date().timeIntervalSince(lastMove) > grace
                        let shouldVibrate = (inScroll == false || still)

                        if inScroll && still {
                            Task { @MainActor in
                                flash = true
                                try? await Task.sleep(for: .milliseconds(150))
                                flash = false
                            }
                        }

                        if shouldVibrate {
                            Task.detached {
                                try? await Task.sleep(for: .milliseconds(60))
                                await Haptics.play(haptic)
                            }
                        }
                    }
                )
        }
    }
}

extension ButtonStyle where Self == HapticOpacityButtonStyle {
    public static var hapticOpacity: Self {
        .init()
    }

    public static func hapticOpacity(_ haptic: SensoryFeedback? = nil) -> Self {
        .init(haptic)
    }
}

// MARK: - Preview

#Preview {
    Button("Tap me") {

    }
    .buttonStyle(.hapticOpacity)
}
