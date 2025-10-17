//
//  View+AllowsSwipeToDismiss.swift
//  union-buttons
//
//  Created by Ben Sage on 10/17/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry public var allowsSwipeToDismiss: Bool = false
}

extension View {
    public func allowsSwipeToDismiss(_ allows: Bool = true) -> some View {
        environment(\.allowsSwipeToDismiss, allows)
    }
}

