import { NativeModule as ExpoNativeModule, requireNativeModule } from 'expo';
import { Platform } from 'react-native';

import {
  ExpoFocusMenuModuleEvents,
  FocusMenuItem,
  ExpoFocusMenuConfig,
} from './ExpoFocusMenu.types';

declare class NativeExpoFocusMenuModule extends ExpoNativeModule<ExpoFocusMenuModuleEvents> {
  showNativeMenu(items: FocusMenuItem[], config?: ExpoFocusMenuConfig): Promise<string | null>;
  dismissNativeMenu(): Promise<void>;
  isNativeMenuVisible(): Promise<boolean>;
  setNativeMenuConfig(config: ExpoFocusMenuConfig): Promise<void>;
}

// This call loads the native module object from the JSI.
const NativeModule = requireNativeModule<NativeExpoFocusMenuModule>('ExpoFocusMenu');

// Store callbacks for menu items
const menuCallbacks = new Map<string, (itemId: string) => void>();

/**
 * Validates menu items before showing the menu
 */
function validateMenuItems(items: FocusMenuItem[]): void {
  if (!items || items.length === 0) {
    throw new Error('Menu items cannot be empty');
  }

  items.forEach((item) => {
    if (!item.id || !item.title) {
      throw new Error('Menu item must have id and title');
    }

    // Recursively validate children
    if (item.children && item.children.length > 0) {
      validateMenuItems(item.children);
    }
  });
}

/**
 * Filters out iOS-only configuration for Android
 */
function filterConfigForPlatform(config?: ExpoFocusMenuConfig): ExpoFocusMenuConfig | undefined {
  if (!config) {
    return undefined;
  }

  return config;
}

const ExpoFocusMenuModule = {
  /**
   * Shows a context menu with the specified items
   */
  async showMenu(
    items: FocusMenuItem[],
    onItemPress: (itemId: string) => void,
    config?: ExpoFocusMenuConfig,
  ): Promise<void> {
    // Validate items
    validateMenuItems(items);

    // Store the callback
    const callbackId = `menu_${Date.now()}`;
    menuCallbacks.set(callbackId, onItemPress);

    try {
      // Filter config based on platform
      const platformConfig = filterConfigForPlatform(config);

      // Show the native menu and wait for selection
      const selectedItemId = await NativeModule.showNativeMenu(items, {
        ...platformConfig,
        callbackId,
      } as any);

      // If an item was selected, call the callback
      if (selectedItemId && onItemPress) {
        onItemPress(selectedItemId);
      }
    } finally {
      // Clean up the callback
      menuCallbacks.delete(callbackId);
    }
  },

  /**
   * Dismisses the currently visible menu
   */
  async dismissMenu(): Promise<void> {
    return NativeModule.dismissNativeMenu();
  },

  /**
   * Checks if a menu is currently visible
   */
  async isMenuVisible(): Promise<boolean> {
    return NativeModule.isNativeMenuVisible();
  },

  /**
   * Sets default configuration for all menus
   */
  async setMenuConfig(config: ExpoFocusMenuConfig): Promise<void> {
    const platformConfig = filterConfigForPlatform(config);
    return NativeModule.setNativeMenuConfig(platformConfig || {});
  },
};

export default ExpoFocusMenuModule;
