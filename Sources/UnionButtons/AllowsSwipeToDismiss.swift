import SwiftUI

extension EnvironmentValues {
    @Entry public var allowsSwipeToDismiss: Bool = false
}

extension View {
    public func allowsSwipeToDismiss(_ allowed: Bool = true) -> some View {
        environment(\.allowsSwipeToDismiss, allowed)
    }
}

