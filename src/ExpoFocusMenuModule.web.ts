import { FocusMenuItem, ExpoFocusMenuConfig } from './ExpoFocusMenu.types';

// Web implementation - shows a native browser context menu
const ExpoFocusMenuModule = {
  async showMenu(
    items: FocusMenuItem[],
    onItemPress: (itemId: string) => void,
    config?: ExpoFocusMenuConfig
  ): Promise<void> {
    // For web, we could implement a custom menu or use the browser's context menu API
    // This is a simplified implementation
    console.warn('ExpoFocusMenu: Web implementation is limited. Consider using a web-specific context menu library.');

    // Create a simple alert-based menu for demonstration
    const menuItems = items.map(item => `${item.id}: ${item.title}`).join('\n');
    const selected = prompt(`Select an option:\n${menuItems}\n\nEnter the ID:`);

    if (selected && items.find(item => item.id === selected)) {
      onItemPress(selected);
    }
  },

  async dismissMenu(): Promise<void> {
    // No-op on web
  },

  async isMenuVisible(): Promise<boolean> {
    return false;
  },

  async setMenuConfig(config: ExpoFocusMenuConfig): Promise<void> {
    // Store config if needed for web
  },
};

export default ExpoFocusMenuModule;
