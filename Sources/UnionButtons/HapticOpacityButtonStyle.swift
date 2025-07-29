//
//  HapticOpacityButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 6/25/25.
//

import SwiftUI
import UnionHaptics

/// Scroll‑aware button that fades while pressed and vibrates when the touch resolves into a tap.
/// It **auto‑detects** whether it’s inside a horizontal scroll view, a vertical scroll view, both,
/// or none — no configuration needed.
@available(iOS 17, *)
public struct HapticOpacityButtonStyle: PrimitiveButtonStyle {
    private let haptic: SensoryFeedback
    private let grace: TimeInterval
    private let delay: Duration

    // MARK: Init
    public init(
        _ haptic: SensoryFeedback? = nil,
        grace: TimeInterval = 0.15,
        delay: Duration = .milliseconds(100)
    ) {
        self.haptic = haptic ?? .impact(flexibility: .rigid)
        self.grace  = grace
        self.delay  = delay
    }

    public func makeBody(configuration: Configuration) -> some View {
        Content(configuration: configuration,
                haptic: haptic,
                grace: grace,
                delay: delay)
    }

    // MARK: Internal view
    private struct Content: View {
        let configuration: PrimitiveButtonStyleConfiguration
        let haptic: SensoryFeedback
        let grace: TimeInterval
        let delay: Duration

        // Scroll detection flags
        @State private var inHoriz = false
        @State private var inVert  = false
        @State private var lastPoint = CGPoint.zero
        @State private var lastMove  = Date.distantPast

        // UI + haptic state
        @State private var flash = false
        @State private var pressed = false
        @State private var scrollCancelled = false
        @State private var setPressedTask: Task<Void, Never>?
        @State private var buttonBounds = CGRect.zero

        private struct Info: Equatable { var p: CGPoint; var horiz: Bool; var vert: Bool }
        private var dimmed: Bool { pressed || flash }

        var body: some View {
            configuration.label
                .opacity(dimmed ? 0.5 : 1)
                .animation(.spring(duration: dimmed ? 0.1 : 0.3), value: dimmed)
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
                    let horiz = proxy.bounds(of: .scrollView(axis: .horizontal)) != nil
                    let vert  = proxy.bounds(of: .scrollView(axis: .vertical))   != nil
                    let f     = proxy.frame(in: .global)
                    return Info(p: CGPoint(x: f.minX, y: f.minY), horiz: horiz, vert: vert)
                } action: { info in
                    inHoriz = info.horiz
                    inVert  = info.vert
                    if (inHoriz || inVert) && info.p != lastPoint {
                        lastPoint = info.p
                        lastMove  = Date()
                        setPressedTask?.cancel()
                        setPressedTask = nil
                        pressed = false
                        flash = false
                        #if DEBUG
                        print("HapticOpacityButtonStyle: Scroll detected! Cancelled press task")
                        #endif
                    }
                }
                .contentShape(.rect)
                .simultaneousGesture(drag)
        }

        // MARK: Drag gesture
        private var drag: some Gesture {
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !scrollCancelled else { return }
                    
                    // Check if we're inside button bounds
                    let insideBounds = buttonBounds.contains(value.location)
                    
                    // Check for scroll cancellation
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    if (inHoriz && dx > 5) || (inVert && dy > 5) {
                        cancelForScroll()
                        return
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
                .onEnded { value in 
                    guard !scrollCancelled else { 
                        resetAfterScrollCancel()
                        return 
                    }
                    
                    let insideBounds = buttonBounds.contains(value.location)
                    
                    if inHoriz || inVert {
                        let still = Date().timeIntervalSince(lastMove) > grace
                        let timeSinceMove = Date().timeIntervalSince(lastMove)
                        #if DEBUG
                        print("HapticOpacityButtonStyle: timeSinceMove=\(timeSinceMove), grace=\(grace), still=\(still)")
                        #endif
                        if max(abs(value.translation.width), abs(value.translation.height)) < 5 && still && insideBounds {
                            // If task is still pending, this is a quick tap - trigger immediately with haptic
                            if setPressedTask != nil {
                                pressed = true
                                setPressedTask?.cancel(); setPressedTask = nil
                                flash = true
                                Task { try? await Task.sleep(for: .milliseconds(150)); flash = false }
                                Task.detached {
                                    await Haptics.play(haptic)
                                }
                            }
                            // If task already completed, just trigger (haptic already played)
                            configuration.trigger()
                        }
                        Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); setPressed(false) }
                    } else {
                        if pressed && insideBounds { configuration.trigger() }
                        setPressed(false)
                    }
                }
        }

       
        private func setPressed(_ pressing: Bool) {
            if pressing {
                guard setPressedTask == nil, !pressed else { return }
                setPressedTask = Task {
                    let delayTime: TimeInterval = (inHoriz || inVert) ? (Double(delay.components.seconds) + Double(delay.components.attoseconds) / 1e18) : 0.0
                    try? await Task.sleep(for: .seconds(delayTime))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        // Check if scroll was recent when in scroll view
                        let still = Date().timeIntervalSince(lastMove) > grace
                        if (inHoriz || inVert) && !still {
                            #if DEBUG
                            print("HapticOpacityButtonStyle: Press task completed but scroll was recent, not showing feedback")
                            #endif
                            setPressedTask = nil
                            return
                        }
                        
                        pressed = true
                        setPressedTask = nil
                        
                        // Play haptic and flash
                        if inHoriz || inVert {
                            flash = true
                            Task { try? await Task.sleep(for: .milliseconds(150)); flash = false }
                        }
                        
                        Task.detached {
                            try? await Task.sleep(for: .seconds(0.1))
                            await Haptics.play(haptic)
                        }
                    }
                }
            } else {
                setPressedTask?.cancel()
                setPressedTask = nil
                pressed = false
            }
        }
        
        private func cancelForScroll() {
            setPressedTask?.cancel(); setPressedTask = nil
            pressed = false; flash = false
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

// MARK: Sugar
extension PrimitiveButtonStyle where Self == HapticOpacityButtonStyle {
    public static var hapticOpacity: Self { .init() }
}

// MARK: - Preview

#Preview {
    Button("Tap me") {

    }
    .buttonStyle(.hapticOpacity)
}

