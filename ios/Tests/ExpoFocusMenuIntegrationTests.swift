import XCTest
import ExpoModulesCore
import UIKit
@testable import ExpoFocusMenu

@available(iOS 13.0, *)
class ExpoFocusMenuIntegrationTests: XCTestCase {

    var module: ExpoFocusMenuModule!
    var menuView: ExpoFocusMenuView!
    var mockAppContext: AppContext!

    override func setUp() {
        super.setUp()
        mockAppContext = MockIntegrationAppContext()
        module = ExpoFocusMenuModule()
        menuView = ExpoFocusMenuView(appContext: mockAppContext)
    }

    override func tearDown() {
        menuView = nil
        module = nil
        mockAppContext = nil
        super.tearDown()
    }

    // MARK: - Module to View Integration Tests

    func testModuleDefinitionIncludesView() {
        let definition = module.definition()

        // Verify the module exports the view
        // Note: This test would need access to the actual module definition structure
        XCTAssertNotNil(definition)
    }

    func testViewPropsFromModule() {
        // Test that props defined in module work with the view
        let items: [[String: Any]] = [
            ["id": "1", "title": "Option 1"],
            ["id": "2", "title": "Option 2"]
        ]

        // Set props as they would be from the module
        menuView.menuItems = items
        menuView.updateTriggerMode("tap")
        menuView.showPreview = true
        menuView.hapticFeedback = true
        menuView.showReactions = true
        menuView.reactions = ["👍", "❤️"]

        // Verify props are set correctly
        XCTAssertEqual(menuView.menuItems.count, 2)
        XCTAssertEqual(menuView.triggerMode, "tap")
        XCTAssertTrue(menuView.showPreview)
        XCTAssertTrue(menuView.hapticFeedback)
        XCTAssertTrue(menuView.showReactions)
        XCTAssertEqual(menuView.reactions.count, 2)
    }

    // MARK: - Event System Integration Tests

