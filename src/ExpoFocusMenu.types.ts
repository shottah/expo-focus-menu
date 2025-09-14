import type { StyleProp, ViewStyle } from 'react-native';
import type { ReactNode } from 'react';

/**
 * Represents a single item in the focus menu
 */
export interface FocusMenuItem {
  /** Unique identifier for the menu item */
  id: string;

  /** Display title for the menu item */
  title: string;

  /** Optional subtitle for the menu item */
  subtitle?: string;

  /** Optional icon name (system icon on iOS, drawable resource on Android) */
  icon?: string;

  /** Optional custom image URL or base64 string for the menu item */
  image?: string;

  /** Whether this item should be styled as destructive (typically red on iOS) */
  destructive?: boolean;

  /** Whether this item should be disabled */
  disabled?: boolean;

  /**
   * Nested menu items for creating submenus.
   * Note: Only one level of nesting is supported (parent -> child).
   * Children cannot have their own children - any deeper nesting will be ignored.
   */
  children?: FocusMenuItem[];
}

/**
 * Configuration options for the focus menu behavior
 */
export interface ExpoFocusMenuConfig {
  /** Whether to provide haptic feedback when menu appears */
  hapticFeedback?: boolean;
}

/**
 * Props for the ExpoFocusMenuView component
 */
export interface ExpoFocusMenuViewProps extends ExpoFocusMenuConfig {
  /** Array of menu items to display */
  items: FocusMenuItem[];

  /** Callback when a menu item is pressed */
  onItemPress: (itemId: string) => void;

  /** Callback when the menu is shown */
  onMenuShow?: () => void;

  /** Callback when the menu is dismissed */
  onMenuDismiss?: () => void;

  /** Emoji reactions to show (no reactions if not provided) */
  reactions?: string[];

  /** Callback when an emoji reaction is selected */
  onReactionPress?: (data: { emoji: string; selected: boolean }) => void;

  /** Children to wrap with the menu */
  children: ReactNode;

  /** Style for the wrapper view */
  style?: StyleProp<ViewStyle>;

  /** Test ID for testing */
  testID?: string;

  /** Accessibility label */
  accessibilityLabel?: string;

  /** Accessibility hint */
  accessibilityHint?: string;

  /** Whether the view is accessible */
  accessible?: boolean;
}

/**
 * Native module interface
 */
export interface ExpoFocusMenuModule {
  /** Show the context menu with the given items */
  showMenu: (
    items: FocusMenuItem[],
    onItemPress: (itemId: string) => void,
    config?: ExpoFocusMenuConfig
  ) => Promise<void>;

  /** Dismiss the currently visible menu */
  dismissMenu: () => Promise<void>;

  /** Check if a menu is currently visible */
  isMenuVisible: () => Promise<boolean>;

  /** Set default configuration for all menus */
  setMenuConfig: (config: ExpoFocusMenuConfig) => Promise<void>;
}

/**
 * Events emitted by the native module
 */
export interface ExpoFocusMenuModuleEvents {
  /** Fired when a menu item is selected */
  onMenuItemSelected: (event: { itemId: string }) => void;

  /** Fired when the menu is shown */
  onMenuShown: (event: {}) => void;

  /** Fired when the menu is dismissed */
  onMenuDismissed: (event: {}) => void;

  // Index signature for EventsMap compatibility
  [key: string]: (event: any) => void;
}
