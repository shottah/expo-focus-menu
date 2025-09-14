// Simple test to verify types and basic structure
import { FocusMenuItem, ExpoFocusMenuConfig } from '../ExpoFocusMenu.types';

describe('ExpoFocusMenu Types', () => {
  describe('FocusMenuItem', () => {
    it('should have required fields', () => {
      const item: FocusMenuItem = {
        id: 'test',
        title: 'Test Item',
      };

      expect(item.id).toBe('test');
      expect(item.title).toBe('Test Item');
    });

    it('should support optional fields', () => {
      const item: FocusMenuItem = {
        id: 'test',
        title: 'Test Item',
        icon: 'test-icon',
        destructive: true,
        disabled: false,
        children: [],
      };

      expect(item.icon).toBe('test-icon');
      expect(item.destructive).toBe(true);
      expect(item.disabled).toBe(false);
      expect(item.children).toEqual([]);
    });

    it('should support nested items', () => {
      const item: FocusMenuItem = {
        id: 'parent',
        title: 'Parent',
        children: [
          { id: 'child1', title: 'Child 1' },
          { id: 'child2', title: 'Child 2' },
        ],
      };

      expect(item.children).toHaveLength(2);
      expect(item.children![0].id).toBe('child1');
      expect(item.children![1].id).toBe('child2');
    });
  });

  describe('ExpoFocusMenuConfig', () => {
    it('should have optional trigger mode', () => {
      const config1: ExpoFocusMenuConfig = {
        triggerMode: 'longPress',
      };

      const config2: ExpoFocusMenuConfig = {
        triggerMode: 'tap',
      };

      expect(config1.triggerMode).toBe('longPress');
      expect(config2.triggerMode).toBe('tap');
    });

    it('should support haptic feedback option', () => {
      const config: ExpoFocusMenuConfig = {
        hapticFeedback: true,
      };

      expect(config.hapticFeedback).toBe(true);
    });

    it('should allow empty config', () => {
      const config: ExpoFocusMenuConfig = {};

      expect(config).toEqual({});
    });
  });

  describe('Menu Item Validation Logic', () => {
    function validateMenuItem(item: any): boolean {
      if (!item.id || !item.title) {
        return false;
      }

      if (item.children) {
        for (const child of item.children) {
          if (!validateMenuItem(child)) {
            return false;
          }
        }
      }

      return true;
    }

    it('should validate valid items', () => {
      const validItem: FocusMenuItem = {
        id: 'test',
        title: 'Test',
      };

      expect(validateMenuItem(validItem)).toBe(true);
    });

    it('should reject items without id', () => {
      const invalidItem = {
        title: 'Test',
      };

      expect(validateMenuItem(invalidItem)).toBe(false);
    });

    it('should reject items without title', () => {
      const invalidItem = {
        id: 'test',
      };

      expect(validateMenuItem(invalidItem)).toBe(false);
    });

    it('should validate nested items recursively', () => {
      const validNested: FocusMenuItem = {
        id: 'parent',
        title: 'Parent',
        children: [
          { id: 'child1', title: 'Child 1' },
          { id: 'child2', title: 'Child 2' },
        ],
      };

      expect(validateMenuItem(validNested)).toBe(true);

      const invalidNested = {
        id: 'parent',
        title: 'Parent',
        children: [
          { id: 'child1', title: 'Child 1' },
          { title: 'Child 2' }, // missing id
        ],
      };

      expect(validateMenuItem(invalidNested)).toBe(false);
    });
  });
});

