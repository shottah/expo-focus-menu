import * as React from 'react';
import {
  View,
  Platform,
  ViewStyle,
  StyleProp,
} from 'react-native';
import { requireNativeViewManager } from 'expo-modules-core';

import { ExpoFocusMenuViewProps } from './ExpoFocusMenu.types';
import { validateMenuItems, validateReactions, validateTriggerMode } from './utils/validation';

// Import the native view component
const NativeView = requireNativeViewManager<ExpoFocusMenuViewProps & {
  style?: StyleProp<ViewStyle>;
}>('ExpoFocusMenu');

/**
 * A React Native component that wraps its children with a context menu
 * triggered by long press or tap.
 */
export default function ExpoFocusMenuView({
  items,
  onItemPress,
  onMenuShow,
  onMenuDismiss,
  showReactions = false,
  reactions,
  onReactionPress,
  children,
  style,
  triggerMode = 'longPress',
  showPreview = false,
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
  const validatedTriggerMode = React.useMemo(() =>
    validateTriggerMode(triggerMode), [triggerMode]);
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
    if (onReactionPress && event.nativeEvent?.emoji) {
      onReactionPress(event.nativeEvent.emoji);
    }
  }, [onReactionPress]);

  // Use native view on iOS, fallback to TouchableWithoutFeedback on other platforms
  if (Platform.OS === 'ios') {
    return (
      <NativeView
        style={style}
        items={validatedItems}
        triggerMode={validatedTriggerMode}
        showPreview={showPreview}
        hapticFeedback={hapticFeedback}
        showReactions={showReactions}
        reactions={validatedReactions}
        onItemPress={handleItemPress}
        onMenuShow={handleMenuShow}
        onMenuDismiss={handleMenuDismiss}
        onReactionPress={handleReactionPress}
        testID={testID}
        accessibilityLabel={accessibilityLabel}
        accessibilityHint={accessibilityHint || (validatedTriggerMode === 'longPress' ? 'Long press to show menu options' : 'Tap to show menu options')}
        accessible={accessible}
      >
        {children}
      </NativeView>
    );
  }

  // Fallback for Android/Web - just render children
  // TODO: Implement Android native view
  return (
    <View style={style} testID={testID}>
      {children}
    </View>
  );
}
