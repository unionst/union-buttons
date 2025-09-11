//
//  View+applyDragGesture.swift
//  union-buttons
//
//  Created by Aaron Moss on 9/10/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func applyDragGesture(drag: SimultaneousDragGesture, simultaneousDrag: some Gesture) -> some View {
        if #available(iOS 18.0, *) {
            // Try to force attachment by wrapping in a container
            self
                .background(Color.clear)
                .gesture(drag)
        } else {
            self.simultaneousGesture(simultaneousDrag, including: .gesture)
        }
    }
}
