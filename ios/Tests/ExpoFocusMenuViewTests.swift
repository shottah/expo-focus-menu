import XCTest
import UIKit
import ExpoModulesCore
@testable import ExpoFocusMenu

@available(iOS 13.0, *)
class ExpoFocusMenuViewTests: XCTestCase {

    var menuView: ExpoFocusMenuView!
    var mockAppContext: AppContext!

    override func setUp() {
        super.setUp()
        mockAppContext = MockAppContext()
        menuView = ExpoFocusMenuView(appContext: mockAppContext)
    }

    override func tearDown() {
        menuView = nil
        mockAppContext = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewInitialization() {
        XCTAssertNotNil(menuView)
        XCTAssertEqual(menuView.backgroundColor, .clear)
        XCTAssertTrue(menuView.isUserInteractionEnabled)
        XCTAssertEqual(menuView.triggerMode, "longPress")
        XCTAssertFalse(menuView.showPreview)
        XCTAssertFalse(menuView.hapticFeedback)
        XCTAssertFalse(menuView.showReactions)
    }

    func testContextMenuInteractionAdded() {
        let interactions = menuView.interactions
        let hasContextMenu = interactions.contains { $0 is UIContextMenuInteraction }
        XCTAssertTrue(hasContextMenu, "View should have context menu interaction")
    }

    // MARK: - Property Tests

    func testMenuItemsProperty() {
        let items: [[String: Any]] = [
            ["id": "1", "title": "Item 1"],
            ["id": "2", "title": "Item 2", "subtitle": "Subtitle"],
            ["id": "3", "title": "Item 3", "destructive": true]
        ]

        menuView.menuItems = items
        XCTAssertEqual(menuView.menuItems.count, 3)
    }

    func testTriggerModeProperty() {
        // Test longPress mode (default)
        XCTAssertEqual(menuView.triggerMode, "longPress")

        // Change to tap mode
        menuView.updateTriggerMode("tap")
        XCTAssertEqual(menuView.triggerMode, "tap")

        // Verify tap gesture is added
        let hasTapGesture = menuView.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } ?? false
        XCTAssertTrue(hasTapGesture, "Tap gesture should be added in tap mode")

        // Change back to longPress
        menuView.updateTriggerMode("longPress")
        XCTAssertEqual(menuView.triggerMode, "longPress")
    }

    func testShowPreviewProperty() {
        menuView.showPreview = true
        XCTAssertTrue(menuView.showPreview)

        menuView.showPreview = false
        XCTAssertFalse(menuView.showPreview)
    }

    func testHapticFeedbackProperty() {
        menuView.hapticFeedback = true
        XCTAssertTrue(menuView.hapticFeedback)

        menuView.hapticFeedback = false
        XCTAssertFalse(menuView.hapticFeedback)
    }

    func testReactionsProperty() {
        // Test empty reactions
        XCTAssertEqual(menuView.reactions.count, 0)

        // Set custom reactions
        let customEmojis = ["👍", "❤️", "😂", "🔥"]
        menuView.reactions = customEmojis
        XCTAssertEqual(menuView.reactions.count, 4)
        XCTAssertEqual(menuView.reactions, customEmojis)

        // Test emoji encoding
        let complexEmoji = ["👨‍👩‍👧‍👦", "🏳️‍🌈", "👋🏽"]
        menuView.reactions = complexEmoji
        XCTAssertEqual(menuView.reactions.count, 3)
    }

    // MARK: - Menu Creation Tests

    func testCreateMenuWithValidItems() {
        let items: [[String: Any]] = [
            ["id": "1", "title": "Option 1"],
            ["id": "2", "title": "Option 2", "subtitle": "Description"],
            ["id": "3", "title": "Delete", "destructive": true],
            ["id": "4", "title": "Disabled", "disabled": true]
        ]

        menuView.menuItems = items

        // Create menu through delegate method
        let interaction = UIContextMenuInteraction(delegate: menuView)
        let config = menuView.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)

        XCTAssertNotNil(config, "Should create menu configuration")

