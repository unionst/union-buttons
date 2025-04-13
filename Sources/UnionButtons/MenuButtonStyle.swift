import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
public struct MenuButtonStyle: PrimitiveButtonStyle {
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat
    let haptics: Bool
    let animation: Animation?
    
    public init(
        horizontalPadding: CGFloat = 0,
        verticalPadding: CGFloat = 0,
        haptics: Bool = true,
        animation: Animation? = nil
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.haptics = haptics
        self.animation = animation
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        MenuButtonStyleView(configuration: configuration, style: self)
    }
}

// Global gesture state tracking
@available(iOS 17.0, macOS 14.0, *)
@MainActor private final class GlobalTouchTracker: ObservableObject {
    @MainActor static let shared = GlobalTouchTracker()
    
    // Current touch location
    @Published var touchLocation: CGPoint?
    
    // Button that should trigger when touch ends
    @Published var activeButtonId: UUID?
    
    // Whether the touch has ended (and at what location)
    @Published var touchEndedAt: CGPoint?
    
    // Flag to track if we've done direct touch handling already
    @Published var directTouchHandled = false
    
    // Duration for feedback delay
    let feedbackDelay: UInt64 = 10_000_000 // 10ms
    
    func beginTouch(at location: CGPoint) {
        touchLocation = location
        touchEndedAt = nil
        directTouchHandled = false
    }
    
    func updateTouch(to location: CGPoint) {
        touchLocation = location
        directTouchHandled = true // Mark that we're now in movement phase
    }
    
    func endTouch(at location: CGPoint) {
        // Record where the touch ended for final button activation
        touchEndedAt = location
        
        // Delay clearing state to allow all buttons to process the end event
        Task { 
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            await MainActor.run {
                self.resetTouchState()
            }
        }
    }
    
    private func resetTouchState() {
        touchLocation = nil
        touchEndedAt = nil
        activeButtonId = nil
        directTouchHandled = false
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct MenuButtonStyleView: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let style: MenuButtonStyle
    
    // Unique identifier for this button
    @State private var buttonId = UUID()
    
    // Local button state
    @State private var isPressed = false
    @State private var shouldTriggerHaptic = false
    @State private var buttonFrame = CGRect.zero
    
    // Access the global touch tracker
    @StateObject private var touchTracker = GlobalTouchTracker.shared
    
    var body: some View {
        configuration.label
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background(isPressed ? Color.secondary.opacity(0.2) : Color.clear)
            .animation(style.animation, value: isPressed)
            .contentShape(Rectangle())
            // Handle direct tap gesture
            .onTapGesture {
                // For direct taps, just trigger the action
                configuration.trigger()
            }
            // Add direct DragGesture for immediate highlighting
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        // Only handle direct touch if global system hasn't handled it yet
                        if !touchTracker.directTouchHandled {
                            // Immediately highlight on direct touch
                            isPressed = true
                            // Update global state
                            touchTracker.activeButtonId = buttonId
                        }
                    }
                    .onEnded { _ in
                        // Will be handled by global system
                    }
            )
            // Set up GeometryReader to track button bounds
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            buttonFrame = geo.frame(in: .global)
                        }
                        .onChange(of: geo.frame(in: .global)) { newFrame in
                            buttonFrame = newFrame
                        }
                }
            )
            // Handle global touch location changes
            .onChange(of: touchTracker.touchLocation) { newLocation in
                if let location = newLocation {
                    // Check if touch is inside our bounds
                    let touchInside = buttonFrame.contains(location)
                    
                    // Track previous state for haptic detection
                    let wasPressed = isPressed
                    
                    // Always update based on current touch location (key fix here)
                    isPressed = touchInside
                    
                    // If we just became the active button
                    if isPressed && !wasPressed {
                        // Mark as the active button
                        touchTracker.activeButtonId = buttonId
                        
                        // If we weren't previously active, trigger haptic
                        if !wasPressed {
                            shouldTriggerHaptic = true
                        }
                    }
                } else {
                    // No active touch - make sure we're not pressed
                    isPressed = false
                }
            }
            // Also directly track active button changes
            .onChange(of: touchTracker.activeButtonId) { activeId in
                // If another button became active, make sure we're not pressed
                if activeId != nil && activeId != buttonId {
                    isPressed = false
                }
            }
            // Handle touch end events
            .onChange(of: touchTracker.touchEndedAt) { endLocation in
                guard let endLocation = endLocation else { return }
                
                // When touch ends, check if we're the button under the touch point
                let touchEndedOnThisButton = buttonFrame.contains(endLocation)
                
                // Trigger if the touch ended on this button OR if we were the active button
                if touchEndedOnThisButton || touchTracker.activeButtonId == buttonId {
                    // We're the active button when the touch ended, trigger the action
                    configuration.trigger()
                    
                    // Reset local state
                    isPressed = false
                    shouldTriggerHaptic = false
                }
            }
            // Handle haptic feedback
            .sensoryFeedback(.selection, trigger: shouldTriggerHaptic) { oldValue, newValue in
                // Only trigger haptic if enabled and this is a positive transition
                let shouldTrigger = style.haptics && newValue && oldValue == false
                
                // Reset the haptic trigger after a short delay
                if shouldTrigger {
                    Task { 
                        try? await Task.sleep(nanoseconds: touchTracker.feedbackDelay)
                        await MainActor.run {
                            shouldTriggerHaptic = false
                        }
                    }
                }
                
                return shouldTrigger
            }
    }
}

// Global gesture handler to track touches across the entire screen
@available(iOS 17.0, macOS 14.0, *)
public struct GlobalTouchHandler: ViewModifier {
    @StateObject private var touchTracker = GlobalTouchTracker.shared
    
    public func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if touchTracker.touchLocation == nil {
                            // First detection of this touch
                            touchTracker.beginTouch(at: value.location)
                        } else {
                            // Update existing touch
                            touchTracker.updateTouch(to: value.location)
                        }
                    }
                    .onEnded { value in
                        // Signal that touch has ended (with final location)
                        touchTracker.endTouch(at: value.location)
                    }
            )
    }
}

// Convenience extension to apply the gesture handler
@available(iOS 17.0, macOS 14.0, *)
public extension View {
    func enableMenuButtonGestures() -> some View {
        self.modifier(GlobalTouchHandler())
    }
} 
