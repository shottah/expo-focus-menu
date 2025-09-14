/**
 * Security validation utilities for expo-focus-menu
 */

import { FocusMenuItem } from '../ExpoFocusMenu.types';

// Security limits
const MAX_MENU_ITEMS = 50;
const MAX_EMOJI_REACTIONS = 20;
const MAX_STRING_LENGTH = 200;
const MAX_NESTING_DEPTH = 3;

/**
 * Validates and sanitizes menu items with security checks
 */
export function validateMenuItems(items: unknown): FocusMenuItem[] {
  if (!Array.isArray(items)) {
    console.warn('[ExpoFocusMenu] Invalid menu items: expected array');
    return [];
  }

  // Limit array size to prevent DoS
  const validItems = items as any[];
  if (validItems.length > MAX_MENU_ITEMS) {
    console.warn(`[ExpoFocusMenu] Too many menu items (${validItems.length}). Limiting to ${MAX_MENU_ITEMS}`);
    return validItems
      .slice(0, MAX_MENU_ITEMS)
      .map((item: any) => validateMenuItem(item, 0))
      .filter((item): item is FocusMenuItem => item !== null);
  }

  return validItems
    .map((item: any) => validateMenuItem(item, 0))
    .filter((item): item is FocusMenuItem => item !== null);
}

/**
 * Validates a single menu item
 */
function validateMenuItem(item: unknown, depth: number): FocusMenuItem | null {
  if (typeof item !== 'object' || item === null) {
    return null;
  }

  const menuItem = item as any;

  // Required fields
  if (typeof menuItem.id !== 'string' || typeof menuItem.title !== 'string') {
    console.warn('[ExpoFocusMenu] Invalid menu item: missing required id or title');
    return null;
  }

  // Sanitize strings
  const sanitized: FocusMenuItem = {
    id: sanitizeString(menuItem.id, MAX_STRING_LENGTH),
    title: sanitizeString(menuItem.title, MAX_STRING_LENGTH),
  };

  // Optional fields
  if (menuItem.subtitle !== undefined) {
    sanitized.subtitle = sanitizeString(menuItem.subtitle, MAX_STRING_LENGTH);
  }

  if (menuItem.icon !== undefined) {
    sanitized.icon = sanitizeString(menuItem.icon, 50); // Limit icon names
  }

  if (menuItem.image !== undefined) {
    // Validate image URL or base64
    const imageStr = String(menuItem.image);
    if (imageStr.startsWith('data:') || imageStr.startsWith('http')) {
      sanitized.image = imageStr.slice(0, 5000); // Limit image data size
    }
  }

  if (typeof menuItem.destructive === 'boolean') {
    sanitized.destructive = menuItem.destructive;
  }

  if (typeof menuItem.disabled === 'boolean') {
    sanitized.disabled = menuItem.disabled;
  }

  // Handle nested items with depth limit
  if (Array.isArray(menuItem.children) && depth < MAX_NESTING_DEPTH) {
    const children = menuItem.children
      .slice(0, 10) // Limit children per item
      .map((child: any) => validateMenuItem(child, depth + 1))
      .filter((child: FocusMenuItem | null): child is FocusMenuItem => child !== null);

    if (children.length > 0) {
      sanitized.children = children;
    }
  } else if (depth >= MAX_NESTING_DEPTH && Array.isArray(menuItem.children)) {
    console.warn('[ExpoFocusMenu] Maximum nesting depth reached, ignoring children');
  }

  return sanitized;
}

/**
 * Validates and sanitizes emoji reactions
 */
export function validateReactions(reactions: unknown): string[] {
  if (!Array.isArray(reactions)) {
    return [];
  }

  // Limit array size
  const validReactions = reactions as any[];
  if (validReactions.length > MAX_EMOJI_REACTIONS) {
    console.warn(`[ExpoFocusMenu] Too many reactions (${validReactions.length}). Limiting to ${MAX_EMOJI_REACTIONS}`);
    return validReactions
      .slice(0, MAX_EMOJI_REACTIONS)
      .filter((item: any) => typeof item === 'string')
      .map((emoji: string) => sanitizeEmoji(emoji))
      .filter((emoji: string) => emoji.length > 0);
  }

  return validReactions
    .filter((item: any) => typeof item === 'string')
    .map((emoji: string) => sanitizeEmoji(emoji))
    .filter((emoji: string) => emoji.length > 0);
}

/**
 * Sanitizes a string to prevent injection attacks
 */
function sanitizeString(str: unknown, maxLength: number): string {
  if (typeof str !== 'string') {
    return String(str);
  }

  // Remove control characters and limit length
  return str
    // eslint-disable-next-line no-control-regex
    .replace(/[\u0000-\u001F\u007F]/g, '') // Remove control characters
    .slice(0, maxLength)
    .trim();
}

/**
 * Sanitizes emoji strings
 */
function sanitizeEmoji(emoji: string): string {
  // Limit to reasonable emoji length (most complex emojis are ~20 chars)
  const sanitized = emoji.slice(0, 20).trim();

  // Basic check for emoji-like content (contains unicode in emoji ranges)
  // This is a simplified check - full emoji validation is complex
  const hasEmojiLike = /[\u{1F300}-\u{1FAF8}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/u.test(sanitized);

  return hasEmojiLike || sanitized.length <= 4 ? sanitized : '';
}

/**
 * Validates trigger mode
 */
export function validateTriggerMode(mode: unknown): 'longPress' | 'tap' {
  return mode === 'tap' ? 'tap' : 'longPress';
}

