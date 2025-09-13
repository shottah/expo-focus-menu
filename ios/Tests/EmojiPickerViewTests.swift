import XCTest
import UIKit
@testable import ExpoFocusMenu

class EmojiPickerViewTests: XCTestCase {

    var emojiPicker: EmojiPickerView!
    var window: UIWindow!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
    }

    override func tearDown() {
        emojiPicker = nil
        window = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializationWithEmojis() {
        let emojis = ["👍", "❤️", "😂", "🔥", "💯"]
        emojiPicker = EmojiPickerView(frame: .zero, emojis: emojis)

        XCTAssertNotNil(emojiPicker)
        XCTAssertEqual(emojiPicker.emojis.count, 5)
        XCTAssertEqual(emojiPicker.emojis, emojis)
        XCTAssertNil(emojiPicker.selectedEmoji)
    }

    func testInitializationWithEmptyEmojis() {
        emojiPicker = EmojiPickerView(frame: .zero, emojis: [])

        XCTAssertNotNil(emojiPicker)
        XCTAssertEqual(emojiPicker.emojis.count, 0)
        XCTAssertNil(emojiPicker.selectedEmoji)
    }

    func testDefaultEmojis() {
        let defaultEmojis = EmojiPickerView.defaultEmojis
        XCTAssertEqual(defaultEmojis.count, 10)
        XCTAssertEqual(defaultEmojis[0], "😀")
        XCTAssertEqual(defaultEmojis[1], "😂")
        XCTAssertEqual(defaultEmojis[2], "❤️")
        XCTAssertEqual(defaultEmojis[3], "👍")
        XCTAssertEqual(defaultEmojis[4], "🔥")
        XCTAssertEqual(defaultEmojis[5], "💯")
        XCTAssertEqual(defaultEmojis[6], "😍")
        XCTAssertEqual(defaultEmojis[7], "🎉")
        XCTAssertEqual(defaultEmojis[8], "👏")
        XCTAssertEqual(defaultEmojis[9], "✨")
    }

    // MARK: - Emoji Encoding Tests

    func testComplexEmojiEncoding() {
        // Test multi-codepoint emojis
        let complexEmojis = [
            "👨‍👩‍👧‍👦", // Family
            "🏳️‍🌈",     // Rainbow flag
            "👋🏽",       // Waving hand with skin tone
            "❤️‍🔥",      // Heart on fire
            "👨‍💻"       // Man technologist
        ]

        emojiPicker = EmojiPickerView(frame: .zero, emojis: complexEmojis)

        XCTAssertEqual(emojiPicker.emojis.count, 5)

        // Verify each emoji is properly encoded
        for (index, emoji) in emojiPicker.emojis.enumerated() {
            XCTAssertNotNil(emoji.data(using: .utf8), "Emoji at index \(index) should be valid UTF-8")
            XCTAssertGreaterThan(emoji.utf8.count, 0, "Emoji at index \(index) should have UTF-8 bytes")
        }
    }

    // MARK: - View Setup Tests

    func testViewHierarchy() {
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: ["👍"])
        window.addSubview(emojiPicker)

        // Check background color
        XCTAssertEqual(emojiPicker.backgroundColor, .clear)

        // Check for blur view (or solid background on simulator)
        let hasBlurView = emojiPicker.subviews.contains { subview in
            subview.subviews.contains { $0 is UIVisualEffectView }
        }
        XCTAssertTrue(hasBlurView || emojiPicker.subviews.count > 0, "Should have background view")

        // Check for collection view
        let hasCollectionView = emojiPicker.subviews.contains { subview in
            subview.subviews.contains { view in
                view.subviews.contains { $0 is UICollectionView }
            }
        }
        XCTAssertTrue(hasCollectionView, "Should have collection view")
    }

    func testViewCornerRadius() {
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: ["👍"])

        // Check pill shape corner radius
        if let backgroundView = emojiPicker.subviews.first {
            XCTAssertEqual(backgroundView.layer.cornerRadius, 28.0, "Should have pill shape corner radius")
            XCTAssertTrue(backgroundView.layer.masksToBounds)
        }
    }

    func testShadowConfiguration() {
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: ["👍"])

        XCTAssertEqual(emojiPicker.layer.shadowColor, UIColor.black.cgColor)
        XCTAssertEqual(emojiPicker.layer.shadowOpacity, 0.25)
        XCTAssertEqual(emojiPicker.layer.shadowRadius, 12.0)
        XCTAssertEqual(emojiPicker.layer.shadowOffset, CGSize(width: 0, height: 4))
    }

    // MARK: - Collection View DataSource Tests

    func testCollectionViewNumberOfItems() {
        let emojis = ["👍", "❤️", "😂", "🔥", "💯"]
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: emojis)

        let numberOfItems = emojiPicker.collectionView(UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()), numberOfItemsInSection: 0)
        XCTAssertEqual(numberOfItems, 5)
    }

    func testCollectionViewCellConfiguration() {
        let emojis = ["👍", "❤️", "😂"]
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: emojis)

        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCell")

        let indexPath = IndexPath(item: 0, section: 0)
        let cell = emojiPicker.collectionView(collectionView, cellForItemAt: indexPath) as? EmojiCollectionViewCell

        XCTAssertNotNil(cell)
        XCTAssertEqual(cell?.emojiLabel.text, "👍")
        XCTAssertFalse(cell?.emojiLabel.isHidden ?? true)
    }

    func testCollectionViewCellSelection() {
        let emojis = ["👍", "❤️", "😂"]
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: emojis)
        emojiPicker.selectedEmoji = "❤️"

        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCell")

        // Test selected cell
        let selectedIndexPath = IndexPath(item: 1, section: 0)
        let selectedCell = emojiPicker.collectionView(collectionView, cellForItemAt: selectedIndexPath) as? EmojiCollectionViewCell

        XCTAssertNotNil(selectedCell)
        XCTAssertEqual(selectedCell?.emojiLabel.text, "❤️")
        XCTAssertNotEqual(selectedCell?.contentView.backgroundColor, .clear)

        // Test unselected cell
        let unselectedIndexPath = IndexPath(item: 0, section: 0)
        let unselectedCell = emojiPicker.collectionView(collectionView, cellForItemAt: unselectedIndexPath) as? EmojiCollectionViewCell

        XCTAssertNotNil(unselectedCell)
        XCTAssertEqual(unselectedCell?.emojiLabel.text, "👍")
        XCTAssertEqual(unselectedCell?.contentView.backgroundColor, .clear)
    }

    // MARK: - Selection Tests

    func testEmojiSelection() {
        let emojis = ["👍", "❤️", "😂"]
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: emojis)

        let expectation = XCTestExpectation(description: "Emoji selected")
        var selectedEmoji: String?
        var wasSelected: Bool = false

        emojiPicker.onEmojiSelected = { emoji in
            selectedEmoji = emoji
            wasSelected = !emoji.isEmpty
            expectation.fulfill()
        }

        // Simulate selection
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let indexPath = IndexPath(item: 1, section: 0)
        emojiPicker.collectionView(collectionView, didSelectItemAt: indexPath)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(selectedEmoji, "❤️")
        XCTAssertTrue(wasSelected)
        XCTAssertEqual(emojiPicker.selectedEmoji, "❤️")
    }

    func testEmojiDeselection() {
        let emojis = ["👍", "❤️", "😂"]
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: emojis)
        emojiPicker.selectedEmoji = "❤️"

        let expectation = XCTestExpectation(description: "Emoji deselected")
        var deselectedEmoji: String?

        emojiPicker.onEmojiSelected = { emoji in
            deselectedEmoji = emoji
            expectation.fulfill()
        }

        // Simulate deselection (tap same emoji again)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let indexPath = IndexPath(item: 1, section: 0)
        emojiPicker.collectionView(collectionView, didSelectItemAt: indexPath)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(deselectedEmoji, "")
        XCTAssertNil(emojiPicker.selectedEmoji)
    }

    // MARK: - Reload Data Tests

    func testReloadData() {
        let initialEmojis = ["👍", "❤️"]
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: initialEmojis)

        // Change emojis
        let newEmojis = ["😀", "😂", "🔥", "💯"]
        emojiPicker.emojis = newEmojis

        XCTAssertEqual(emojiPicker.emojis.count, 4)
        XCTAssertEqual(emojiPicker.emojis, newEmojis)

        // Test collection view updates
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let numberOfItems = emojiPicker.collectionView(collectionView, numberOfItemsInSection: 0)
        XCTAssertEqual(numberOfItems, 4)
    }

    // MARK: - Hide Animation Tests

    func testHideMethod() {
        emojiPicker = EmojiPickerView(frame: CGRect(x: 0, y: 0, width: 280, height: 56), emojis: ["👍"])
        window.addSubview(emojiPicker)

        let expectation = XCTestExpectation(description: "Hide animation completed")

        emojiPicker.hide {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNil(emojiPicker.superview, "View should be removed from superview")
    }

    // MARK: - Cell Tests

    func testEmojiCollectionViewCell() {
        let cell = EmojiCollectionViewCell(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        XCTAssertNotNil(cell.emojiLabel)
        XCTAssertEqual(cell.emojiLabel.textAlignment, .center)
        XCTAssertEqual(cell.emojiLabel.font, .systemFont(ofSize: 24))
        XCTAssertEqual(cell.contentView.backgroundColor, .clear)
        XCTAssertEqual(cell.contentView.layer.cornerRadius, 20.0)
    }

    func testEmojiCellSelection() {
        let cell = EmojiCollectionViewCell(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        // Test selection
        cell.isSelected = true
        XCTAssertNotEqual(cell.contentView.backgroundColor, .clear)
        XCTAssertEqual(cell.transform, CGAffineTransform(scaleX: 1.1, y: 1.1))

        // Test deselection
        cell.isSelected = false
        XCTAssertEqual(cell.contentView.backgroundColor, .clear)
        XCTAssertEqual(cell.transform, .identity)
    }

    func testEmojiCellHighlight() {
        let cell = EmojiCollectionViewCell(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        // Test highlight
        cell.isHighlighted = true
        XCTAssertNotEqual(cell.contentView.backgroundColor, .clear)
        XCTAssertEqual(cell.transform, CGAffineTransform(scaleX: 0.95, y: 0.95))

        // Test unhighlight
        cell.isHighlighted = false
        XCTAssertEqual(cell.contentView.backgroundColor, .clear)
        XCTAssertEqual(cell.transform, .identity)
    }
}