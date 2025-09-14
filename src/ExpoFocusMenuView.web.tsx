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
  triggerMode = 'longPress',
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
        triggerMode,
        hapticFeedback,
      });

      if (onMenuDismiss) {
        onMenuDismiss();
      }
    } catch (error) {
      console.error('Failed to show menu:', error);
    }
  }, [items, onItemPress, onMenuShow, onMenuDismiss, triggerMode, hapticFeedback]);

  const handleContextMenu = React.useCallback(
    (e: React.MouseEvent) => {
      if (triggerMode === 'longPress') {
        e.preventDefault();
        showMenu();
      }
    },
    [triggerMode, showMenu],
  );

  const handleClick = React.useCallback(
    (e: React.MouseEvent) => {
      if (triggerMode === 'tap') {
        e.preventDefault();
        showMenu();
      }
    },
    [triggerMode, showMenu],
  );

  return (
    <div
      style={style as React.CSSProperties}
      onContextMenu={handleContextMenu}
      onClick={handleClick}
      data-testid={testID}
      aria-label={accessibilityLabel}
      title={accessibilityHint}
      role={accessible ? 'button' : undefined}
    >
      {children}
    </div>
  );
}
