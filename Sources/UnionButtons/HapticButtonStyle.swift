import SwiftUI
import UnionHaptics

@available(iOS 17, *)
public struct HapticButtonStyle: PrimitiveButtonStyle {
    public enum Priority { case high, regular }

    let priority: Priority
    let scrollView: Axis?
    let animationDuration: CGFloat

    public init(
        priority: Priority = .regular,
        scrollView: Axis? = nil,
        animationDuration: CGFloat = 0.15
    ) {
        self.priority = priority
        self.scrollView = scrollView
        self.animationDuration = animationDuration
    }

    public func makeBody(configuration: Configuration) -> some View {
        InternalView(configuration: configuration, style: self)
    }

    private struct InternalView: View {
        let configuration: PrimitiveButtonStyleConfiguration
        let style: HapticButtonStyle

        @State private var isPressed = false
        @State private var lastTap: Date?
        @State private var scrollCancelled = false
        @State private var setPressedTask: Task<Void, Never>?

        var body: some View {
            configuration.label
                .simultaneousGesture(dragGesture, isEnabled: style.priority == .regular)
                .highPriorityGesture(dragGesture, isEnabled: style.priority == .high)
                .onChange(of: isPressed) { _, newValue in handlePressed(newValue) }
        }

        private var dragGesture: some Gesture {
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !scrollCancelled else { return }
                    if let axis = style.scrollView {
                        switch axis {
                        case .horizontal where abs(value.translation.width) > 5,
                             .vertical   where abs(value.translation.height) > 5:
                            setPressed(false)
                            scrollCancelled = true
                            return
                        default: break
                        }
                    }
                    if abs(value.translation.height) > 150 {
                        setPressed(false)
                    } else {
                        setPressed(true)
                    }
                }
                .onEnded { value in
                    guard !scrollCancelled else {
                        scrollCancelled = false
                        Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); isPressed = false }
                        return
                    }
                    if style.scrollView != nil {
                        if abs(value.translation.height) < 5 {
                            isPressed = true
                            setPressedTask?.cancel()
                            setPressedTask = nil
                            configuration.trigger()
                        }
                        Task { try? await Task.sleep(for: .seconds(1.0 / 60.0)); isPressed = false }
                    } else {
                        if isPressed { configuration.trigger() }
                        isPressed = false
                    }
                }
        }

        private func setPressed(_ pressing: Bool) {
            if pressing {
                guard setPressedTask == nil, !isPressed else { return }
                setPressedTask = Task {
                    let delay = style.scrollView == nil ? 0.0 : 0.2
                    try? await Task.sleep(for: .seconds(delay))
                    guard !Task.isCancelled else { return }
                    isPressed = true
                    setPressedTask?.cancel()
                    setPressedTask = nil
                }
            } else {
                setPressedTask?.cancel()
                setPressedTask = nil
                isPressed = false
            }
        }

        private func handlePressed(_ pressed: Bool) {
            if pressed {
                lastTap = Date()
                Task.detached(priority: .high) {
                    try await Task.sleep(for: .seconds(0.1))
                    await Haptics.rigid()
                }
            }
        }
    }
}

extension PrimitiveButtonStyle where Self == HapticButtonStyle {
    static var haptic: Self { .init() }
    static func haptic(priority: HapticButtonStyle.Priority = .regular, scrollView: Axis? = nil) -> Self {
        .init(priority: priority, scrollView: scrollView)
    }
} 