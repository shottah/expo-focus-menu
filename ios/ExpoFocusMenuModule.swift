import ExpoModulesCore
import UIKit

public class ExpoFocusMenuModule: Module {
  private var currentMenuController: UIViewController?

  public func definition() -> ModuleDefinition {
    Name("ExpoFocusMenu")

    // Define events that can be sent to JavaScript
    Events("onMenuItemSelected", "onMenuShown", "onMenuDismissed")

    // Show the native context menu
    AsyncFunction("showNativeMenu") { (items: [[String: Any]], config: [String: Any]?) -> String? in
      return try await showMenu(items: items, config: config ?? [:])
    }

    // Dismiss the currently visible menu
    AsyncFunction("dismissNativeMenu") { () -> Void in
      Task { @MainActor in
        dismissMenu()
      }
    }

    // Check if a menu is currently visible
    AsyncFunction("isNativeMenuVisible") { () -> Bool in
      return currentMenuController != nil
    }

    // Set default configuration for menus
    AsyncFunction("setNativeMenuConfig") { (config: [String: Any]) -> Void in
      // Store config for future use (could be stored in UserDefaults or instance variable)
    }

    // Export the native view
    View(ExpoFocusMenuView.self) {
      // Define props for the view
      Prop("items") { (view: ExpoFocusMenuView, items: [[String: Any]]) in
        view.menuItems = items
      }

      Prop("triggerMode") { (view: ExpoFocusMenuView, mode: String) in
        view.updateTriggerMode(mode)
      }

      Prop("showPreview") { (view: ExpoFocusMenuView, show: Bool) in
        view.showPreview = show
      }

      Prop("hapticFeedback") { (view: ExpoFocusMenuView, enabled: Bool) in
        view.hapticFeedback = enabled
      }

      Prop("showReactions") { (view: ExpoFocusMenuView, show: Bool) in
        view.showReactions = show
      }

      Prop("reactions") { (view: ExpoFocusMenuView, emojis: [String]?) in
    // NSLog("🎯 Received reactions prop: %@", (emojis ?? []).description)

        // Ensure we're properly setting the array
        if let emojis = emojis {
          view.reactions = emojis
    // NSLog("🎯 Set view.reactions to: %@", view.reactions.description)

          // Log each emoji individually to verify encoding
          for (index, emoji) in emojis.enumerated() {
    // NSLog("🎯 Prop emoji[%d]: '%@' (UTF-8 bytes: %d)", index, emoji, emoji.utf8.count)
          }
        } else {
          view.reactions = []
    // NSLog("🎯 No reactions provided, using empty array")
        }
      }


      // Event handlers
      Events("onItemPress", "onMenuShow", "onMenuDismiss", "onReactionPress")
    }
  }

  @MainActor
  private func showMenu(items: [[String: Any]], config: [String: Any]) async throws -> String? {
    guard !items.isEmpty else {
      throw NSError(domain: "ExpoFocusMenu", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "Menu items cannot be empty"
      ])
    }

    // Create a semaphore to wait for menu selection
    return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
      DispatchQueue.main.async {
        // Get the key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
          continuation.resume(returning: nil)
          return
        }

        // Create a transparent view controller to host the menu
        let menuController = UIViewController()
        menuController.view.backgroundColor = .clear

        // Create the menu
        let menu = self.createMenu(from: items) { selectedId in
          // Clean up and return the selected item ID
          self.dismissMenu()
          continuation.resume(returning: selectedId)
        }

        // Configure the menu based on config
        let showPreview = config["showPreview"] as? Bool ?? false
        let hapticFeedback = config["hapticFeedback"] as? Bool ?? false

        if hapticFeedback {
          let generator = UIImpactFeedbackGenerator(style: .light)
          generator.prepare()
          generator.impactOccurred()
        }

        // For iOS 14+, show menu using UIMenu directly
        if #available(iOS 14.0, *), let menu = menu {
          // Get the topmost view controller
          guard let topViewController = self.getTopViewController() else {
            continuation.resume(returning: nil)
            return
          }

          // Create a button to trigger the menu
          let menuButton = UIButton(frame: CGRect(x: window.frame.midX - 50, y: window.frame.midY - 20, width: 100, height: 40))
          menuButton.backgroundColor = .clear
          menuButton.isUserInteractionEnabled = true

