import * as React from 'react';
import {
  View,
  Platform,
  ViewStyle,
  StyleProp,
  StyleSheet,
  findNodeHandle,
} from 'react-native';
import { requireNativeViewManager } from 'expo-modules-core';

import { ExpoFocusMenuViewProps, FocusMenuItem, NativeFocusMenuItem } from './ExpoFocusMenu.types';
import { validateMenuItems, validateReactions } from './utils/validation';

const ICON_SIZE = 24;

const hiddenStyles = StyleSheet.create({
  container: {
    position: 'absolute',
    left: -9999,
    top: -9999,
    opacity: 0,
    pointerEvents: 'none',
  },
  iconWrapper: {
    width: ICON_SIZE,
    height: ICON_SIZE,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
});

/** Flatten menu items including children to get all items with icons */
function getAllItemsWithIcons(items: FocusMenuItem[]): FocusMenuItem[] {
  const result: FocusMenuItem[] = [];
  for (const item of items) {
    if (item.icon && React.isValidElement(item.icon)) {
      result.push(item);
    }
    if (item.children) {
      for (const child of item.children) {
        if (child.icon && React.isValidElement(child.icon)) {
          result.push(child);
        }
      }
    }
  }
  return result;
}

/** Transform FocusMenuItem[] to NativeFocusMenuItem[] with icon view tags */
function transformToNativeItems(
  items: FocusMenuItem[],
  iconTags: Map<string, number>,
): NativeFocusMenuItem[] {
  return items.map((item) => {
    const nativeItem: NativeFocusMenuItem = {
      id: item.id,
      title: item.title,
      subtitle: item.subtitle,
      destructive: item.destructive,
      disabled: item.disabled,
    };

    // Add icon view tag if available
    if (item.icon && React.isValidElement(item.icon)) {
      const tag = iconTags.get(item.id);
      if (tag) {
        nativeItem.iconViewTag = tag;
      }
    }

    // Transform children recursively
    if (item.children) {
      nativeItem.children = transformToNativeItems(item.children, iconTags);
    }

    return nativeItem;
  });
}

// Import the native view component
const NativeView = requireNativeViewManager<ExpoFocusMenuViewProps & {
  style?: StyleProp<ViewStyle>;
}>('ExpoFocusMenu');

/**
 * A React Native component that wraps its children with a context menu
 * triggered by long press.
 */
export default function ExpoFocusMenuView({
  items,
  onItemPress,
  onMenuShow,
  onMenuDismiss,
  reactions,
  onReactionPress,
  children,
  style,
  hapticFeedback = false,
  testID,
  accessibilityLabel,
  accessibilityHint,
  accessible,
}: ExpoFocusMenuViewProps) {
  // Validate and sanitize inputs for security
  const validatedItems = React.useMemo(() => validateMenuItems(items), [items]);
  const validatedReactions = React.useMemo(() =>
    reactions ? validateReactions(reactions) : undefined, [reactions]);

  // Track icon view refs and their native tags
  const iconRefs = React.useRef<Map<string, View>>(new Map());
  const [iconTags, setIconTags] = React.useState<Map<string, number>>(new Map());

  // Extract all items with React component icons
  const itemsWithIcons = React.useMemo(
    () => getAllItemsWithIcons(validatedItems),
    [validatedItems],
  );

  // After icons mount, get their native view tags
  React.useEffect(() => {
    // Small delay to ensure views are mounted
    const timer = setTimeout(() => {
      const newTags = new Map<string, number>();
      iconRefs.current.forEach((viewRef, itemId) => {
        const tag = findNodeHandle(viewRef);
        if (tag) {
          newTags.set(itemId, tag);
        } else if (process.env.NODE_ENV !== 'production') {
          console.warn(`FocusMenu: Could not get view tag for icon "${itemId}"`);
        }
      });
      setIconTags(newTags);
    }, 50);

    return () => clearTimeout(timer);
  }, [itemsWithIcons]);

  // Transform items to native format with icon view tags
  const nativeItems = React.useMemo(
    () => transformToNativeItems(validatedItems, iconTags),
    [validatedItems, iconTags],
  );

  // Handle menu item press events from native
  const handleItemPress = React.useCallback((event: any) => {
    if (onItemPress && event.nativeEvent?.itemId) {
      onItemPress(event.nativeEvent.itemId);
    }
  }, [onItemPress]);

  // Handle menu show events from native
  const handleMenuShow = React.useCallback(() => {
    if (onMenuShow) {
      onMenuShow();
    }
  }, [onMenuShow]);

  // Handle menu dismiss events from native
  const handleMenuDismiss = React.useCallback(() => {
    if (onMenuDismiss) {
      onMenuDismiss();
    }
  }, [onMenuDismiss]);

  // Handle emoji reaction press events from native
  const handleReactionPress = React.useCallback((event: any) => {
    if (onReactionPress && event.nativeEvent) {
      onReactionPress({
        emoji: event.nativeEvent.emoji,
        selected: event.nativeEvent.selected ?? true,
      });
    }
  }, [onReactionPress]);

  // Render hidden icon container
  const renderHiddenIcons = () => {
    if (itemsWithIcons.length === 0) {
      return null;
    }

    return (
      <View style={hiddenStyles.container} collapsable={false}>
        {itemsWithIcons.map((item) => (
          <View
            key={item.id}
            ref={(ref) => {
              if (ref) {
                iconRefs.current.set(item.id, ref);
              } else {
                iconRefs.current.delete(item.id);
              }
            }}
            style={hiddenStyles.iconWrapper}
            collapsable={false}
          >
            {item.icon}
          </View>
        ))}
      </View>
    );
  };

  // Use native view on iOS and Android
  if (Platform.OS === 'ios' || Platform.OS === 'android') {
    return (
      <NativeView
        style={style}
        items={nativeItems}
        hapticFeedback={hapticFeedback}
        reactions={validatedReactions}
        onItemPress={handleItemPress}
        onMenuShow={handleMenuShow}
        onMenuDismiss={handleMenuDismiss}
        onReactionPress={handleReactionPress}
        testID={testID}
        accessibilityLabel={accessibilityLabel}
        accessibilityHint={accessibilityHint || 'Long press to show menu options'}
        accessible={accessible}
      >
        {children}
        {renderHiddenIcons()}
      </NativeView>
    );
  }

  // Fallback for Web - just render children
  return (
    <View style={style} testID={testID}>
      {children}
    </View>
  );
}
