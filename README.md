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

Core style with custom transform closures.

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

## Requirements

- iOS 17.0+
- macOS 14.0+
- watchOS 10.0+
- tvOS 17.0+
- Swift 5.9+

## License

MIT License. See [LICENSE](LICENSE) for details. 