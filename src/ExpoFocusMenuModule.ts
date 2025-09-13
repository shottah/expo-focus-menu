import { NativeModule, requireNativeModule } from 'expo';

import { ExpoFocusMenuModuleEvents } from './ExpoFocusMenu.types';

declare class ExpoFocusMenuModule extends NativeModule<ExpoFocusMenuModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoFocusMenuModule>('ExpoFocusMenu');
