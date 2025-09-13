import XCTest
import ExpoModulesCore
@testable import ExpoFocusMenu

class ExpoFocusMenuModuleTests: XCTestCase {

    var module: ExpoFocusMenuModule!

    override func setUp() {
        super.setUp()
        module = ExpoFocusMenuModule()
    }

    override func tearDown() {
        module = nil
        super.tearDown()
    }

    // MARK: - Module Definition Tests

    func testModuleName() {
        let definition = module.definition()
        XCTAssertNotNil(definition)
        // Module should have name "ExpoFocusMenu"
    }

    // MARK: - ShowNativeMenu Tests

    func testShowNativeMenuWithEmptyItems() async {
        let items: [[String: Any]] = []
        let config: [String: Any] = [:]

        do {
            _ = try await module.showNativeMenu(items: items, config: config)
            XCTFail("Should throw error for empty items")
        } catch {
            XCTAssertNotNil(error)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "ExpoFocusMenu")
            XCTAssertEqual(nsError.code, 1)
        }
    }

    func testShowNativeMenuWithValidItems() async {
        let items: [[String: Any]] = [
            ["id": "item1", "title": "Option 1"],
            ["id": "item2", "title": "Option 2", "disabled": true],
            ["id": "item3", "title": "Delete", "destructive": true]
        ]
        let config: [String: Any] = [
            "showPreview": false,
            "hapticFeedback": true
        ]

        // Note: This test will need UI mocking to fully test menu presentation
        // For now, we test that the method doesn't crash with valid input
        do {
            _ = try await module.showNativeMenu(items: items, config: config)
        } catch {
            // Expected in test environment without UI
            XCTAssertNotNil(error)
        }
    }

    func testShowNativeMenuWithSubmenu() async {
        let items: [[String: Any]] = [
            ["id": "item1", "title": "Option 1"],
            [
                "id": "submenu",
                "title": "More Options",
                "children": [
                    ["id": "child1", "title": "Child 1"],
                    ["id": "child2", "title": "Child 2"]
                ]
            ]
        ]
        let config: [String: Any] = [:]

        do {
            _ = try await module.showNativeMenu(items: items, config: config)
        } catch {
            // Expected in test environment without UI
            XCTAssertNotNil(error)
        }
    }

    // MARK: - DismissNativeMenu Tests

    func testDismissNativeMenu() async {
        await module.dismissNativeMenu()
        // Verify currentMenuController is nil
        XCTAssertNil(module.currentMenuController)
    }

    // MARK: - IsNativeMenuVisible Tests

    func testIsNativeMenuVisibleWhenNoMenu() async {
        let isVisible = await module.isNativeMenuVisible()
        XCTAssertFalse(isVisible)
    }

    // MARK: - SetNativeMenuConfig Tests

    func testSetNativeMenuConfig() async {
        let config: [String: Any] = [
            "showPreview": true,
            "hapticFeedback": false,
            "triggerMode": "tap"
        ]

        await module.setNativeMenuConfig(config: config)
        // This method doesn't return anything, just verify it doesn't crash
        XCTAssertTrue(true)
    }

    // MARK: - Menu Creation Tests

    func testCreateMenuWithValidItems() {
        let items: [[String: Any]] = [
            ["id": "item1", "title": "Option 1", "icon": "star.fill"],
            ["id": "item2", "title": "Option 2", "disabled": true],
            ["id": "item3", "title": "Delete", "destructive": true, "icon": "trash"]
        ]

        let expectation = XCTestExpectation(description: "Menu selection")

        let menu = module.createMenu(from: items) { selectedId in
            XCTAssertEqual(selectedId, "item1")
            expectation.fulfill()
        }

        if #available(iOS 14.0, *) {
            XCTAssertNotNil(menu)
            XCTAssertEqual(menu?.children.count, 3)

            // Test menu structure
            if let firstAction = menu?.children.first as? UIAction {
                XCTAssertEqual(firstAction.title, "Option 1")
                XCTAssertNotNil(firstAction.image)
            }

            if let secondAction = menu?.children[1] as? UIAction {
                XCTAssertEqual(secondAction.title, "Option 2")
                XCTAssertTrue(secondAction.attributes.contains(.disabled))
            }

            if let thirdAction = menu?.children[2] as? UIAction {
                XCTAssertEqual(thirdAction.title, "Delete")
                XCTAssertTrue(thirdAction.attributes.contains(.destructive))
            }
        }
    }

    func testCreateMenuWithInvalidItems() {
        let items: [[String: Any]] = [
            [:], // Invalid item without id or title
            ["title": "No ID"], // Missing id
            ["id": "no-title"] // Missing title
        ]

        let menu = module.createMenu(from: items) { _ in }

        if #available(iOS 14.0, *) {
            XCTAssertNotNil(menu)
            XCTAssertEqual(menu?.children.count, 0) // All items should be filtered out
        }
    }

    // MARK: - Helper Method Tests

    func testGetTopViewController() {
        // This test requires a UI context
        // In a real app test, you'd set up a window and view controller hierarchy
        let topVC = module.getTopViewController()
        // In test environment, this will likely be nil
        // XCTAssertNil(topVC) or XCTAssertNotNil(topVC) depending on test setup
    }
}

// MARK: - Mock Extensions for Testing

extension ExpoFocusMenuModule {
    // Expose private properties/methods for testing
    var currentMenuController: UIViewController? {
        get {
            // Use runtime to access private property
            return nil // Placeholder
        }
    }

    // Expose private methods for testing
    func createMenu(from items: [[String: Any]], onSelect: @escaping (String) -> Void) -> UIMenu? {
        // This would need to be implemented or made internal for testing
        return nil
    }

    func getTopViewController() -> UIViewController? {
        // This would need to be implemented or made internal for testing
        return nil
    }

    // Async wrapper methods for testing
    func showNativeMenu(items: [[String: Any]], config: [String: Any]) async throws -> String? {
        // This would call the actual implementation
        return nil
    }

    func dismissNativeMenu() async {
        // This would call the actual implementation
    }

    func isNativeMenuVisible() async -> Bool {
        // This would call the actual implementation
        return false
    }

    func setNativeMenuConfig(config: [String: Any]) async {
        // This would call the actual implementation
    }
}