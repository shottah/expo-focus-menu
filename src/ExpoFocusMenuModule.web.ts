import { registerWebModule, NativeModule } from 'expo';

import { ExpoFocusMenuModuleEvents } from './ExpoFocusMenu.types';

class ExpoFocusMenuModule extends NativeModule<ExpoFocusMenuModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoFocusMenuModule, 'ExpoFocusMenuModule');
