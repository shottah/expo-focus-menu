import * as React from 'react';

import { ExpoFocusMenuViewProps } from './ExpoFocusMenu.types';

export default function ExpoFocusMenuView(props: ExpoFocusMenuViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
