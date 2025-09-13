import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoFocusMenuViewProps } from './ExpoFocusMenu.types';

const NativeView: React.ComponentType<ExpoFocusMenuViewProps> =
  requireNativeView('ExpoFocusMenu');

export default function ExpoFocusMenuView(props: ExpoFocusMenuViewProps) {
  return <NativeView {...props} />;
}
