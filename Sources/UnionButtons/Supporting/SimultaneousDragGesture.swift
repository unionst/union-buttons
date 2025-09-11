//
//  SimultaneousDragGesture.swift
//  union-buttons
//
//  Created by Aaron Moss on 9/10/25.
//

import SwiftUI

struct SimultaneousDragGesture: UIGestureRecognizerRepresentable {
    public struct Value : Equatable, Sendable {
        public var time: Date
        public var location: CGPoint
        public var startLocation: CGPoint
        public var translation: CGSize {
            return CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }
        
        public static func == (a: SimultaneousDragGesture.Value, b: SimultaneousDragGesture.Value) -> Bool {
            return a.time == b.time && a.location == b.location && a.startLocation == b.startLocation
        }
    }
    
    var onBegan: (() -> Void)?
    var onChanged: ((Value) -> Void)?
    var onEnded: ((Value) -> Void)?
    
    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let dragGesture = UILongPressGestureRecognizer()
        
        dragGesture.minimumPressDuration = 0.0
        dragGesture.allowableMovement = CGFloat.infinity
        dragGesture.delegate = context.coordinator
        
        return dragGesture
    }
    
    func handleUIGestureRecognizerAction(_ gestureRecognizer: UILongPressGestureRecognizer, context: Context) {
        let location = context.converter.location(in: .local)
        let time = Date()
        
        switch gestureRecognizer.state {
        case .began:
            context.coordinator.start = location
            onBegan?()
            onChanged?(Value(time: time, location: location, startLocation: context.coordinator.start ?? location))
        case .changed:
            onChanged?(Value(time: time, location: location, startLocation: context.coordinator.start ?? location))
        case .ended, .cancelled:
            onEnded?(Value(time: time, location: location, startLocation: context.coordinator.start ?? location))
            context.coordinator.reset()
        default:
            break
        }
    }
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var start: CGPoint?
        func reset() { start = nil }
        
        // This allows the drag gesture to be simultaenous with the gestures of its containing view (i.e scroll view)
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

extension SimultaneousDragGesture {
    @MainActor @preconcurrency public func onBegan(perform action: @escaping () -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.onBegan = action
        return mutableSelf
    }
    
    @MainActor @preconcurrency public func onChanged(perform action: @escaping (SimultaneousDragGesture.Value) -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.onChanged = action
        return mutableSelf
    }
    
    @MainActor @preconcurrency func onEnded(perform action: @escaping (SimultaneousDragGesture.Value) -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.onEnded = action
        return mutableSelf
    }
}