          // Configure the menu for the button
          menuButton.menu = menu
          menuButton.showsMenuAsPrimaryAction = true

          // Add button to the view
          topViewController.view.addSubview(menuButton)

          // Trigger the menu programmatically
          menuButton.sendActions(for: .menuActionTriggered)

          // Clean up after a short delay
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            menuButton.removeFromSuperview()
          }

          // Send event that menu is shown
          self.sendEvent("onMenuShown")
        } else {
          // Fallback for older iOS versions using UIAlertController
          let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

          self.addActionsToAlertController(alertController, from: items) { selectedId in
            continuation.resume(returning: selectedId)
          }

          alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            continuation.resume(returning: nil)
          })

          if let topController = self.getTopViewController() {
            topController.present(alertController, animated: true) {
              self.sendEvent("onMenuShown")
            }
          } else {
            continuation.resume(returning: nil)
          }
        }
      }
    }
  }

  private func createMenu(from items: [[String: Any]], onSelect: @escaping (String) -> Void) -> UIMenu? {
    if #available(iOS 14.0, *) {
      let menuElements = items.compactMap { item -> UIMenuElement? in
        guard let id = item["id"] as? String,
              let title = item["title"] as? String else {
          return nil
        }

        let disabled = item["disabled"] as? Bool ?? false
        let destructive = item["destructive"] as? Bool ?? false
        let icon = item["icon"] as? String

        // Check for children (submenu)
        if let children = item["children"] as? [[String: Any]], !children.isEmpty {
          // Recursively create submenu
          if let submenu = createMenu(from: children, onSelect: onSelect) {
            return UIMenu(title: title, image: icon != nil ? UIImage(systemName: icon!) : nil, children: submenu.children)
          }
        }

        // Create action
        var attributes: UIMenuElement.Attributes = []
        if disabled {
          attributes.insert(.disabled)
        }
        if destructive {
          attributes.insert(.destructive)
        }

        let action = UIAction(
          title: title,
          image: icon != nil ? UIImage(systemName: icon!) : nil,
          attributes: attributes
        ) { _ in
          if !disabled {
            onSelect(id)
            self.sendEvent("onMenuItemSelected", ["itemId": id])
          }
        }

        return action
      }

      return UIMenu(children: menuElements)
    }
    return nil
  }

  private func addActionsToAlertController(_ controller: UIAlertController, from items: [[String: Any]], onSelect: @escaping (String) -> Void) {
    for item in items {
      guard let id = item["id"] as? String,
            let title = item["title"] as? String else {
        continue
      }

      let disabled = item["disabled"] as? Bool ?? false
      let destructive = item["destructive"] as? Bool ?? false

      let style: UIAlertAction.Style = destructive ? .destructive : .default

      let action = UIAlertAction(title: title, style: style) { _ in
        onSelect(id)
        self.sendEvent("onMenuItemSelected", ["itemId": id])
      }

      action.isEnabled = !disabled
      controller.addAction(action)
    }
  }

  @MainActor
  private func dismissMenu() {
    currentMenuController?.dismiss(animated: true)
    currentMenuController = nil
    sendEvent("onMenuDismissed")
  }

  private func getTopViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first(where: { $0.isKeyWindow }),
          let rootViewController = window.rootViewController else {
      return nil
    }

    var topController = rootViewController
    while let presentedViewController = topController.presentedViewController {
      topController = presentedViewController
    }

    return topController
  }
}

// MARK: - Menu Delegate for iOS 14+

@available(iOS 14.0, *)
private class MenuDelegate: NSObject, UIContextMenuInteractionDelegate {
  let menu: UIMenu?
  let showPreview: Bool

  init(menu: UIMenu?, showPreview: Bool) {
    self.menu = menu
    self.showPreview = showPreview
  }

  func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(identifier: nil, previewProvider: showPreview ? {
      // Return a preview view controller if showPreview is enabled
      let previewController = UIViewController()
      previewController.view.backgroundColor = .systemBackground
      return previewController
    } : nil) { _ in
      return self.menu
    }
  }
}
