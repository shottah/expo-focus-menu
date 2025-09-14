import * as React from 'react';

import ExpoFocusMenuModule from './ExpoFocusMenuModule';
import { ExpoFocusMenuViewProps } from './ExpoFocusMenu.types';

/**
 * Web implementation of ExpoFocusMenuView
 * Uses the browser's context menu event
 */
export default function ExpoFocusMenuView({
  items,
  onItemPress,
  onMenuShow,
  onMenuDismiss,
  children,
  style,
  hapticFeedback,
  testID,
  accessibilityLabel,
  accessibilityHint,
  accessible,
}: ExpoFocusMenuViewProps) {
  const showMenu = React.useCallback(async () => {
    if (!items || items.length === 0) {
      return;
    }

    try {
      if (onMenuShow) {
        onMenuShow();
      }

      await ExpoFocusMenuModule.showMenu(items, onItemPress, {
        hapticFeedback,
      });

      if (onMenuDismiss) {
        onMenuDismiss();
      }
    } catch (error) {
      console.error('Failed to show menu:', error);
    }
  }, [items, onItemPress, onMenuShow, onMenuDismiss, hapticFeedback]);

  const handleContextMenu = React.useCallback(
    (e: React.MouseEvent) => {
      // Always use context menu (right-click) on web
      e.preventDefault();
      showMenu();
    },
    [showMenu],
  );

  return (
    <div
      style={style as React.CSSProperties}
      onContextMenu={handleContextMenu}
      data-testid={testID}
      aria-label={accessibilityLabel}
      title={accessibilityHint || 'Right-click to show menu options'}
      role={accessible ? 'button' : undefined}
    >
      {children}
    </div>
  );
}