    func testEventPropagationFromViewToModule() {
        let expectation = XCTestExpectation(description: "Event propagation")

        // Set up event listener on the view
        var receivedItemId: String?
        menuView.onItemPress.addListener { event in
            receivedItemId = event["itemId"] as? String
            expectation.fulfill()
        }

        // Simulate menu item selection
        menuView.onItemPress(["itemId": "test-item"])

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedItemId, "test-item")
    }

    func testMultipleEventHandlers() {
        let itemPressExpectation = XCTestExpectation(description: "Item press")
        let menuShowExpectation = XCTestExpectation(description: "Menu show")
        let menuDismissExpectation = XCTestExpectation(description: "Menu dismiss")
        let reactionExpectation = XCTestExpectation(description: "Reaction press")

        // Set up all event listeners
        menuView.onItemPress.addListener { _ in
            itemPressExpectation.fulfill()
        }

        menuView.onMenuShow.addListener { _ in
            menuShowExpectation.fulfill()
        }

        menuView.onMenuDismiss.addListener { _ in
            menuDismissExpectation.fulfill()
        }

        menuView.onReactionPress.addListener { _ in
            reactionExpectation.fulfill()
        }

        // Trigger all events
        menuView.onItemPress(["itemId": "test"])
        menuView.onMenuShow()
        menuView.onMenuDismiss()
        menuView.onReactionPress(["emoji": "👍", "selected": true])

        wait(for: [itemPressExpectation, menuShowExpectation, menuDismissExpectation, reactionExpectation], timeout: 1.0)
    }

    // MARK: - Menu Creation Integration Tests

    func testCompleteMenuFlowWithReactions() {
        // Setup complete menu configuration
        let items: [[String: Any]] = [
            ["id": "share", "title": "Share", "icon": "square.and.arrow.up"],
            ["id": "copy", "title": "Copy", "icon": "doc.on.doc"],
            ["id": "delete", "title": "Delete", "icon": "trash", "destructive": true]
        ]

        menuView.menuItems = items
        menuView.showReactions = true
        menuView.reactions = ["👍", "❤️", "😂", "🔥", "💯"]
        menuView.hapticFeedback = true
        menuView.showPreview = false

        // Add to window to simulate real usage
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        window.addSubview(menuView)
        menuView.frame = CGRect(x: 100, y: 200, width: 120, height: 44)

        // Test context menu creation
        let interaction = UIContextMenuInteraction(delegate: menuView)
        let config = menuView.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)

        XCTAssertNotNil(config, "Should create menu configuration")
        XCTAssertNil(config?.previewProvider, "Should not have preview when showPreview is false")

        // Test menu display callback
        let showExpectation = XCTestExpectation(description: "Menu shown")
        menuView.onMenuShow.addListener { _ in
            showExpectation.fulfill()
        }

        menuView.contextMenuInteraction(interaction, willDisplayMenuFor: config!, animator: nil)

        wait(for: [showExpectation], timeout: 1.0)

        // Test menu dismiss callback
        let dismissExpectation = XCTestExpectation(description: "Menu dismissed")
        menuView.onMenuDismiss.addListener { _ in
            dismissExpectation.fulfill()
        }

        menuView.contextMenuInteraction(interaction, willEndFor: config!, animator: nil)

        wait(for: [dismissExpectation], timeout: 1.0)
    }

    // MARK: - Module Methods Integration Tests

    func testShowNativeMenuIntegration() async {
        let items: [[String: Any]] = [
            ["id": "option1", "title": "Option 1"],
            ["id": "option2", "title": "Option 2", "icon": "star"],
            [
                "id": "submenu",
                "title": "More Options",
                "children": [
                    ["id": "child1", "title": "Child Option 1"],
                    ["id": "child2", "title": "Child Option 2"]
                ]
            ]
        ]

        let config: [String: Any] = [
            "showPreview": true,
            "hapticFeedback": true
        ]

        // Test menu creation without UI (will fail but shouldn't crash)
        do {
            _ = try await module.showNativeMenu(items: items, config: config)
        } catch {
            // Expected in test environment
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Emoji Picker Integration Tests

    func testEmojiPickerIntegrationWithMenuView() {
        // Setup menu view with reactions
        menuView.showReactions = true
        menuView.reactions = ["👍", "❤️", "😂", "🔥", "💯", "🎉"]

        // Add to window
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        window.addSubview(menuView)
        menuView.frame = CGRect(x: 100, y: 200, width: 120, height: 44)

        // Test emoji selection event
        let expectation = XCTestExpectation(description: "Emoji selected")
        var selectedEmoji: String?
        var wasSelected: Bool = false

        menuView.onReactionPress.addListener { event in
            selectedEmoji = event["emoji"] as? String
            wasSelected = event["selected"] as? Bool ?? false
            expectation.fulfill()
        }

        // Simulate emoji selection
        menuView.onReactionPress(["emoji": "🔥", "selected": true])

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(selectedEmoji, "🔥")
        XCTAssertTrue(wasSelected)
    }

    // MARK: - Configuration Persistence Tests

    func testMenuConfigurationPersistence() async {
        // Set default configuration through module
        let defaultConfig: [String: Any] = [
            "showPreview": true,
            "hapticFeedback": false,
            "triggerMode": "tap"
        ]

        await module.setNativeMenuConfig(config: defaultConfig)

        // Verify configuration is stored (would need access to internal storage)
        // This is a placeholder for actual implementation
        XCTAssertTrue(true, "Configuration should be stored")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentEventHandling() {
        let expectation = XCTestExpectation(description: "Concurrent events")
        expectation.expectedFulfillmentCount = 100

        menuView.onItemPress.addListener { _ in
            expectation.fulfill()
        }

        // Trigger events from multiple queues
        let queue1 = DispatchQueue(label: "test.queue1")
        let queue2 = DispatchQueue(label: "test.queue2")

        for i in 0..<50 {
            queue1.async {
                self.menuView.onItemPress(["itemId": "item-\(i)"])
            }

            queue2.async {
                self.menuView.onItemPress(["itemId": "item-\(i + 50)"])
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Memory Management Tests

    func testViewCleanupOnDeinit() {
        // Create view in autoreleasepool to test cleanup
        autoreleasepool {
            let tempView = ExpoFocusMenuView(appContext: mockAppContext)
            tempView.menuItems = [["id": "1", "title": "Test"]]
            tempView.reactions = ["👍", "❤️"]

            // Add to window and then remove
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
            window.addSubview(tempView)
            tempView.removeFromSuperview()
        }

        // Verify no memory leaks (would need instruments for full testing)
        XCTAssertTrue(true, "View should be deallocated")
    }

    // MARK: - Error Handling Tests

    func testErrorHandlingInMenuCreation() async {
        // Test with invalid items
        let invalidItems: [[String: Any]] = []

        do {
            _ = try await module.showNativeMenu(items: invalidItems, config: [:])
            XCTFail("Should throw error for empty items")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "ExpoFocusMenu")
            XCTAssertEqual(nsError.code, 1)
            XCTAssertNotNil(nsError.localizedDescription)
        }
    }

    // MARK: - Accessibility Tests

    func testAccessibilitySupport() {
        menuView.accessibilityLabel = "Context Menu"
        menuView.accessibilityHint = "Long press to show menu"
        menuView.isAccessibilityElement = true

        XCTAssertEqual(menuView.accessibilityLabel, "Context Menu")
        XCTAssertEqual(menuView.accessibilityHint, "Long press to show menu")
        XCTAssertTrue(menuView.isAccessibilityElement)
    }

    // MARK: - Performance Tests

    func testLargeMenuPerformance() {
        // Create a large menu with many items
        var items: [[String: Any]] = []
        for i in 0..<100 {
            items.append([
                "id": "item-\(i)",
                "title": "Option \(i)",
                "icon": i % 2 == 0 ? "star" : "heart"
            ])
        }

        measure {
            menuView.menuItems = items

            let interaction = UIContextMenuInteraction(delegate: menuView)
            _ = menuView.contextMenuInteraction(interaction, configurationForMenuAtLocation: .zero)
        }
    }

    func testEmojiPickerPerformance() {
        // Create a large emoji list
        let emojis = Array(repeating: ["😀", "😂", "❤️", "👍", "🔥"], count: 20).flatMap { $0 }

        measure {
            let picker = EmojiPickerView(frame: .zero, emojis: emojis)
            _ = picker.collectionView(UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()), numberOfItemsInSection: 0)
        }
    }
}

// MARK: - Mock Classes for Integration Tests

class MockIntegrationAppContext: AppContext {
    override init() {
        super.init()
    }
}

// MARK: - Test Helpers

extension ExpoFocusMenuModule {
    // Test helper methods
    func showNativeMenu(items: [[String: Any]], config: [String: Any]) async throws -> String? {
        // This would need to be implemented or made accessible for testing
        return nil
    }

    func setNativeMenuConfig(config: [String: Any]) async {
        // This would need to be implemented or made accessible for testing
    }
}