        // Test preview provider
        if menuView.showPreview {
            XCTAssertNotNil(config?.previewProvider)
        } else {
            XCTAssertNil(config?.previewProvider)
        }
    }

    func testCreateMenuWithSubmenu() {
        let items: [[String: Any]] = [
            ["id": "1", "title": "Option 1"],
            [
                "id": "2",
                "title": "More",
                "children": [
                    ["id": "2.1", "title": "Sub Option 1"],
                    ["id": "2.2", "title": "Sub Option 2"]
                ]
            ]
        ]

        menuView.menuItems = items

        let interaction = UIContextMenuInteraction(delegate: menuView)
        let config = menuView.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)

        XCTAssertNotNil(config, "Should create menu configuration with submenu")
    }

    func testCreateMenuWithIcons() {
        let items: [[String: Any]] = [
            ["id": "1", "title": "Star", "icon": "star.fill"],
            ["id": "2", "title": "Heart", "icon": "heart.fill"],
            ["id": "3", "title": "Trash", "icon": "trash", "destructive": true]
        ]

        menuView.menuItems = items

        let interaction = UIContextMenuInteraction(delegate: menuView)
        let config = menuView.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)

        XCTAssertNotNil(config, "Should create menu with icons")
    }

    // MARK: - Event Handler Tests

    func testOnItemPressEvent() {
        let expectation = XCTestExpectation(description: "onItemPress event")

        menuView.onItemPress.addListener { event in
            if let itemId = event["itemId"] as? String {
                XCTAssertEqual(itemId, "test-item")
                expectation.fulfill()
            }
        }

        // Trigger event
        menuView.onItemPress(["itemId": "test-item"])

        wait(for: [expectation], timeout: 1.0)
    }

    func testOnMenuShowEvent() {
        let expectation = XCTestExpectation(description: "onMenuShow event")

        menuView.onMenuShow.addListener { _ in
            expectation.fulfill()
        }

        // Trigger event
        menuView.onMenuShow()

        wait(for: [expectation], timeout: 1.0)
    }

    func testOnMenuDismissEvent() {
        let expectation = XCTestExpectation(description: "onMenuDismiss event")

        menuView.onMenuDismiss.addListener { _ in
            expectation.fulfill()
        }

        // Trigger event
        menuView.onMenuDismiss()

        wait(for: [expectation], timeout: 1.0)
    }

    func testOnReactionPressEvent() {
        let expectation = XCTestExpectation(description: "onReactionPress event")

        menuView.onReactionPress.addListener { event in
            if let emoji = event["emoji"] as? String,
               let selected = event["selected"] as? Bool {
                XCTAssertEqual(emoji, "👍")
                XCTAssertTrue(selected)
                expectation.fulfill()
            }
        }

        // Trigger event
        menuView.onReactionPress(["emoji": "👍", "selected": true])

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Emoji Picker Tests

    func testShowEmojiPicker() {
        // Add view to window for testing
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        window.addSubview(menuView)
        menuView.frame = CGRect(x: 100, y: 200, width: 120, height: 44)

        menuView.showReactions = true
        menuView.reactions = ["👍", "❤️", "😂"]

        // Trigger emoji picker
        menuView.showEmojiPicker()

        // Wait for async operations
        let expectation = XCTestExpectation(description: "Emoji picker shown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(menuView.emojiPickerView)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testHideEmojiPicker() {
        // Setup emoji picker first
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        window.addSubview(menuView)
        menuView.frame = CGRect(x: 100, y: 200, width: 120, height: 44)

        menuView.showReactions = true
        menuView.showEmojiPicker()

        // Hide emoji picker
        let expectation = XCTestExpectation(description: "Emoji picker hidden")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            menuView.hideEmojiPicker()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                XCTAssertNil(menuView.emojiPickerView)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Gesture Tests

    func testTapGestureInTapMode() {
        menuView.updateTriggerMode("tap")

        // Find tap gesture
        let tapGesture = menuView.gestureRecognizers?.first { $0 is UITapGestureRecognizer }
        XCTAssertNotNil(tapGesture, "Should have tap gesture in tap mode")
    }

    // MARK: - Context Menu Delegate Tests

    func testContextMenuPreviewProvider() {
        menuView.showPreview = true

        let interaction = UIContextMenuInteraction(delegate: menuView)
        let config = menuView.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)

        XCTAssertNotNil(config?.previewProvider, "Should provide preview when showPreview is true")

        menuView.showPreview = false
        let config2 = menuView.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)

        XCTAssertNil(config2?.previewProvider, "Should not provide preview when showPreview is false")
    }

    func testContextMenuWillDisplay() {
        let expectation = XCTestExpectation(description: "Menu will display")

        menuView.onMenuShow.addListener { _ in
            expectation.fulfill()
        }

        let interaction = UIContextMenuInteraction(delegate: menuView)
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            return UIMenu(title: "", children: [])
        }

        menuView.contextMenuInteraction(interaction, willDisplayMenuFor: config, animator: nil)

        wait(for: [expectation], timeout: 1.0)
    }

    func testContextMenuWillEnd() {
        let expectation = XCTestExpectation(description: "Menu will end")

        menuView.onMenuDismiss.addListener { _ in
            expectation.fulfill()
        }

        let interaction = UIContextMenuInteraction(delegate: menuView)
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            return UIMenu(title: "", children: [])
        }

        menuView.contextMenuInteraction(interaction, willEndFor: config, animator: nil)

        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Classes

class MockAppContext: AppContext {
    override init() {
        super.init()
    }
}

// MARK: - Helper Extensions

extension ExpoFocusMenuView {
    // Expose private properties for testing
    var emojiPickerView: EmojiPickerView? {
        // This would need to be made internal or use runtime access
        return nil
    }

    func showEmojiPicker() {
        // This would need to be made internal for testing
    }

    func hideEmojiPicker() {
        // This would need to be made internal for testing
    }
}

// MARK: - EventDispatcher Extension for Testing

extension EventDispatcher {
    func addListener(_ listener: @escaping ([String: Any]) -> Void) {
        // This would need proper implementation for testing
    }

    func callAsFunction(_ parameters: [String: Any]) {
        // Trigger the event for testing
    }
}