//
//  GlobalTouchHandler.swift
//  union-buttons
//
//  Created by Ben Sage on 4/9/25.
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
internal struct MenuButtonStyleView: View {
    let configuration: PrimitiveButtonStyleConfiguration
    let style: MenuButtonStyle
    
    @State private var buttonId = UUID()
    @State private var isPressed = false
    @State private var shouldTriggerHaptic = false
    @State private var buttonFrame = CGRect.zero
    @State private var touchTracker = GlobalTouchTracker.shared
    
    var body: some View {
        configuration.label
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background(isPressed ? Color.secondary.opacity(0.2) : Color.clear)
            .animation(style.animation, value: isPressed)
            .contentShape(Rectangle())
            .onTapGesture {
                configuration.trigger()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !touchTracker.directTouchHandled {
                            isPressed = true
                            touchTracker.activeButtonId = buttonId
                        }
                    }
                    .onEnded { _ in }
            )
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
            .onChange(of: touchTracker.touchLocation) { newLocation in
                if let location = newLocation {
                    let touchInside = buttonFrame.contains(location)
                    let wasPressed = isPressed
                    isPressed = touchInside
                    
                    if isPressed && !wasPressed {
                        touchTracker.activeButtonId = buttonId
                        if !wasPressed {
                            shouldTriggerHaptic = true
                        }
                    }
                } else {
                    isPressed = false
                }
            }
            .onChange(of: touchTracker.activeButtonId) { activeId in
                if activeId != nil && activeId != buttonId {
                    isPressed = false
                }
            }
            .onChange(of: touchTracker.touchEndedAt) { endLocation in
                guard let endLocation = endLocation else { return }
                
                let touchEndedOnThisButton = buttonFrame.contains(endLocation)
                
                if touchEndedOnThisButton || touchTracker.activeButtonId == buttonId {
                    configuration.trigger()
                    isPressed = false
                    shouldTriggerHaptic = false
                }
            }
            .sensoryFeedback(.selection, trigger: shouldTriggerHaptic) { oldValue, newValue in
                let shouldTrigger = style.haptics && newValue && oldValue == false
                
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
