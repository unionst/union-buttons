//
//  BindingButtonStyle.swift
//  union-buttons
//
//  Created by Ben Sage on 5/2/25.
//

import SwiftUI

public struct BindingButtonStyle: ButtonStyle {
    @Binding public var isPressed: Bool

    public init(isPressed: Binding<Bool>) {
        _isPressed = isPressed
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { new in
                isPressed = new
            }
    }
}
