# UnionButtons

SwiftUI button styles that solve common interaction problems.

## Why this is necessary

**Haptic timing**: Standard SwiftUI buttons only provide haptic feedback on release, not on press down when users expect it.

**Scroll interference**: Buttons in scroll views trigger when you're trying to scroll, and don't cancel properly when dragging starts.

**Moving containers**: Buttons in sheets, popovers, or any moving container don't detect when their parent is being dragged.

**Manual configuration**: Having to manually specify scroll directions and handle edge cases for each button.

## Solution

UnionButtons provides button styles that:
- Play haptics immediately on press down
- Automatically detect and cancel during scrolling or container movement  
- Work in scroll views, sheets, and any moving container without configuration
- Handle edge cases like firing during scroll deceleration

## Installation

### Swift Package Manager

Add UnionButtons to your project:

```swift
dependencies: [
    .package(url: "https://github.com/unionst/union-buttons.git", from: "1.0.0")
]
```

## Usage

```swift
import SwiftUI
import UnionButtons

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("Save Changes") {
                saveChanges()
            }
            .buttonStyle(.hapticOpacity)
            
            Button("Like Post") {
                likePost()
            }
            .buttonStyle(.bouncy(.success))
            
            Button("Silent Action") {
                performSilentAction()
            }
            .buttonStyle(.haptic(.warning))
        }
    }
}
```

## Button Styles

### HapticOpacityButtonStyle

Provides opacity-based visual feedback with haptic feedback.

```swift
Button("Sign In") { signIn() }
    .buttonStyle(.hapticOpacity)

Button("Delete Item") { deleteItem() }
    .buttonStyle(.hapticOpacity(.warning))

Button("Cancel") { cancel() }
    .buttonStyle(.hapticOpacity(nil))
```

- Fades to 50% opacity when pressed
- Automatic scroll/movement cancellation  
- Customizable haptic feedback

### BouncyButtonStyle

Scale-based feedback with bounce animation.

```swift
Button("Add to Cart") { addToCart() }
    .buttonStyle(.bouncy)

Button("Complete Order") { completeOrder() }
    .buttonStyle(.bouncy(.success))

Button("Preview") { showPreview() }
    .buttonStyle(.bouncy(nil))
```

- 1.05x scale effect when pressed
- Bounce animation
- Customizable haptic feedback

### HapticButtonStyle

Haptic feedback only with no visual changes.

```swift
Button("Invisible Press") { handlePress() }
    .buttonStyle(.haptic)

Button("Soft Touch") { handleSoftTouch() }
    .buttonStyle(.haptic(.impact(flexibility: .soft)))

Button("No Feedback") { handleSilent() }
    .buttonStyle(.haptic(nil))
```

- No visual changes
- Haptic feedback only
- Useful when visual feedback is handled elsewhere

## Advanced Usage

### UnionButtonStyle

Core style with custom transform closures and configurable delay.

```swift
Button("Custom Effect") {
    performAction()
} 
.buttonStyle(UnionButtonStyle { label, isPressed in
    label
        .rotationEffect(.degrees(isPressed ? 5 : 0))
        .scaleEffect(isPressed ? 1.1 : 1.0)
        .saturation(isPressed ? 1.5 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
})
```

#### Custom Delay

Control how quickly the button responds to touch by adjusting the delay parameter:

```swift
// Quick response for immediate feedback
Button("Quick Response") {
    performQuickAction()
}
.buttonStyle(UnionButtonStyle(
    delay: .milliseconds(25)
) { label, isPressed in
    label
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
})

// Longer delay for preventing accidental touches
Button("Careful Action") {
    performSensitiveAction()
}
.buttonStyle(UnionButtonStyle(
    .impact(flexibility: .rigid),
    delay: .milliseconds(200)
) { label, isPressed in
    label
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .brightness(isPressed ? -0.2 : 0)
})
```

#### Custom Haptic Delay

Control the timing of haptic feedback independently from visual feedback:

```swift
// Instant haptic feedback
Button("Instant Haptic") {
    performAction()
}
.buttonStyle(UnionButtonStyle(
    hapticDelay: .zero
) { label, isPressed in
    label
        .scaleEffect(isPressed ? 0.95 : 1.0)
})

// Delayed haptic for specific use cases
Button("Delayed Haptic") {
    performSensitiveAction()
}
.buttonStyle(UnionButtonStyle(
    .impact(flexibility: .soft),
    delay: .milliseconds(50),
    hapticDelay: .milliseconds(200)
) { label, isPressed in
    label
        .opacity(isPressed ? 0.7 : 1.0)
})
```

### ListButton

Component for list interfaces with persistent highlight feedback.

```swift
ListButton("Settings") {
    openSettings()
}

ListButton("Quick Action", highlightDuration: .seconds(0.5)) {
    performQuickAction()
}

ListButton {
    selectContact()
} label: {
    HStack {
        Image(systemName: "person.circle.fill")
            .foregroundStyle(.blue)
            .font(.title2)
        
        VStack(alignment: .leading) {
            Text("John Doe")
                .font(.headline)
            Text("john@example.com")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        Image(systemName: "chevron.right")
            .foregroundStyle(.tertiary)
    }
}
```

## ScrollView Integration

Works automatically in scroll views without configuration:

```swift
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            Button("Item \(item.id)") {
                selectItem(item)
            }
            .buttonStyle(.hapticOpacity)
        }
    }
}
```

## Pull-to-Dismiss Support

When using buttons in fullScreenCover presentations, the gesture recognizer can block iOS's native pull-to-dismiss feature. Use the `allowsSwipeToDismiss()` modifier to enable smart gesture handling:

```swift
.fullScreenCover(item: $selectedItem) { item in
    DetailView(item: item)
        .allowsSwipeToDismiss()
        .navigationTransition(.zoom(...))
}
```

This makes buttons detect downward swipes within the first 100ms and cancel themselves, allowing pull-to-dismiss to work while preserving full button functionality.

### When to Use

- ✅ **Use on views presented with `.fullScreenCover`** that need pull-to-dismiss
- ✅ **Use on scroll views** containing interactive buttons in dismissible contexts
- ❌ **Don't use on regular NavigationStack pushed views** (no pull-to-dismiss needed)
- ❌ **Don't use on modal sheets** (they have their own dismiss handling)

### How It Works

```swift
struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button("Action 1") { performAction1() }
                    .buttonStyle(.hapticOpacity)
                
                Button("Action 2") { performAction2() }
                    .buttonStyle(.bouncy)
            }
        }
    }
}

struct ContentView: View {
    @State private var showDetail = false
    
    var body: some View {
        Button("Show Detail") { showDetail = true }
            .fullScreenCover(isPresented: $showDetail) {
                DetailView()
                    .allowsSwipeToDismiss()
            }
    }
}
```

The gesture monitors the first 100ms of touch:
- **Downward swipe detected** (`deltaY > 20` and primarily vertical): Button cancels, pull-to-dismiss activates
- **Horizontal or upward movement**: Button continues normally
- **After 100ms**: No more cancellation checks, button fully active

## Requirements

- iOS 17.0+
- macOS 14.0+
- watchOS 10.0+
- tvOS 17.0+
- Swift 5.9+

## License

MIT License. See [LICENSE](LICENSE) for details. 