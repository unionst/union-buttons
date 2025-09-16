//
//  SimultaneousDragGesture.swift
//  union-buttons
//
//  Created by Aaron Moss on 9/10/25.
//

import SwiftUI

struct SimultaneousDragGesture: UIGestureRecognizerRepresentable {
    struct Value : Equatable, Sendable {
        var time: Date
        var location: CGPoint
        var startLocation: CGPoint

        var translation: CGSize {
            CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }
        
        static func == (a: SimultaneousDragGesture.Value, b: SimultaneousDragGesture.Value) -> Bool {
            a.time == b.time && a.location == b.location && a.startLocation == b.startLocation
        }
    }
    
    var onBegan: (() -> Void)?
    var onChanged: ((Value) -> Void)?
    var onEnded: ((Value) -> Void)?
    
    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let dragGesture = UILongPressGestureRecognizer()
        
        dragGesture.minimumPressDuration = 0.0
        dragGesture.allowableMovement = CGFloat.greatestFiniteMagnitude
        dragGesture.delegate = context.coordinator
        
        return dragGesture
    }
    
    func handleUIGestureRecognizerAction(_ gestureRecognizer: UILongPressGestureRecognizer, context: Context) {
        switch gestureRecognizer.state {
        case .began:
            context.coordinator.start = context.converter.location(in: .local)
            onBegan?()
            onChanged?(value(from: context))
        case .changed:
            onChanged?(value(from: context))
        case .ended, .cancelled:
            onEnded?(value(from: context))
            context.coordinator.reset()
        default:
            break
        }
    }

    func value(from context: Context) -> Value {
        let location = context.converter.location(in: .local)
        let start = context.coordinator.start ?? location
        let time = Date()

        return .init(time: time, location: location, startLocation: start)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        .init()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var start: CGPoint?
        func reset() { start = nil }
        
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

extension SimultaneousDragGesture {

    @MainActor @preconcurrency func onBegan(perform action: @escaping () -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.onBegan = action
        return mutableSelf
    }
    
    @MainActor @preconcurrency func onChanged(
        perform action: @escaping (SimultaneousDragGesture.Value) -> Void
    ) -> Self {
        var mutableSelf = self
        mutableSelf.onChanged = action
        return mutableSelf
    }
    
    @MainActor @preconcurrency func onEnded(
        perform action: @escaping (SimultaneousDragGesture.Value) -> Void
    ) -> Self {
        var mutableSelf = self
        mutableSelf.onEnded = action
        return mutableSelf
    }
}
