# Contributing to expo-focus-menu

First off, thank you for considering contributing to expo-focus-menu! It's people like you that make this library better for everyone.

## Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

1. **Use a clear and descriptive title**
2. **Describe the exact steps to reproduce the problem**
3. **Provide specific examples** to demonstrate the steps
4. **Describe the behavior you observed** and what you expected
5. **Include screenshots or videos** if possible
6. **Include your environment details:**
   - expo-focus-menu version
   - React Native version
   - Expo SDK version (if applicable)
   - iOS version
   - Device or simulator

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

1. **Use a clear and descriptive title**
2. **Provide a detailed description** of the suggested enhancement
3. **Provide specific examples** to demonstrate the enhancement
4. **Describe the current behavior** and explain the expected behavior
5. **Explain why this enhancement would be useful**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code lints
6. Issue that pull request!

## Development Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/your-username/expo-focus-menu.git
   cd expo-focus-menu
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up the example app:**
   ```bash
   cd example
   npm install
   cd ios && pod install
   cd ../..
   ```

4. **Make your changes**

5. **Run tests:**
   ```bash
   npm test
   npm run test:ios
   ```

6. **Run the example app to test your changes:**
   ```bash
   cd example
   npm run ios
   ```

## Development Workflow

### Branch Naming

- `feature/` - New features (e.g., `feature/android-support`)
- `fix/` - Bug fixes (e.g., `fix/menu-dismiss-crash`)
- `docs/` - Documentation updates (e.g., `docs/api-reference`)
- `refactor/` - Code refactoring (e.g., `refactor/menu-creation`)
- `test/` - Test additions or fixes (e.g., `test/emoji-picker`)

### Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test additions or fixes
- `chore:` - Maintenance tasks

Examples:
```
feat: add Android context menu support
fix: resolve menu dismissal crash on iOS 13
docs: update README with new API examples
test: add unit tests for emoji picker
```

### Code Style

- Use TypeScript for all new code
- Follow the existing code style (enforced by ESLint)
- Add JSDoc comments for public APIs
- Keep functions small and focused
- Write meaningful variable and function names

### Testing

- Write unit tests for new functionality
- Ensure all tests pass before submitting PR
- Aim for high test coverage
- Test on both simulator and real device if possible

#### Running Tests

```bash
# Run all tests
npm test

# Run iOS tests
npm run test:ios

# Run with coverage
npm test -- --coverage

# Run linting
npm run lint
```

### Documentation

- Update README.md if you change the API
- Add JSDoc comments to new functions/components
- Update CHANGELOG.md following Keep a Changelog format
- Include code examples for new features

## Project Structure

```
expo-focus-menu/
├── src/                    # TypeScript source files
│   ├── index.ts           # Main export
│   ├── ExpoFocusMenuView.tsx
│   └── ExpoFocusMenu.types.ts
├── ios/                    # iOS native implementation
│   ├── ExpoFocusMenuModule.swift
│   ├── ExpoFocusMenuView.swift
│   ├── EmojiPickerView.swift
│   └── Tests/             # iOS unit tests
├── android/                # Android implementation (placeholder)
├── example/                # Example app
└── __tests__/             # JavaScript tests
```

## Release Process

Releases are automated through GitHub Actions:

1. Merge PRs to `main` branch
2. Create a new release on GitHub
3. CI/CD will automatically:
   - Run tests
   - Build the package
   - Publish to npm
   - Create GitHub release

## Questions?

Feel free to open an issue with the `question` label or reach out to the maintainers.

## Recognition

Contributors will be recognized in:
- The project README
- Release notes
- GitHub contributors page

Thank you for contributing! 🎉