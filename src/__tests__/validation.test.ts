import { validateMenuItems, validateReactions } from '../utils/validation';
import { FocusMenuItem } from '../ExpoFocusMenu.types';

describe('Validation Utilities', () => {
  describe('validateMenuItems', () => {
    it('should validate basic menu items', () => {
      const items: FocusMenuItem[] = [
        { id: '1', title: 'Item 1' },
        { id: '2', title: 'Item 2' },
      ];

      const validated = validateMenuItems(items);
      expect(validated).toHaveLength(2);
      expect(validated[0].id).toBe('1');
      expect(validated[1].id).toBe('2');
    });

    it('should filter out invalid items', () => {
      const items = [
        { id: '1', title: 'Valid' },
        { title: 'Missing ID' },
        { id: '2' }, // Missing title
        null,
        undefined,
        'not an object',
      ];

      const validated = validateMenuItems(items);
      expect(validated).toHaveLength(1);
      expect(validated[0].id).toBe('1');
    });

    describe('Nesting Depth Validation', () => {
      it('should allow 1 level of nesting (parent -> child)', () => {
        const items: FocusMenuItem[] = [
          {
            id: 'parent',
            title: 'Parent',
            children: [
              { id: 'child1', title: 'Child 1' },
              { id: 'child2', title: 'Child 2' },
            ],
          },
        ];

        const validated = validateMenuItems(items);
        expect(validated).toHaveLength(1);
        expect(validated[0].children).toHaveLength(2);
        expect(validated[0].children![0].id).toBe('child1');
      });

      it('should NOT allow 2 levels of nesting (grandchildren should be ignored)', () => {
        const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

        const items: FocusMenuItem[] = [
          {
            id: 'parent',
            title: 'Parent',
            children: [
              {
                id: 'child',
                title: 'Child',
                children: [
                  { id: 'grandchild1', title: 'Grandchild 1' },
                  { id: 'grandchild2', title: 'Grandchild 2' },
                ],
              },
            ],
          },
        ];

        const validated = validateMenuItems(items);
        expect(validated).toHaveLength(1);
        expect(validated[0].children).toHaveLength(1);
        // Children should not have their own children
        expect(validated[0].children![0].children).toBeUndefined();

        // Check that warning was logged
        expect(consoleSpy).toHaveBeenCalledWith(
          expect.stringContaining('Maximum nesting depth (1 level) reached'),
        );

        consoleSpy.mockRestore();
      });

      it('should ignore any nesting beyond 1 level', () => {
        const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

        const items: FocusMenuItem[] = [
          {
            id: 'parent',
            title: 'Parent',
            children: [
              {
                id: 'child',
                title: 'Child',
                children: [
                  {
                    id: 'grandchild',
                    title: 'Grandchild', // This should be ignored
                    children: [
                      {
                        id: 'great-grandchild',
                        title: 'Great Grandchild', // This should also be ignored
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ];

        const validated = validateMenuItems(items);

        // Check structure - only parent and child should exist
        expect(validated).toHaveLength(1);
        expect(validated[0].children).toHaveLength(1);
        expect(validated[0].children![0].id).toBe('child');

        // Child should not have any children
        expect(validated[0].children![0].children).toBeUndefined();

        // Check that warning was logged
        expect(consoleSpy).toHaveBeenCalledWith(
          expect.stringContaining('Maximum nesting depth (1 level) reached'),
        );

        consoleSpy.mockRestore();
      });

      it('should handle complex nested structures with 1-level depth limit', () => {
        const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

        const items: FocusMenuItem[] = [
          {
            id: 'file',
            title: 'File',
            children: [
              {
                id: 'new',
                title: 'New',
                children: [  // These grandchildren should be ignored
                  { id: 'document', title: 'Document' },
                  { id: 'folder', title: 'Folder' },
                ],
              },
              {
                id: 'open',
                title: 'Open',
                children: [  // These grandchildren should be ignored
                  { id: 'recent', title: 'Recent Files' },
                ],
              },
              {
                id: 'save',
                title: 'Save',  // No children - this is fine
              },
            ],
          },
          {
            id: 'edit',
            title: 'Edit',
            children: [
              { id: 'undo', title: 'Undo' },
              { id: 'redo', title: 'Redo' },
            ],
          },
        ];

        const validated = validateMenuItems(items);

        // Check structure
        expect(validated).toHaveLength(2);

        // File menu should have 3 children
        expect(validated[0].children).toHaveLength(3);
        expect(validated[0].children![0].id).toBe('new');
        expect(validated[0].children![1].id).toBe('open');
        expect(validated[0].children![2].id).toBe('save');

        // None of File's children should have their own children
        expect(validated[0].children![0].children).toBeUndefined();
        expect(validated[0].children![1].children).toBeUndefined();
        expect(validated[0].children![2].children).toBeUndefined();

        // Edit menu should have 2 children
        expect(validated[1].children).toHaveLength(2);
        expect(validated[1].children![0].children).toBeUndefined();
        expect(validated[1].children![1].children).toBeUndefined();

        // Check that warnings were logged for the too-deep nesting
        expect(consoleSpy).toHaveBeenCalled();

        consoleSpy.mockRestore();
      });
    });

    it('should limit total number of menu items', () => {
      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

      // Create 60 items (more than MAX_MENU_ITEMS which is 50)
      const items = Array.from({ length: 60 }, (_, i) => ({
        id: `item${i}`,
        title: `Item ${i}`,
      }));

      const validated = validateMenuItems(items);
      expect(validated).toHaveLength(50); // Should be limited to 50
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Too many menu items'),
      );

      consoleSpy.mockRestore();
    });

    it('should sanitize string fields', () => {
      const items = [
        {
          id: 'test\u0000',  // Contains null character
          title: '  Test Item  ', // Has extra spaces
          subtitle: 'A'.repeat(300), // Very long string
        },
      ];

      const validated = validateMenuItems(items);
      expect(validated).toHaveLength(1);
      expect(validated[0].id).toBe('test'); // Null character removed
      expect(validated[0].title).toBe('Test Item'); // Trimmed
      expect(validated[0].subtitle!.length).toBeLessThanOrEqual(200); // Limited length
    });
  });

  describe('validateReactions', () => {
    it('should validate emoji reactions', () => {
      const reactions = ['😀', '❤️', '👍', '🔥'];
      const validated = validateReactions(reactions);
      expect(validated).toEqual(reactions);
    });

    it('should filter out non-string reactions', () => {
      const reactions = ['😀', 123, null, '❤️', undefined, '👍'];
      const validated = validateReactions(reactions);
      expect(validated).toEqual(['😀', '❤️', '👍']);
    });

    it('should limit number of reactions', () => {
      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

      // Create 25 reactions (more than MAX_EMOJI_REACTIONS which is 20)
      const reactions = Array.from({ length: 25 }, (_, i) => `😀${i}`);

      const validated = validateReactions(reactions);
      expect(validated.length).toBeLessThanOrEqual(20);
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Too many reactions'),
      );

      consoleSpy.mockRestore();
    });

    it('should handle empty reactions array', () => {
      const validated = validateReactions([]);
      expect(validated).toEqual([]);
    });

    it('should handle non-array input', () => {
      const validated = validateReactions('not an array' as any);
      expect(validated).toEqual([]);
    });
  });
});
