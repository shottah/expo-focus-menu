# expo-focus-menu

[![npm version](https://badge.fury.io/js/expo-focus-menu.svg)](https://badge.fury.io/js/expo-focus-menu)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Test](https://github.com/shottah/expo-focus-menu/actions/workflows/test.yml/badge.svg)](https://github.com/shottah/expo-focus-menu/actions/workflows/test.yml)

Native iOS context menus with haptic feedback, SF Symbols, and interactive emoji reactions for React Native. Provides an elegant focus menu UI component for Expo and React Native apps.

## Features

- 📱 **Native iOS Context Menus** - Uses UIContextMenuInteraction for authentic iOS experience
- 🎯 **Focus Menu UI** - Long press or tap to reveal contextual actions
- 💫 **Haptic Feedback** - Configurable haptic response on menu activation
- 🎨 **SF Symbols Support** - Use any SF Symbol as menu item icons
- 😀 **Emoji Reactions** - Interactive emoji picker for quick reactions
- 🎭 **Customizable Triggers** - Long press or tap activation modes
- 📦 **Submenus** - Nested menu items for complex hierarchies
- 🔴 **Destructive Actions** - Native styling for dangerous operations
- ♿ **Accessibility** - Full VoiceOver and accessibility support

## Installation

### For Expo managed projects

```bash
expo install expo-focus-menu
```

### For bare React Native projects

First ensure you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/).

```bash
npm install expo-focus-menu
# or
yarn add expo-focus-menu
```

### iOS Setup

Run pod install after installation:

```bash
cd ios && pod install
```

**Note:** This module currently only supports iOS. Android support displays a fallback view.

## Quick Start

```tsx
import { ExpoFocusMenuView } from 'expo-focus-menu';

function MyComponent() {
  const menuItems = [
    { id: 'share', title: 'Share', icon: 'square.and.arrow.up' },
    { id: 'copy', title: 'Copy', icon: 'doc.on.doc' },
    { id: 'delete', title: 'Delete', icon: 'trash', destructive: true }
  ];

  return (
    <ExpoFocusMenuView
      items={menuItems}
      onItemPress={(itemId) => console.log('Selected:', itemId)}
    >
      <Text>Long press me!</Text>
    </ExpoFocusMenuView>
  );
}
```

## Advanced Usage

### With Emoji Reactions

```tsx
<ExpoFocusMenuView
  items={menuItems}
  showReactions={true}
  reactions={['👍', '❤️', '😂', '🔥', '💯']}
  onReactionPress={({ emoji, selected }) => {
    console.log(`Emoji ${emoji} was ${selected ? 'selected' : 'deselected'}`);
  }}
  onItemPress={(itemId) => console.log('Menu item:', itemId)}
>
  <View style={styles.card}>
    <Text>React to this content!</Text>
  </View>
</ExpoFocusMenuView>
```

### With Submenus

```tsx
const menuItems = [
  { id: 'edit', title: 'Edit', icon: 'pencil' },
  {
    id: 'share',
    title: 'Share',
    icon: 'square.and.arrow.up',
    children: [
      { id: 'twitter', title: 'Twitter', icon: 'bird' },
      { id: 'facebook', title: 'Facebook', icon: 'f.circle' },
      { id: 'email', title: 'Email', icon: 'envelope' }
    ]
  },
  { id: 'delete', title: 'Delete', icon: 'trash', destructive: true }
];
```

### Custom Configuration

```tsx
<ExpoFocusMenuView
  items={menuItems}
  triggerMode="tap"           // 'tap' or 'longPress' (default)
  showPreview={true}           // Show content preview on menu
  hapticFeedback={true}        // Enable haptic feedback
  onItemPress={handleItemPress}
  onMenuShow={() => console.log('Menu opened')}
  onMenuDismiss={() => console.log('Menu closed')}
>
  <YourContent />
</ExpoFocusMenuView>
```

## API Reference

### ExpoFocusMenuView Props

| Prop | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `FocusMenuItem[]` | Array of menu items to display | Required |
| `onItemPress` | `(itemId: string) => void` | Callback when menu item is selected | Required |
| `children` | `ReactNode` | Content to wrap with menu | Required |
| `triggerMode` | `'longPress' \| 'tap'` | How to trigger the menu | `'longPress'` |
| `showPreview` | `boolean` | Show content preview in menu (iOS 13+) | `false` |
| `hapticFeedback` | `boolean` | Enable haptic feedback | `false` |
| `showReactions` | `boolean` | Show emoji reaction picker | `false` |
| `reactions` | `string[]` | Custom emoji reactions | Default set |
| `onReactionPress` | `(data: {emoji: string, selected: boolean}) => void` | Reaction selection callback | - |
| `onMenuShow` | `() => void` | Menu shown callback | - |
| `onMenuDismiss` | `() => void` | Menu dismissed callback | - |

### FocusMenuItem Interface

```typescript
interface FocusMenuItem {
  id: string;                    // Unique identifier
  title: string;                 // Display title
  subtitle?: string;             // Optional subtitle (iOS 15+)
  icon?: string;                 // SF Symbol name
  image?: string;                // Custom image URL or base64
  destructive?: boolean;         // Style as destructive action
  disabled?: boolean;            // Disable this item
  children?: FocusMenuItem[];    // Nested submenu items
}
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| iOS 13+ | ✅ Fully supported | Native UIContextMenuInteraction |
| iOS 14+ | ✅ Enhanced | UIMenu with advanced features |
| iOS 15+ | ✅ Enhanced | Subtitles support |
| Android | ⚠️ Fallback | Displays children without menu |
| Web | ⚠️ Fallback | Displays children without menu |

## Examples

Check the [example](./example) directory for a complete working example with various use cases.

```bash
# Run the example app
cd example
npm install
npm run ios
```

## Testing

```bash
# Run all tests
npm test

# Run iOS specific tests
npm run test:ios

# Run with coverage
npm test -- --coverage
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Roadmap

- [ ] Android support with native implementation
- [ ] Web context menu support
- [ ] Custom menu animations
- [ ] Menu item badges
- [ ] Dynamic menu updates
- [ ] Custom preview views
- [ ] Menu section headers

## License

MIT © [shottah](https://github.com/shottah)

## Acknowledgments

- Built with [Expo Modules API](https://docs.expo.dev/modules/module-api/)
- Inspired by iOS native context menu interactions
- Emoji picker design inspired by popular messaging apps

## Support

- 🐛 [Report bugs](https://github.com/shottah/expo-focus-menu/issues)
- 💡 [Request features](https://github.com/shottah/expo-focus-menu/issues)
- 📖 [Read the docs](https://github.com/shottah/expo-focus-menu#api-reference)
- ⭐ Star this repo if you find it useful!