# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of expo-focus-menu
- Native iOS context menu implementation using UIContextMenuInteraction
- Support for menu items with titles, subtitles, icons (SF Symbols), and custom images
- Haptic feedback on menu activation
- Emoji reaction picker with customizable emojis
- Support for submenus/nested menu items
- Destructive and disabled menu item states
- Configurable trigger modes (long press or tap)
- Preview support for menu content
- Full TypeScript support with type definitions
- Comprehensive test suite for iOS components
- Event callbacks for menu interactions (show, dismiss, item press, reaction press)
- Accessibility support with VoiceOver
- Example app demonstrating all features

### Platform Support
- iOS 13+ with native UIContextMenuInteraction
- iOS 14+ enhanced with UIMenu features
- iOS 15+ with subtitle support
- Android and Web fallback (displays children without menu)

## [0.1.0] - 2024-XX-XX

### Added
- Initial npm package release
- Basic documentation and usage examples
- CI/CD pipeline with GitHub Actions
- Automated testing and publishing workflows

[Unreleased]: https://github.com/shottah/expo-focus-menu/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/shottah/expo-focus-menu/releases/tag/v0.1.0