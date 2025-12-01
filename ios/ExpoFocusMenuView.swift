import ExpoModulesCore
import UIKit

// Native view that handles the context menu interaction
class ExpoFocusMenuView: ExpoView, UIContextMenuInteractionDelegate {
  // Properties from JS
  var menuItems: [[String: Any]] = []
  // Removed triggerMode - always use long press
  var hapticFeedback: Bool = false
  // Store reactions with proper UTF-8 handling
  private var _reactions: [String] = []
  var reactions: [String] {
    get { return _reactions }
    set {
      // Ensure proper UTF-8 encoding for emojis
      _reactions = newValue.map { emoji in
        // Force re-encode the string to handle multi-byte UTF-8 properly
        if let data = emoji.data(using: .utf8),
           let reencoded = String(data: data, encoding: .utf8) {
          return reencoded
        }
        return emoji
      }
    // NSLog("🎯 Reactions array updated: count=%d, values=%@", _reactions.count, _reactions.description)

      // Update emoji picker if it exists
      if let picker = emojiPickerView {
        picker.emojis = _reactions
        picker.reloadData()
      }
    }
  }

  // Event handlers
  let onItemPress = EventDispatcher()
  let onMenuShow = EventDispatcher()
  let onMenuDismiss = EventDispatcher()
  let onReactionPress = EventDispatcher()

  // Context menu interaction
  private var contextMenuInteraction: UIContextMenuInteraction?
  private var emojiPickerView: EmojiPickerView?
  private var selectedEmoji: String?
  private var menuPreviewFrame: CGRect? // Store the actual menu preview frame
  private var menuAppearedAbove: Bool = false // Track actual menu position

  // Cache for snapshotted icon images
  private var iconImageCache: [String: UIImage] = [:]

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    setupView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    // Make the view transparent but interactive
    backgroundColor = .clear
    isUserInteractionEnabled = true

