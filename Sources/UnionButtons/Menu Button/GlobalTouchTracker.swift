//
//  GlobalTouchTracker.swift
//  union-buttons
//
//  Created by Ben Sage on 4/9/25.
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
@Observable @MainActor internal final class GlobalTouchTracker {
    @MainActor static let shared = GlobalTouchTracker()
    
    var touchLocation: CGPoint?
    var activeButtonId: UUID?
    var touchEndedAt: CGPoint?
    var directTouchHandled = false
    
    let feedbackDelay: UInt64 = 10_000_000 // 10ms
    
    func beginTouch(at location: CGPoint) {
        touchLocation = location
        touchEndedAt = nil
        directTouchHandled = false
    }
    
    func updateTouch(to location: CGPoint) {
        touchLocation = location
        directTouchHandled = true
    }
    
    func endTouch(at location: CGPoint) {
        touchEndedAt = location
        
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
