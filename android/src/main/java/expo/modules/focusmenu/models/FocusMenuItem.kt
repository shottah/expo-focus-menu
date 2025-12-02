package expo.modules.focusmenu.models

import android.graphics.Bitmap

/**
 * Represents a menu item with all its properties.
 * Icons are stored as Bitmaps captured from React Native views.
 */
data class FocusMenuItem(
    val id: String,
    val title: String,
    val subtitle: String? = null,
    val iconBitmap: Bitmap? = null,
    val destructive: Boolean = false,
    val disabled: Boolean = false,
    val children: List<FocusMenuItem>? = null
)