    // Add context menu interaction for iOS 13+
    if #available(iOS 13.0, *) {
      contextMenuInteraction = UIContextMenuInteraction(delegate: self)
      addInteraction(contextMenuInteraction!)
      // Only long press triggers the menu - no tap gesture
    }
  }

  // Removed handleTap - only long press triggers the menu

  // MARK: - Icon Snapshotting

  /// Recursively finds a subview by its React Native tag
  private func findViewByTag(_ tag: Int, in view: UIView? = nil) -> UIView? {
    let searchView = view ?? self

    // Check if this view has the tag we're looking for
    // React Native stores tags in the view's tag property or reactTag
    if searchView.tag == tag {
      return searchView
    }

    // Check for React Native's reactTag property via key-value coding
    if let reactTag = searchView.value(forKey: "reactTag") as? NSNumber,
       reactTag.intValue == tag {
      return searchView
    }

    // Recursively search subviews
    for subview in searchView.subviews {
      if let found = findViewByTag(tag, in: subview) {
        return found
      }
    }

    return nil
  }

  /// Snapshots a view to a UIImage
  private func snapshotView(_ view: UIView) -> UIImage? {
    guard view.bounds.size.width > 0 && view.bounds.size.height > 0 else {
      return nil
    }

    let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
    let image = renderer.image { _ in
      view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }

    return image
  }

  /// Prepares icon snapshots for all menu items with iconViewTag
  private func prepareIconSnapshots() {
    iconImageCache.removeAll()

    func processItems(_ items: [[String: Any]]) {
      for item in items {
        guard let itemId = item["id"] as? String,
              let viewTag = item["iconViewTag"] as? Int else { continue }

        if let iconView = findViewByTag(viewTag),
           let image = snapshotView(iconView) {
          iconImageCache[itemId] = image
        } else if ProcessInfo.processInfo.environment["DEBUG"] != nil {
          NSLog("[ExpoFocusMenu] Warning: Could not snapshot icon for item '\(itemId)'")
        }

        // Process children if present
        if let children = item["children"] as? [[String: Any]] {
          processItems(children)
        }
      }
    }

    processItems(menuItems)
  }

  // MARK: - UIContextMenuInteractionDelegate

  @available(iOS 13.0, *)
  func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    // Trigger haptic feedback if enabled
    if hapticFeedback {
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.prepare()
      generator.impactOccurred()
    }

    // Prepare icon snapshots before creating the menu
    prepareIconSnapshots()

    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      return self?.createMenu()
    }
  }

  // This method provides the actual preview target rect
  @available(iOS 13.0, *)
  func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
    // Store the current view position for reference
    if let window = self.window {
      let selfFrame = superview?.convert(frame, to: window) ?? frame
    // NSLog("🎯 Preview target rect: origin=(%.1f, %.1f) size=(%.1f, %.1f)",
    //        selfFrame.origin.x, selfFrame.origin.y, selfFrame.size.width, selfFrame.size.height)
    }

    // Return nil to use default preview
    return nil
  }

  // This method is called when dismissing and provides final preview position
  @available(iOS 13.0, *)
  func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
    // Return nil to use default preview
    return nil
  }

  @available(iOS 13.0, *)
  func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
    onMenuShow()

    // Reset previous detection
    menuPreviewFrame = nil
    menuAppearedAbove = false

    // Try multiple methods to detect menu position
    if let animator = animator {
      // Method 1: Check preview controller position during animation
      animator.addAnimations { [weak self] in
        guard let self = self else { return }

        // Try to find the actual menu container in the view hierarchy
        if let window = self.window {
          // Look for the menu backdrop view (typically a UIVisualEffectView)
          self.findContextMenuInHierarchy(window)

          // Also check preview position if available
          if let previewView = animator.previewViewController?.view,
             let previewSuperview = previewView.superview {
            let previewFrame = previewSuperview.convert(previewView.frame, to: window)
            let selfFrame = self.superview?.convert(self.frame, to: window) ?? self.frame

            // Context menus typically offset the preview
            // If preview moves up, menu is likely below
            // If preview moves down, menu is likely above
            let previewOffset = previewFrame.midY - selfFrame.midY

            if abs(previewOffset) > 10 {
              // Significant offset detected
              self.menuAppearedAbove = previewOffset > 0
              self.menuPreviewFrame = previewFrame

    // NSLog("🎯 Preview offset detected: %.1f, Menu likely %@",
    //              previewOffset,
    //              self.menuAppearedAbove ? "ABOVE" : "BELOW")
            }
          }
        }
      }

      // Method 2: Check after animation completes
      animator.addCompletion { [weak self] in
        guard let self = self else { return }
        if let window = self.window {
          self.findContextMenuInHierarchy(window)
        }
      }
    }

    // Show emoji picker if reactions are provided
    if !_reactions.isEmpty {
      // Adjusted delay for better timing
      let delay: TimeInterval = 0.25

      DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
        self?.showEmojiPicker()
      }
    }
  }

  // Helper method to find context menu in view hierarchy
  private func findContextMenuInHierarchy(_ view: UIView) {
    guard let window = self.window else { return }
    let selfFrame = superview?.convert(frame, to: window) ?? frame

    // Look for context menu container views
    for subview in view.subviews.reversed() {
      let viewClass = String(describing: type(of: subview))

      // Context menus are typically in _UIContextMenuContainerView or similar
      if viewClass.contains("ContextMenu") || viewClass.contains("Platter") {
        let menuFrame = subview.frame

        // Determine position relative to our view
        if menuFrame.midY < selfFrame.midY {
          menuAppearedAbove = true
    // NSLog("🎯 Found menu container ABOVE at Y: %.1f (view Y: %.1f)",
    //          menuFrame.midY, selfFrame.midY)
        } else {
          menuAppearedAbove = false
    // NSLog("🎯 Found menu container BELOW at Y: %.1f (view Y: %.1f)",
    //          menuFrame.midY, selfFrame.midY)
        }

        menuPreviewFrame = menuFrame
        return
      }

      // Recursively check subviews
      findContextMenuInHierarchy(subview)
    }
  }

  @available(iOS 13.0, *)
  func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
    onMenuDismiss()
    // Hide emoji picker when menu closes
    hideEmojiPicker()
    // Clear menu position tracking
    menuPreviewFrame = nil
    // Don't reset selection - keep it for next time
  }

  // MARK: - Menu Creation

  @available(iOS 13.0, *)
  private func createMenu() -> UIMenu? {
    guard !menuItems.isEmpty else { return nil }

    var menuElements: [UIMenuElement] = []

    for item in menuItems {
      guard let itemId = item["id"] as? String,
            let title = item["title"] as? String else { continue }

      let subtitle = item["subtitle"] as? String
      let destructive = item["destructive"] as? Bool ?? false
      let disabled = item["disabled"] as? Bool ?? false

      // Check if this item has children (submenu)
      if let children = item["children"] as? [[String: Any]], !children.isEmpty {
        // Create submenu
        var submenuActions: [UIAction] = []
        for child in children {
          if let childId = child["id"] as? String,
             let childTitle = child["title"] as? String {
            // Get cached icon for child item
            let childImage = iconImageCache[childId]
            let childAction = UIAction(title: childTitle, image: childImage) { [weak self] _ in
              self?.onItemPress(["itemId": childId])
            }
            submenuActions.append(childAction)
          }
        }
        let submenu = UIMenu(title: title, children: submenuActions)
        menuElements.append(submenu)
      } else {
        // Create regular action
        var attributes: UIMenuElement.Attributes = []
        if destructive {
          attributes.insert(.destructive)
        }
        if disabled {
          attributes.insert(.disabled)
        }

        // Create the action with title and optional subtitle
        let action: UIAction

        // Get cached icon image from snapshotted React component
        let image = iconImageCache[itemId]

        if let subtitle = subtitle {
          // iOS 15+ supports subtitles
          if #available(iOS 15.0, *) {
            action = UIAction(
              title: title,
              subtitle: subtitle,
              image: image,
              attributes: attributes
            ) { [weak self] _ in
              self?.onItemPress(["itemId": itemId])
            }
          } else {
            // Fallback: append subtitle to title
            action = UIAction(
              title: "\(title)\n\(subtitle)",
              image: image,
              attributes: attributes
            ) { [weak self] _ in
              self?.onItemPress(["itemId": itemId])
            }
          }
        } else {
          action = UIAction(
            title: title,
            image: image,
            attributes: attributes
          ) { [weak self] _ in
            self?.onItemPress(["itemId": itemId])
          }
        }

        menuElements.append(action)
      }
    }

    return UIMenu(title: "", children: menuElements)
  }


  // Removed updateTriggerMode - always use long press

  // MARK: - Emoji Picker

  private func showEmojiPicker() {
    // NSLog("🎯🎯🎯 showEmojiPicker called, reactions count=%d", _reactions.count)
    guard emojiPickerView == nil else {
    // NSLog("🎯🎯🎯 EmojiPicker already showing, returning")
      return
    }

    // Get the window
    guard let window = self.window else {
    // NSLog("🎯🎯🎯 No window available, cannot show emoji picker")
      return
    }

    // Get frame of self in window coordinates
    let selfFrame = superview?.convert(frame, to: window) ?? frame
    // NSLog("🎯🎯🎯 Self frame in window: origin=(%.1f, %.1f) size=(%.1f, %.1f)",
    //      selfFrame.origin.x, selfFrame.origin.y, selfFrame.size.width, selfFrame.size.height)

    // Determine where emoji picker should go (opposite of menu)
    let emojiPickerShouldGoBelow: Bool

    // Log current positioning data
    let screenHeight = window.bounds.height
    let spaceBelow = screenHeight - selfFrame.maxY
    let spaceAbove = selfFrame.minY

    // Consider safe area
    let safeAreaBottom: CGFloat
    let safeAreaTop: CGFloat
    if #available(iOS 11.0, *) {
      safeAreaBottom = window.safeAreaInsets.bottom
      safeAreaTop = window.safeAreaInsets.top
    } else {
      safeAreaBottom = 0
      safeAreaTop = 20 // Status bar height
    }

    let effectiveSpaceBelow = spaceBelow - safeAreaBottom
    let effectiveSpaceAbove = spaceAbove - safeAreaTop

    // NSLog("🎯🎯 Position Analysis:")
    // NSLog("  View frame: origin=(%.0f, %.0f) size=(%.0f, %.0f)",
    //      selfFrame.origin.x, selfFrame.origin.y, selfFrame.width, selfFrame.height)
    // NSLog("  Screen height: %.0f", screenHeight)
    // NSLog("  Space above: %.0f (effective: %.0f)", spaceAbove, effectiveSpaceAbove)
    // NSLog("  Space below: %.0f (effective: %.0f)", spaceBelow, effectiveSpaceBelow)
    // NSLog("  Safe areas - top: %.0f, bottom: %.0f", safeAreaTop, safeAreaBottom)

    if menuPreviewFrame != nil && menuAppearedAbove {
      // We detected menu position - use it
      emojiPickerShouldGoBelow = true // Menu above, picker below
    // NSLog("🎯 DETECTED: Menu is ABOVE, emoji picker will go BELOW")
    } else if menuPreviewFrame != nil && !menuAppearedAbove {
      // Menu detected below
      emojiPickerShouldGoBelow = false // Menu below, picker above
    // NSLog("🎯 DETECTED: Menu is BELOW, emoji picker will go ABOVE")
    } else {
      // Fallback to improved heuristic
    // NSLog("🎯 Using HEURISTIC for menu position")

      // iOS context menu positioning rules (based on testing):
      // 1. Menus need ~250pt of space
      // 2. They prefer below if space >= 250pt
      // 3. They go above if space below < 250pt AND space above >= 250pt
      // 4. In tight spaces, they choose the side with more room
      let menuSpaceRequired: CGFloat = 250

      let menuLikelyBelow: Bool
      if effectiveSpaceBelow >= menuSpaceRequired {
        // Enough space below - menu will go below
        menuLikelyBelow = true
    // NSLog("  ✓ Sufficient space below (%.0f >= %.0f) → Menu BELOW",
    //        effectiveSpaceBelow, menuSpaceRequired)
      } else if effectiveSpaceAbove >= menuSpaceRequired {
        // Not enough below, but enough above - menu will go above
        menuLikelyBelow = false
    // NSLog("  ✓ Insufficient below, sufficient above → Menu ABOVE")
      } else {
        // Tight space - menu goes to side with more room
        menuLikelyBelow = effectiveSpaceBelow > effectiveSpaceAbove
    // NSLog("  ✓ Tight space, choosing side with more room → Menu %@",
    //        menuLikelyBelow ? "BELOW" : "ABOVE")
      }

      // Position emoji picker opposite to menu
      emojiPickerShouldGoBelow = !menuLikelyBelow
    // NSLog("🎯 RESULT: Menu likely %@, emoji picker will go %@",
    //      menuLikelyBelow ? "BELOW" : "ABOVE",
    //      emojiPickerShouldGoBelow ? "BELOW" : "ABOVE")
    }

    // Create emoji picker with provided emojis only
    guard !_reactions.isEmpty else {
      // NSLog("🎯🎯🎯 No reactions provided, not showing emoji picker")
      return
    }

    // NSLog("🎯🎯🎯 Creating EmojiPickerView with %d reactions: %@", _reactions.count, _reactions.description)
    print("🎯🎯🎯 Creating EmojiPickerView with reactions: \(_reactions)")
    let emojiPicker = EmojiPickerView(frame: .zero, emojis: _reactions)
    emojiPicker.translatesAutoresizingMaskIntoConstraints = false
    emojiPicker.selectedEmoji = selectedEmoji // Restore previous selection

    emojiPicker.onEmojiSelected = { [weak self] emoji in
      guard let self = self else { return }

      if emoji.isEmpty {
        // Emoji was deselected
        self.selectedEmoji = nil
        self.onReactionPress(["emoji": emoji, "selected": false])
      } else {
        // Emoji was selected
        self.selectedEmoji = emoji
        self.onReactionPress(["emoji": emoji, "selected": true])
      }

      // Don't hide the picker - keep it visible
    // NSLog("🎯 Emoji selected: %@, keeping picker visible", emoji.isEmpty ? "(deselected)" : emoji)
    }

    window.addSubview(emojiPicker)
    self.emojiPickerView = emojiPicker

    // Ensure emoji picker is above other views (simulator fix)
    emojiPicker.layer.zPosition = 999
    window.bringSubviewToFront(emojiPicker)

    // Position emoji picker
    let pickerWidth = min(selfFrame.width * 1.2, 280)
    let pickerHeight: CGFloat = 56 // Compact pill height

    NSLayoutConstraint.activate([
      emojiPicker.widthAnchor.constraint(equalToConstant: pickerWidth),
      emojiPicker.heightAnchor.constraint(equalToConstant: pickerHeight),
      emojiPicker.centerXAnchor.constraint(equalTo: window.centerXAnchor, constant: selfFrame.midX - window.bounds.midX)
    ])

    // Position emoji picker on opposite side of menu
    // Add extra spacing to ensure clear separation from menu
    let emojiPickerSpacing: CGFloat = 20

    if emojiPickerShouldGoBelow {
      // Emoji picker goes below the view
      NSLayoutConstraint.activate([
        emojiPicker.topAnchor.constraint(equalTo: window.topAnchor, constant: selfFrame.maxY + emojiPickerSpacing)
      ])
    // NSLog("🎯 Positioning emoji picker BELOW view")
    } else {
      // Emoji picker goes above the view
      NSLayoutConstraint.activate([
        emojiPicker.bottomAnchor.constraint(equalTo: window.topAnchor, constant: selfFrame.minY - emojiPickerSpacing)
      ])
    // NSLog("🎯 Positioning emoji picker ABOVE view")
    }
  }

  private func hideEmojiPicker() {
    // Store the current selection before hiding
    if let picker = emojiPickerView {
      selectedEmoji = picker.selectedEmoji
    }

    emojiPickerView?.hide { [weak self] in
      self?.emojiPickerView = nil
    }
  }
}