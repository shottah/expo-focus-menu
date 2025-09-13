package expo.modules.focusmenu

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.PopupMenu
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.Promise
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ExpoFocusMenuModule : Module() {
  private var currentPopupMenu: PopupMenu? = null
  private var menuItemCallbacks = mutableMapOf<String, (String) -> Unit>()

  override fun definition() = ModuleDefinition {
    Name("ExpoFocusMenu")

    // Define events that can be sent to JavaScript
    Events("onMenuItemSelected", "onMenuShown", "onMenuDismissed")

    // Show the native context menu
    AsyncFunction("showNativeMenu") { items: List<Map<String, Any>>, config: Map<String, Any>?, promise: Promise ->
      showMenu(items, config ?: emptyMap(), promise)
    }

    // Dismiss the currently visible menu
    AsyncFunction("dismissNativeMenu") {
      dismissMenu()
    }

    // Check if a menu is currently visible
    AsyncFunction("isNativeMenuVisible") {
      currentPopupMenu != null
    }

    // Set default configuration for menus
    AsyncFunction("setNativeMenuConfig") { config: Map<String, Any> ->
      // Store config for future use (could be stored in SharedPreferences)
    }

    // Export the native view
    View(ExpoFocusMenuView::class) {
      // Define props for the view
      Prop("items") { view, items: List<Map<String, Any>> ->
        view.menuItems = items
      }

      Prop("triggerMode") { view, mode: String ->
        view.triggerMode = mode
        view.updateTriggerMode()
      }

      Prop("showPreview") { view, show: Boolean ->
        view.showPreview = show
      }

      Prop("hapticFeedback") { view, enabled: Boolean ->
        view.hapticFeedback = enabled
      }

      Prop("showReactions") { view, show: Boolean ->
        view.showReactions = show
      }

      Prop("reactions") { view, emojis: List<String>? ->
        view.reactions = emojis ?: emptyList()
      }


      // Event handlers
      Events("onItemPress", "onMenuShow", "onMenuDismiss", "onReactionPress")
    }
  }

  private fun showMenu(items: List<Map<String, Any>>, config: Map<String, Any>, promise: Promise) {
    if (items.isEmpty()) {
      promise.reject("EMPTY_ITEMS", "Menu items cannot be empty", null)
      return
    }

    val context = appContext.currentActivity ?: appContext.reactContext ?: run {
      promise.reject("NO_ACTIVITY", "No current activity available", null)
      return
    }

    CoroutineScope(Dispatchers.Main).launch {
      try {
        // Find the root view of the current activity
        val rootView = context.window.decorView.findViewById<View>(android.R.id.content)

        // Create PopupMenu
        val popupMenu = PopupMenu(context, rootView)
        currentPopupMenu = popupMenu

        // Track menu item IDs to their string IDs
        val menuItemIdMap = mutableMapOf<Int, String>()
        var menuItemCounter = 1

        // Add items to the menu
        addItemsToMenu(popupMenu.menu, items, menuItemIdMap, menuItemCounter)

        // Handle haptic feedback
        val hapticFeedback = config["hapticFeedback"] as? Boolean ?: false
        if (hapticFeedback) {
          provideHapticFeedback(context)
        }

        // Set up menu item click listener
        var itemSelected = false
        popupMenu.setOnMenuItemClickListener { menuItem ->
          val itemId = menuItemIdMap[menuItem.itemId]
          if (itemId != null && menuItem.isEnabled) {
            itemSelected = true
            sendEvent("onMenuItemSelected", mapOf("itemId" to itemId))
            promise.resolve(itemId)
            currentPopupMenu = null
          }
          true
        }

        // Set up dismiss listener
        popupMenu.setOnDismissListener {
          if (!itemSelected) {
            promise.resolve(null)
          }
          sendEvent("onMenuDismissed", emptyMap())
          currentPopupMenu = null
        }

        // Show the menu
        popupMenu.show()
        sendEvent("onMenuShown", emptyMap())

      } catch (e: Exception) {
        promise.reject("MENU_ERROR", "Failed to show menu: ${e.message}", e)
        currentPopupMenu = null
      }
    }
  }

  private fun addItemsToMenu(
    menu: Menu,
    items: List<Map<String, Any>>,
    menuItemIdMap: MutableMap<Int, String>,
    startId: Int
  ): Int {
    var currentId = startId

    for (item in items) {
      val id = item["id"] as? String ?: continue
      val title = item["title"] as? String ?: continue
      val subtitle = item["subtitle"] as? String
      val disabled = item["disabled"] as? Boolean ?: false
      val destructive = item["destructive"] as? Boolean ?: false
      val icon = item["icon"] as? String
      val children = item["children"] as? List<Map<String, Any>>

      // Combine title and subtitle for display
      val displayTitle = if (subtitle != null) {
        "$title\n$subtitle"
      } else {
        title
      }

      if (children != null && children.isNotEmpty()) {
        // Create submenu
        val subMenu = menu.addSubMenu(displayTitle)

        // Add icon if available (only works on some Android versions)
        if (icon != null) {
          val iconResource = getIconResource(icon)
          if (iconResource != 0) {
            subMenu.setIcon(iconResource)
          }
        }

        // Recursively add children to submenu
        currentId = addItemsToMenu(subMenu, children, menuItemIdMap, currentId)
      } else {
        // Create regular menu item
        val menuItem = menu.add(Menu.NONE, currentId, Menu.NONE, displayTitle)
        menuItemIdMap[currentId] = id
        currentId++

        // Set enabled state
        menuItem.isEnabled = !disabled

        // Add icon if available
        if (icon != null) {
          val iconResource = getIconResource(icon)
          if (iconResource != 0) {
            menuItem.setIcon(iconResource)
          }
        }

        // Note: Android doesn't have a built-in "destructive" style like iOS
        // You could implement custom styling if needed
      }
    }

    return currentId
  }

  private fun getIconResource(iconName: String): Int {
    // Map common icon names to Android drawable resources
    return when (iconName) {
      "doc.on.doc", "copy" -> android.R.drawable.ic_menu_crop
      "doc.on.clipboard", "paste" -> android.R.drawable.ic_menu_edit
      "trash", "delete" -> android.R.drawable.ic_menu_delete
      "arrowshape.turn.up.left", "reply" -> android.R.drawable.ic_menu_revert
      "arrowshape.turn.up.right", "forward" -> android.R.drawable.ic_menu_send
      "share" -> android.R.drawable.ic_menu_share
      "edit" -> android.R.drawable.ic_menu_edit
      "search" -> android.R.drawable.ic_menu_search
      "add", "plus" -> android.R.drawable.ic_menu_add
      "close" -> android.R.drawable.ic_menu_close_clear_cancel
      "info" -> android.R.drawable.ic_menu_info_details
      "preferences", "settings" -> android.R.drawable.ic_menu_preferences
      "help" -> android.R.drawable.ic_menu_help
      else -> 0
    }
  }

  private fun provideHapticFeedback(context: Context) {
    val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    vibrator?.let {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        it.vibrate(VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE))
      } else {
        @Suppress("DEPRECATION")
        it.vibrate(10)
      }
    }
  }

  private fun dismissMenu() {
    currentPopupMenu?.dismiss()
    currentPopupMenu = null
  }
}