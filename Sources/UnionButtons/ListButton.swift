//
//  ListButton.swift
//  union-buttons
//
//  Created by Ben Sage on 5/28/25.
//

import SwiftUI

public struct ListButton<Label: View>: View {
    public var insets: EdgeInsets
    public var animation: Animation?
    public var outAnimation: Animation?
    public var highlightDuration: Duration
    public var action: () -> Void
    public var label: Label

    @State private var highlighted = false
    @State private var pressed = false

    public init(
        insets: EdgeInsets = .init(),
        animation: Animation? = nil,
        outAnimation: Animation? = nil,
        highlightDuration: Duration = .seconds(1),
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.insets = insets
        self.animation = animation
        self.outAnimation = outAnimation
        self.highlightDuration = highlightDuration
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button {
            action()
            highlight()
        } label: {
            label
                .padding(.top, insets.top)
                .padding(.bottom, insets.bottom)
                .padding(.leading, insets.leading)
                .padding(.trailing, insets.trailing)
                .contentShape(.rect)
                .background(
                    (highlighted || pressed)
                      ? AnyShapeStyle(Color.primary.opacity(0.15))
                      : AnyShapeStyle(.clear)
                )
        }
        .buttonStyle(BindingButtonStyle(isPressed: $pressed))
    }

    private func highlight() {
        withAnimation(animation) {
            highlighted = true
        }
        Task {
            try? await Task.sleep(for: highlightDuration)
            withAnimation(outAnimation) {
                highlighted = false
            }
        }
    }
}

extension ListButton where Label == Text {
    public init(
        _ text: String,
        animation: Animation? = nil,
        highlightDuration: Duration = .seconds(1),
        insets: EdgeInsets = .init(),
        action: @escaping () -> Void
    ) {
        self.label = Text(text)
        self.animation = animation
        self.highlightDuration = highlightDuration
        self.insets = insets
        self.action = action
    }
}

#Preview {
    ListButton("hello") {

    }
}
