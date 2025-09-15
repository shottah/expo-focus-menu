package expo.modules.focusmenu

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.ContextMenu
import android.view.Gravity
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView

class ExpoFocusMenuView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
    companion object {
        private const val TAG = "ExpoFocusMenuView"
    }

    // Event dispatchers
    private val onItemPress by EventDispatcher()
    private val onMenuShow by EventDispatcher()
    private val onMenuDismiss by EventDispatcher()
    private val onReactionPress by EventDispatcher()

    // Properties from JS
    var menuItems: List<Map<String, Any>> = emptyList()
    // Removed triggerMode - always use long press like iOS
    var hapticFeedback: Boolean = false
    var reactions: List<String> = emptyList()
        set(value) {
            field = value
            // Log.d(TAG, "Reactions updated: ${field.size} items")
            emojiPickerAdapter?.updateEmojis(field)
        }

    // Internal state
    private var selectedEmoji: String? = null
    private var emojiPickerWindow: PopupWindow? = null
    private var emojiPickerAdapter: EmojiPickerAdapter? = null
    private var contextMenuView: View? = null
    private var menuItemIdMap = mutableMapOf<Int, String>()
    private var menuItemCounter = 1

    init {
        // Set up the view
        isClickable = true
        isFocusable = true

        // Register for context menu
        setOnCreateContextMenuListener { menu, _, _ ->
            createContextMenu(menu)
        }

        // Only long press triggers the menu (like iOS)
        setOnLongClickListener {
            if (hapticFeedback) provideHapticFeedback()
            showContextMenu()
            // Show emoji picker if reactions are provided
            if (reactions.isNotEmpty()) {
                showEmojiPicker()
            }
            true
        }
    }

    // Removed updateTriggerMode - always use long press

    private fun createContextMenu(menu: ContextMenu) {
        menu.clear()
        menuItemIdMap.clear()
        menuItemCounter = 1

        // Add menu items with support for single-level nesting
        for (item in menuItems) {
            val id = item["id"] as? String ?: continue
            val title = item["title"] as? String ?: continue
            val subtitle = item["subtitle"] as? String
            val disabled = item["disabled"] as? Boolean ?: false
            val destructive = item["destructive"] as? Boolean ?: false
            val icon = item["icon"] as? String
            val children = item["children"] as? List<Map<String, Any>>

            // Combine title and subtitle if present
            val displayTitle = if (subtitle != null) {
                "$title\n$subtitle"
            } else {
                title
            }

            if (!children.isNullOrEmpty()) {
                // Create submenu for nested items (only 1 level deep like iOS)
                val subMenu = menu.addSubMenu(0, Menu.NONE, menuItemCounter, title)
                menuItemCounter++

                // Add children to submenu
                for (child in children) {
                    val childId = child["id"] as? String ?: continue
                    val childTitle = child["title"] as? String ?: continue
                    val childDisabled = child["disabled"] as? Boolean ?: false

                    val childMenuItem = subMenu.add(0, menuItemCounter, 0, childTitle)
                    menuItemIdMap[menuItemCounter] = childId
                    menuItemCounter++
                    childMenuItem.isEnabled = !childDisabled
                }
            } else {
                // Regular menu item
                val menuItem = menu.add(0, menuItemCounter, 0, displayTitle)
                menuItemIdMap[menuItemCounter] = id
                menuItemCounter++

                // Set enabled state
                menuItem.isEnabled = !disabled

                // Add icon if available
                if (icon != null) {
                    val iconResource = getIconResource(icon)
                    if (iconResource != 0) {
                        menuItem.setIcon(iconResource)
                    }
                }
            }
        }

        onMenuShow(emptyMap())
    }

    override fun onContextItemSelected(item: MenuItem): Boolean {
        val itemId = menuItemIdMap[item.itemId]
        if (itemId != null) {
            onItemPress(mapOf("itemId" to itemId))
            return true
        }
        return super.onContextItemSelected(item)
    }

    override fun onContextMenuClosed(menu: ContextMenu) {
        super.onContextMenuClosed(menu)
        onMenuDismiss(emptyMap())
        hideEmojiPicker()
    }

    private fun showEmojiPicker() {
        if (emojiPickerWindow?.isShowing == true) return

        val context = context ?: return

        // Create emoji picker view
        val pickerView = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(24, 16, 24, 16)

            // Apply default dark background style
            val backgroundDrawable = GradientDrawable().apply {
                setColor(Color.parseColor("#333333"))
                cornerRadius = 56f * resources.displayMetrics.density
            }
            background = backgroundDrawable
            alpha = 0.95f
        }

        // Create RecyclerView for emojis
        val recyclerView = RecyclerView(context).apply {
            layoutManager = LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false)

            val adapter = EmojiPickerAdapter(
                emojis = reactions,  // Use only the reactions provided from React Native
                selectedEmoji = selectedEmoji,
                onEmojiClick = { emoji ->
                    handleEmojiSelection(emoji)
                }
            )
            this@ExpoFocusMenuView.emojiPickerAdapter = adapter
            this.adapter = adapter
        }

        pickerView.addView(recyclerView, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        // Create popup window
        emojiPickerWindow = PopupWindow(pickerView).apply {
            width = ViewGroup.LayoutParams.WRAP_CONTENT
            height = ViewGroup.LayoutParams.WRAP_CONTENT
            isFocusable = false
            isOutsideTouchable = false
            elevation = 8f
        }

        // Show above or below the view
        val location = IntArray(2)
        getLocationOnScreen(location)
        val screenHeight = resources.displayMetrics.heightPixels
        val spaceBelow = screenHeight - (location[1] + height)

        if (spaceBelow > 200) {
            // Show below
            emojiPickerWindow?.showAtLocation(
                this,
                Gravity.NO_GRAVITY,
                location[0],
                location[1] + height + 20
            )
        } else {
            // Show above
            emojiPickerWindow?.showAtLocation(
                this,
                Gravity.NO_GRAVITY,
                location[0],
                location[1] - 120
            )
        }
    }

    private fun hideEmojiPicker() {
        emojiPickerWindow?.dismiss()
        emojiPickerWindow = null
    }

    private fun handleEmojiSelection(emoji: String) {
        if (selectedEmoji == emoji) {
            // Deselect
            selectedEmoji = null
            onReactionPress(mapOf("emoji" to "", "selected" to false))
        } else {
            // Select
            selectedEmoji = emoji
            onReactionPress(mapOf("emoji" to emoji, "selected" to true))
        }

        // Update adapter
        emojiPickerAdapter?.selectedEmoji = selectedEmoji
        emojiPickerAdapter?.notifyDataSetChanged()

        // Keep picker visible (don't hide)
    }

    private fun provideHapticFeedback() {
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

    private fun getIconResource(iconName: String): Int {
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

}

// Adapter for emoji picker
private class EmojiPickerAdapter(
    private var emojis: List<String>,
    var selectedEmoji: String?,
    private val onEmojiClick: (String) -> Unit
) : RecyclerView.Adapter<EmojiPickerAdapter.EmojiViewHolder>() {

    fun updateEmojis(newEmojis: List<String>) {
        emojis = newEmojis
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): EmojiViewHolder {
        val textView = TextView(parent.context).apply {
            textSize = 24f
            gravity = Gravity.CENTER
            setPadding(16, 8, 16, 8)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        return EmojiViewHolder(textView)
    }

    override fun onBindViewHolder(holder: EmojiViewHolder, position: Int) {
        val emoji = emojis[position]
        holder.bind(emoji, emoji == selectedEmoji)
        holder.itemView.setOnClickListener { onEmojiClick(emoji) }
    }

    override fun getItemCount() = emojis.size

    class EmojiViewHolder(private val textView: TextView) : RecyclerView.ViewHolder(textView) {
        fun bind(emoji: String, isSelected: Boolean) {
            textView.text = emoji

            if (isSelected) {
                val backgroundDrawable = GradientDrawable().apply {
                    setColor(Color.parseColor("#FFFFFF"))
                    cornerRadius = 15f * textView.resources.displayMetrics.density
                }
                textView.background = backgroundDrawable
                textView.scaleX = 1.1f
                textView.scaleY = 1.1f
            } else {
                textView.background = null
                textView.scaleX = 1.0f
                textView.scaleY = 1.0f
            }
        }
    }
}