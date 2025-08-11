//
//  ListButton.swift
//  union-buttons
//
//  Created by Ben Sage on 5/28/25.
//

import SwiftUI

/// A button component designed for list interfaces with persistent highlight feedback.
///
/// `ListButton` provides both immediate pressed feedback and a persistent highlight effect 
/// that remains visible for a specified duration after tapping. Built on top of `UnionButtonStyle`,
/// it includes smart scroll detection and movement cancellation.
///
/// ## Features
/// - **Immediate Press Feedback**: Visual feedback while the button is being pressed
/// - **Persistent Highlight**: Highlight effect that persists after tapping for visual confirmation
/// - **Smart Movement Detection**: Automatically cancels during scrolling or container movement
/// - **Customizable Animations**: Control both highlight-in and highlight-out animations
/// - **Flexible Layout**: Configurable padding and content layout
/// - **Accessibility**: Full content shape for better touch targets
///
/// ## Basic Usage
/// ```swift
/// ListButton("Settings") {
///     openSettings()
/// }
/// ```
///
/// ## Custom Highlight Duration
/// ```swift
/// ListButton("Quick Action", highlightDuration: .seconds(0.5)) {
///     performQuickAction()
/// }
/// ```
///
/// ## Custom Animations
/// ```swift
/// ListButton(
///     "Smooth Action",
///     animation: .easeInOut(duration: 0.2),
///     outAnimation: .easeOut(duration: 0.5)
/// ) {
///     performAction()
/// }
/// ```
///
/// ## Complex Content
/// ```swift
/// ListButton {
///     performComplexAction()
/// } label: {
///     HStack {
///         Image(systemName: "star.fill")
///         VStack(alignment: .leading) {
///             Text("Primary Action")
///                 .font(.headline)
///             Text("Secondary description")
///                 .font(.caption)
///                 .foregroundStyle(.secondary)
///         }
///         Spacer()
///     }
/// }
/// ```
///
/// ## In ScrollViews and Lists
/// ```swift
/// List {
///     ListButton("Profile Settings") {
///         openProfile()
///     }
///     
///     ListButton("Notifications") {
///         openNotifications()
///     }
///     
///     ListButton("Privacy") {
///         openPrivacy()
///     }
/// }
/// ```
///
/// Works automatically in scroll views with smart cancellation:
/// ```swift
/// ScrollView {
///     LazyVStack {
///         ForEach(0..<20) { i in
///             ListButton("Item \(i)") {
///                 selectItem(i)
///             }
///         }
///     }
/// }
/// ```
public struct ListButton<Label: View>: View {
    /// The padding applied to the button content.
    public var insets: EdgeInsets
    
    /// The animation used when the highlight effect appears.
    public var animation: Animation?
    
    /// The animation used when the highlight effect disappears.
    public var outAnimation: Animation?
    
    /// How long the highlight effect persists after tapping.
    public var highlightDuration: Duration
    
    /// The action to perform when the button is tapped.
    public var action: () -> Void
    
    /// The label content of the button.
    public var label: Label

    @State private var highlighted = false

    /// Creates a list button with customizable highlight behavior.
    ///
    /// - Parameters:
    ///   - insets: The padding applied to the button content. Defaults to no padding.
    ///   - animation: The animation for the highlight effect appearing. Defaults to no animation.
    ///   - outAnimation: The animation for the highlight effect disappearing. Defaults to no animation.
    ///   - highlightDuration: How long the highlight persists after tapping. Defaults to 1 second.
    ///   - action: The action to perform when tapped.
    ///   - label: A view builder that creates the button content.
    ///
    /// ## Example with Custom Animations
    /// ```swift
    /// ListButton(
    ///     insets: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
    ///     animation: .easeIn(duration: 0.15),
    ///     outAnimation: .easeOut(duration: 0.4),
    ///     highlightDuration: .seconds(0.6)
    /// ) {
    ///     handleAction()
    /// } label: {
    ///     HStack {
    ///         Image(systemName: "heart.fill")
    ///         Text("Like Post")
    ///     }
    /// }
    /// ```
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
        }
        .buttonStyle(UnionButtonStyle(nil) { label, isPressed in
            label
                .padding(.top, insets.top)
                .padding(.bottom, insets.bottom)
                .padding(.leading, insets.leading)
                .padding(.trailing, insets.trailing)
                .contentShape(.rect)
                .background(
                    (highlighted || isPressed)
                      ? AnyShapeStyle(Color.primary.opacity(0.15))
                      : AnyShapeStyle(.clear)
                )
        })
        .onDisappear {
            highlighted = false
        }
        .gesture(DragGesture(), including: .gesture)
    }

    private func highlight() {
        if let animation {
            withAnimation(animation) {
                highlighted = true
            }
        } else {
            highlighted = true
        }
        Task {
            try? await Task.sleep(for: highlightDuration)
            if let outAnimation {
                withAnimation(outAnimation) {
                    highlighted = false
                }
            } else {
                highlighted = false
            }
        }
    }
}

// MARK: Text Convenience

extension ListButton where Label == Text {
    /// Creates a list button with text content.
    ///
    /// Convenience initializer for simple text-based list buttons with customizable
    /// highlight behavior.
    ///
    /// - Parameters:
    ///   - text: The text to display in the button.
    ///   - animation: The animation for the highlight effect appearing. Defaults to no animation.
    ///   - highlightDuration: How long the highlight persists after tapping. Defaults to 1 second.
    ///   - insets: The padding applied to the button content. Defaults to no padding.
    ///   - action: The action to perform when tapped.
    ///
    /// ## Basic Usage
    /// ```swift
    /// ListButton("Settings") {
    ///     openSettingsScreen()
    /// }
    /// ```
    ///
    /// ## With Custom Timing
    /// ```swift
    /// ListButton(
    ///     "Quick Action",
    ///     animation: .spring(duration: 0.3),
    ///     highlightDuration: .seconds(0.5)
    /// ) {
    ///     performQuickAction()
    /// }
    /// ```
    ///
    /// ## With Padding
    /// ```swift
    /// ListButton(
    ///     "Padded Button",
    ///     insets: EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    /// ) {
    ///     handleAction()
    /// }
    /// ```
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

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("ListButton Examples")
            .font(.title2)
            .padding()
        
        VStack(spacing: 1) {
            ListButton("Simple List Item") {
                print("Tapped simple item")
            }
            
            ListButton(
                "Custom Highlight Duration",
                highlightDuration: .seconds(0.5)
            ) {
                print("Tapped quick highlight")
            }
            
            ListButton(
                "Animated Highlight",
                animation: .spring(duration: 0.2)
            ) {
                print("Tapped animated")
            }
        }
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
        ListButton(
            insets: EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        ) {
            print("Tapped complex content")
        } label: {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading) {
                    Text("Complex Content")
                        .font(.headline)
                    Text("With subtitle and icon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .background(.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        
        Spacer()
    }
    .padding()
}
