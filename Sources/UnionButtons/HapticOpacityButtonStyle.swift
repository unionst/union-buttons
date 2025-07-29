//
//  HapticOpacityButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 6/25/25.
//

import SwiftUI
import UnionHaptics

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

/// Movement‑aware button that fades while pressed and vibrates when the touch resolves into a tap.
/// It **auto‑detects** whether it’s inside a horizontal scroll view, a vertical scroll view, both,
/// or none — no configuration needed.
@available(iOS 17, *)
public struct HapticOpacityButtonStyle: PrimitiveButtonStyle {
    private let haptic: SensoryFeedback
    private let grace: TimeInterval
    private let delay: Duration
    private let scrollViewOnly: Bool

    // MARK: Init
    public init(
        _ haptic: SensoryFeedback? = nil,
        grace: TimeInterval = 0.15,
        delay: Duration = .milliseconds(100),
        scrollViewOnly: Bool = false
    ) {
        self.haptic = haptic ?? .impact(flexibility: .rigid)
        self.grace  = grace
        self.delay  = delay
        self.scrollViewOnly = scrollViewOnly
    }

    public func makeBody(configuration: Configuration) -> some View {
        Content(configuration: configuration,
                haptic: haptic,
                grace: grace,
                delay: delay,
                scrollViewOnly: scrollViewOnly)
    }

    // MARK: Internal view
    private struct Content: View {
        let configuration: PrimitiveButtonStyleConfiguration
        let haptic: SensoryFeedback
        let grace: TimeInterval
        let delay: Duration
        let scrollViewOnly: Bool

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
                    let globalFrame = proxy.frame(in: .global)
                    let localFrame = proxy.frame(in: .local)
                    let horiz = proxy.bounds(of: .scrollView(axis: .horizontal)) != nil
                    let vert = proxy.bounds(of: .scrollView(axis: .vertical)) != nil
                    let point = CGPoint(x: globalFrame.minX, y: globalFrame.minY)
                    return Info(globalFrame: globalFrame, localFrame: localFrame, point: point, inHoriz: horiz, inVert: vert)
                } action: { info in
                    if scrollViewOnly {
                        // Legacy scroll view detection
                        inHoriz = info.inHoriz
                        inVert = info.inVert
                        if (inHoriz || inVert) && info.point != lastPoint {
                            lastPoint = info.point
                            lastMove = Date()
                            setPressedTask?.cancel()
                            setPressedTask = nil
                            pressed = false
                            flash = false
                            #if DEBUG
                            print("HapticOpacityButtonStyle: Scroll detected! Cancelled press task")
                            #endif
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
                            #if DEBUG
                            print("HapticOpacityButtonStyle: View movement detected! Cancelled press task")
                            #endif
                        }
                        
                        lastGlobalFrame = info.globalFrame
                        lastLocalFrame = info.localFrame
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
                    
                    // Check for movement-based cancellation
                    if scrollViewOnly {
                        // Legacy: only cancel if in scroll view and dragging along axis
                        let dx = abs(value.translation.width)
                        let dy = abs(value.translation.height)
                        if (inHoriz && dx > 5) || (inVert && dy > 5) {
                            cancelForScroll()
                            return
                        }
                    } else {
                        // Universal: cancel on any significant drag
                        let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                        if dragDistance > 5 {
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
                .onEnded { value in 
                    guard !scrollCancelled else { 
                        resetAfterScrollCancel()
                        return 
                    }
                    
                    let insideBounds = buttonBounds.contains(value.location)
                    let still = Date().timeIntervalSince(lastMove) > grace
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    
                    let timeSinceMove = Date().timeIntervalSince(lastMove)
                    #if DEBUG
                    print("HapticOpacityButtonStyle: timeSinceMove=\(timeSinceMove), grace=\(grace), still=\(still)")
                    #endif
                    
                    if scrollViewOnly {
                        // Legacy behavior
                        if inHoriz || inVert {
                            if dragDistance < 5 && still && insideBounds {
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
                                configuration.trigger()
                            }
                            Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); setPressed(false) }
                        } else {
                            if pressed && insideBounds { configuration.trigger() }
                            setPressed(false)
                        }
                    } else {
                        // Universal behavior
                        // For small drags that end inside bounds and view hasn't been moving
                        if dragDistance < 5 && still && insideBounds {
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
                        
                        // For simple non-moving contexts
                        if pressed && insideBounds && still { 
                            configuration.trigger() 
                        }
                        
                        Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); setPressed(false) }
                    }
                }
        }

       
        private func setPressed(_ pressing: Bool) {
            if pressing {
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
                                    #if DEBUG
                                    print("HapticOpacityButtonStyle: Press task completed but scroll was recent, not showing feedback")
                                    #endif
                                    setPressedTask = nil
                                    return
                                }
                                
                                pressed = true
                                setPressedTask = nil
                                flash = true
                                Task { try? await Task.sleep(for: .milliseconds(150)); flash = false }
                                
                                Task.detached {
                                    try? await Task.sleep(for: .seconds(0.1))
                                    await Haptics.play(haptic)
                                }
                            }
                        }
                    } else {
                        // Not in scroll view, immediate feedback
                        pressed = true
                        Task.detached {
                            try? await Task.sleep(for: .seconds(0.1))
                            await Haptics.play(haptic)
                        }
                    }
                } else {
                    // Universal behavior: always delay to allow movement detection
                    setPressedTask = Task {
                        let delayTime: TimeInterval = Double(delay.components.seconds) + Double(delay.components.attoseconds) / 1e18
                        try? await Task.sleep(for: .seconds(delayTime))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            let still = Date().timeIntervalSince(lastMove) > grace
                            if !still {
                                #if DEBUG
                                print("HapticOpacityButtonStyle: Press task completed but movement was recent, not showing feedback")
                                #endif
                                setPressedTask = nil
                                return
                            }
                            
                            pressed = true
                            setPressedTask = nil
                            flash = true
                            Task { try? await Task.sleep(for: .milliseconds(150)); flash = false }
                            
                            Task.detached {
                                try? await Task.sleep(for: .seconds(0.1))
                                await Haptics.play(haptic)
                            }
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
    /// Universal movement detection (default) - works with scroll views, sheets, and any moving container
    public static var hapticOpacity: Self { .init() }
    
    /// Legacy scroll view only detection - only detects ScrollView specifically
    public static var hapticOpacityScrollViewOnly: Self { .init(scrollViewOnly: true) }
}

// MARK: - Preview

#Preview {
    Button("Tap me") {

    }
    .buttonStyle(.hapticOpacity)
}

