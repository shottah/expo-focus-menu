package expo.modules.focusmenu

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import expo.modules.focusmenu.models.FocusMenuItem
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView

/**
 * A native view that wraps React Native children and provides a context menu on long press.
 * Extends ExpoView which automatically handles React Native child rendering.
 */
class ExpoFocusMenuView(
    context: Context,
    appContext: AppContext
) : ExpoView(context, appContext) {

    companion object {
        private const val TAG = "ExpoFocusMenuView"
    }

    // State
    private var menuItems: List<FocusMenuItem> = emptyList()
    private var reactions: List<String>? = null
    private var hapticFeedbackEnabled: Boolean = false
    private var currentPopup: FocusMenuPopup? = null
    private val iconBitmaps = mutableMapOf<String, Bitmap>()

    // Raw items from JS (before bitmap association)
    private var rawMenuItems: List<Map<String, Any>> = emptyList()

    // Event dispatchers - connect to JS callbacks
    val onItemPress by EventDispatcher()
    val onReactionPress by EventDispatcher()
    val onMenuShow by EventDispatcher()
    val onMenuDismiss by EventDispatcher()

    // Gesture detection for long press
    private val gestureDetector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
        override fun onLongPress(e: MotionEvent) {
            showFocusMenu()
        }
    }).apply {
        setIsLongpressEnabled(true)
    }

    init {
        // Enable touch handling on this ViewGroup
        isClickable = true
        isFocusable = true
        isLongClickable = true
    }

    /**
     * Intercept touch events to detect long press on children.
     * We intercept but don't consume, so children still receive touches.
     */
    override fun onInterceptTouchEvent(ev: MotionEvent): Boolean {
        gestureDetector.onTouchEvent(ev)
        // Return false to let children handle the touch
        // The gesture detector will still fire onLongPress
        return false
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        gestureDetector.onTouchEvent(event)
        return super.onTouchEvent(event)
    }

    // --- Props from JS ---

    fun setMenuItems(items: List<Map<String, Any?>>) {
        rawMenuItems = items.filterIsInstance<Map<String, Any>>()
        rebuildMenuItems()
    }

    fun setReactions(emojis: List<String>?) {
        reactions = emojis?.takeIf { it.isNotEmpty() }
    }

    fun configureHapticFeedback(enabled: Boolean) {
        hapticFeedbackEnabled = enabled
    }

    // --- Icon bitmap handling ---

    /**
     * Called when an icon bitmap is captured from the JS side.
     * Associates the bitmap with the menu item ID.
     */
    fun setIconBitmap(itemId: String, bitmap: Bitmap) {
        iconBitmaps[itemId] = bitmap
        rebuildMenuItems()
    }

    /**
     * Recursively finds a subview by its React Native tag.
     */
    private fun findViewByTag(tag: Int, view: View? = null): View? {
        val searchView = view ?: this

        if (searchView.id == tag) {
            return searchView
        }

        if (searchView.tag is Int && searchView.tag == tag) {
            return searchView
        }

        if (searchView is ViewGroup) {
            for (i in 0 until searchView.childCount) {
                val found = findViewByTag(tag, searchView.getChildAt(i))
                if (found != null) {
                    return found
                }
            }
        }

        return null
    }

    /**
     * Snapshots a view to a Bitmap.
     */
    private fun snapshotView(view: View): Bitmap? {
        if (view.width <= 0 || view.height <= 0) {
            return null
        }

        val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        view.draw(canvas)

        return bitmap
    }

    /**
     * Prepares icon snapshots for all menu items with iconViewTag.
     */
    private fun prepareIconSnapshots() {
        fun processItems(items: List<Map<String, Any>>) {
            for (item in items) {
                val itemId = item["id"] as? String ?: continue
                val viewTag = (item["iconViewTag"] as? Number)?.toInt() ?: continue

                val iconView = findViewByTag(viewTag)
                if (iconView != null) {
                    val bitmap = snapshotView(iconView)
                    if (bitmap != null) {
                        iconBitmaps[itemId] = bitmap
                    }
                }

                @Suppress("UNCHECKED_CAST")
                val children = item["children"] as? List<Map<String, Any>>
                if (children != null) {
                    processItems(children)
                }
            }
        }

        processItems(rawMenuItems)
        rebuildMenuItems()
    }

    private fun parseMenuItem(map: Map<String, Any?>): FocusMenuItem {
        val id = map["id"] as? String ?: ""
        @Suppress("UNCHECKED_CAST")
        val children = (map["children"] as? List<*>)
            ?.filterIsInstance<Map<String, Any?>>()
            ?.map { parseMenuItem(it) }

        return FocusMenuItem(
            id = id,
            title = map["title"] as? String ?: "",
            subtitle = map["subtitle"] as? String,
            iconBitmap = iconBitmaps[id],
            destructive = map["destructive"] as? Boolean ?: false,
            disabled = map["disabled"] as? Boolean ?: false,
            children = children?.takeIf { it.isNotEmpty() }
        )
    }

    private fun rebuildMenuItems() {
        menuItems = rawMenuItems.map { parseMenuItem(it) }
    }

    // --- Menu display ---

    private fun showFocusMenu() {
        if (rawMenuItems.isEmpty() && reactions.isNullOrEmpty()) return
        if (currentPopup != null) return // Already showing

        // Snapshot icons before showing menu
        prepareIconSnapshots()

        // Anchor to this view (which contains the RN children)
        val anchorView: View = this

        currentPopup = FocusMenuPopup(
            context = context,
            anchorView = anchorView,
            items = menuItems,
            reactions = reactions,
            hapticFeedback = hapticFeedbackEnabled,
            onItemPress = { itemId ->
                onItemPress(mapOf("itemId" to itemId))
            },
            onReactionPress = { emoji, selected ->
                onReactionPress(mapOf(
                    "emoji" to emoji,
                    "selected" to selected
                ))
            },
            onMenuShow = {
                onMenuShow(emptyMap<String, Any>())
            },
            onMenuDismiss = {
                onMenuDismiss(emptyMap<String, Any>())
                currentPopup = null
            }
        )

        currentPopup?.show()
    }

    fun dismissMenu() {
        currentPopup?.dismiss()
        currentPopup = null
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        dismissMenu()
    }
}
