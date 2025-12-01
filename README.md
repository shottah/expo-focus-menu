# expo-focus-menu

[![npm version](https://badge.fury.io/js/expo-focus-menu.svg)](https://badge.fury.io/js/expo-focus-menu)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Test](https://github.com/shottah/expo-focus-menu/actions/workflows/test.yml/badge.svg)](https://github.com/shottah/expo-focus-menu/actions/workflows/test.yml)

Native iOS context menus with haptic feedback, custom React component icons, and interactive emoji reactions for React Native. Provides an elegant focus menu UI component for Expo and React Native apps.

## Features

- 📱 **Native iOS Context Menus** - Uses UIContextMenuInteraction for authentic iOS experience
- 🎯 **Focus Menu UI** - Long press to reveal contextual actions
- 💫 **Haptic Feedback** - Configurable haptic response on menu activation
- 🎨 **React Component Icons** - Use any React component as menu icons (SVGs, icon libraries, custom graphics)
- 😀 **Emoji Reactions** - Interactive emoji picker for quick reactions
- 📦 **Submenus** - Nested menu items for complex hierarchies
- 🔴 **Destructive Actions** - Native styling for dangerous operations
- ♿ **Accessibility** - Full VoiceOver and accessibility support

## Installation

### For Expo managed projects

```bash
npx expo install expo-focus-menu
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
import { Ionicons } from '@expo/vector-icons';
import { ExpoFocusMenuView } from 'expo-focus-menu';

function MyComponent() {
  const menuItems = [
    { id: 'share', title: 'Share', icon: <Ionicons name="share-outline" size={20} color="#333" /> },
    { id: 'copy', title: 'Copy', icon: <Ionicons name="copy-outline" size={20} color="#333" /> },
    { id: 'delete', title: 'Delete', icon: <Ionicons name="trash-outline" size={20} color="#FF3B30" />, destructive: true },
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

## Icons

Icons are passed as React components, giving you full flexibility to use any icon library or custom graphics:

```tsx
import { Ionicons, MaterialIcons, FontAwesome } from '@expo/vector-icons';
import { Image } from 'react-native';
import CustomSvgIcon from './CustomSvgIcon';

const menuItems = [
  // Using @expo/vector-icons
  { id: 'ion', title: 'Ionicons', icon: <Ionicons name="heart" size={20} color="red" /> },
  { id: 'material', title: 'Material', icon: <MaterialIcons name="star" size={20} color="gold" /> },
  { id: 'fa', title: 'FontAwesome', icon: <FontAwesome name="check" size={20} color="green" /> },

  // Using custom SVG components
  { id: 'custom', title: 'Custom Icon', icon: <CustomSvgIcon width={20} height={20} /> },

  // Using Image components
  { id: 'image', title: 'Image Icon', icon: <Image source={require('./icon.png')} style={{ width: 20, height: 20 }} /> },

  // No icon
  { id: 'noicon', title: 'No Icon' },
];
```

**Recommended icon size:** 20-24 points for optimal display in context menus.

## Advanced Usage

### With Emoji Reactions

```tsx
<ExpoFocusMenuView
  items={menuItems}
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
import { Ionicons } from '@expo/vector-icons';

const menuItems = [
  { id: 'edit', title: 'Edit', icon: <Ionicons name="pencil" size={20} color="#333" /> },
  {
    id: 'share',
    title: 'Share',
    icon: <Ionicons name="share-outline" size={20} color="#333" />,
    children: [
      { id: 'twitter', title: 'Twitter', icon: <Ionicons name="logo-twitter" size={20} color="#1DA1F2" /> },
      { id: 'facebook', title: 'Facebook', icon: <Ionicons name="logo-facebook" size={20} color="#4267B2" /> },
      { id: 'email', title: 'Email', icon: <Ionicons name="mail-outline" size={20} color="#333" /> },
    ],
  },
  { id: 'delete', title: 'Delete', icon: <Ionicons name="trash-outline" size={20} color="#FF3B30" />, destructive: true },
];
```

### Custom Configuration

```tsx
<ExpoFocusMenuView
  items={menuItems}
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
| `hapticFeedback` | `boolean` | Enable haptic feedback | `false` |
| `reactions` | `string[]` | Emoji reactions to display (none if omitted) | - |
| `onReactionPress` | `(data: {emoji: string, selected: boolean}) => void` | Reaction selection callback | - |
| `onMenuShow` | `() => void` | Menu shown callback | - |
| `onMenuDismiss` | `() => void` | Menu dismissed callback | - |

### FocusMenuItem Interface

```typescript
import { ReactNode } from 'react';

interface FocusMenuItem {
  id: string;                    // Unique identifier
  title: string;                 // Display title
  subtitle?: string;             // Optional subtitle (iOS 15+)
  icon?: ReactNode;              // React component icon (e.g., from @expo/vector-icons)
  destructive?: boolean;         // Style as destructive action
  disabled?: boolean;            // Disable this item
  children?: FocusMenuItem[];    // Nested submenu items (max 1 level deep)
}
```

## Compatibility

### Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| iOS 13+ | ✅ Fully supported | Native UIContextMenuInteraction |
| iOS 14+ | ✅ Enhanced | UIMenu with advanced features |
| iOS 15+ | ✅ Enhanced | Subtitles support |
| Android | ⚠️ Fallback | Displays children without menu |
| Web | ⚠️ Fallback | Displays children without menu |

### Version Compatibility

| expo-focus-menu | Expo SDK | React Native | iOS | Android | Node |
|-----------------|----------|--------------|-----|---------|------|
| 0.3.x | 54+ | 0.81+ | 15.0+ | API 24+ (SDK 36) | 20.0+ |
| 0.2.x | 54+ | 0.81+ | 15.0+ | API 24+ (SDK 36) | 20.0+ |
| 0.1.x | 54+ | 0.81+ | 15.0+ | API 24+ (SDK 36) | 20.0+ |

### Dependency Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| expo | * | Yes (peer) |
| react | * | Yes (peer) |
| react-native | * | Yes (peer) |
| ExpoModulesCore | Auto-linked | Yes (iOS) |

### Build Configuration

| Configuration | iOS | Android |
|---------------|-----|---------|
| Swift Version | 5.9 | - |
| Compile SDK | - | 36 |
| Min SDK | iOS 15.0, tvOS 15.0 | API 24 |
| Target SDK | - | 36 |

## Migration from v0.2.x

Version 0.3.0 introduces a breaking change to the icon API:

### Before (v0.2.x)
```tsx
// String-based SF Symbol icons
{ id: 'copy', title: 'Copy', icon: 'doc.on.doc' }
{ id: 'share', title: 'Share', image: 'https://example.com/icon.png' }
```

### After (v0.3.x)
```tsx
import { Ionicons } from '@expo/vector-icons';

// React component icons
{ id: 'copy', title: 'Copy', icon: <Ionicons name="copy-outline" size={20} color="#333" /> }
{ id: 'share', title: 'Share', icon: <Image source={{ uri: 'https://example.com/icon.png' }} style={{ width: 20, height: 20 }} /> }
```

**Key changes:**
- `icon` prop now accepts `ReactNode` instead of `string`
- `image` prop has been removed (use `<Image />` component in `icon` instead)
- SF Symbol names are no longer supported directly

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
