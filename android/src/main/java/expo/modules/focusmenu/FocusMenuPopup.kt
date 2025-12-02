package expo.modules.focusmenu

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Outline
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.view.animation.OvershootInterpolator
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import expo.modules.focusmenu.models.FocusMenuItem
import kotlin.math.roundToInt

/**
 * A native PopupWindow-based menu that displays menu items and reactions.
 * Uses only first-party Android APIs to match the iOS UIContextMenuInteraction approach.
 */
class FocusMenuPopup(
    private val context: Context,
    private val anchorView: View,
    private val items: List<FocusMenuItem>,
    private val reactions: List<String>?,
    private val hapticFeedback: Boolean,
    private val onItemPress: (String) -> Unit,
    private val onReactionPress: ((String, Boolean) -> Unit)?,
    private val onMenuShow: (() -> Unit)?,
    private val onMenuDismiss: (() -> Unit)?
) {
    private var popupWindow: PopupWindow? = null
    private var dimOverlay: View? = null
    private var selectedReaction: String? = null

    // Design tokens (matching iOS)
    private val cornerRadiusDp = 14
    private val paddingDp = 16
    private val itemVerticalPaddingDp = 12
    private val minWidthDp = 250
    private val iconSizeDp = 22
    private val reactionSizeDp = 36
    private val elevationDp = 24f

    // Colors
    private val surfaceColor = Color.WHITE
    private val onSurfaceColor = Color.parseColor("#1C1C1E")
    private val onSurfaceSecondaryColor = Color.parseColor("#8E8E93")
    private val destructiveColor = Color.parseColor("#FF3B30")
    private val dividerColor = Color.parseColor("#E5E5EA")
    private val scrimColor = Color.parseColor("#4D000000")

    fun show() {
        if (popupWindow?.isShowing == true) return

        if (hapticFeedback) {
            anchorView.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
        }

        val contentView = buildPopupContent()

        popupWindow = PopupWindow(
            contentView,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            true
        ).apply {
            elevation = dpToPx(elevationDp.toInt()).toFloat()
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            isOutsideTouchable = true
            isTouchable = true
            setOnDismissListener {
                removeScrim()
                onMenuDismiss?.invoke()
            }
        }

        showScrim()

        // Measure for positioning
        contentView.measure(
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        )

        val (xOffset, yOffset, showAbove) = calculatePosition(contentView)

        // Set animation pivot based on position
        contentView.pivotX = contentView.measuredWidth / 2f
        contentView.pivotY = if (showAbove) contentView.measuredHeight.toFloat() else 0f

        // Initial state
        contentView.alpha = 0f
        contentView.scaleX = 0.92f
        contentView.scaleY = 0.92f

        popupWindow?.showAsDropDown(anchorView, xOffset, yOffset, Gravity.START or Gravity.TOP)

        // Animate in
        AnimatorSet().apply {
            playTogether(
                ObjectAnimator.ofFloat(contentView, View.ALPHA, 0f, 1f),
                ObjectAnimator.ofFloat(contentView, View.SCALE_X, 0.92f, 1f),
                ObjectAnimator.ofFloat(contentView, View.SCALE_Y, 0.92f, 1f)
            )
            duration = 250
            interpolator = OvershootInterpolator(0.8f)
            start()
        }

        onMenuShow?.invoke()
    }

    fun dismiss() {
        val contentView = popupWindow?.contentView ?: run {
            popupWindow?.dismiss()
            return
        }

        AnimatorSet().apply {
            playTogether(
                ObjectAnimator.ofFloat(contentView, View.ALPHA, 1f, 0f),
                ObjectAnimator.ofFloat(contentView, View.SCALE_X, 1f, 0.95f),
                ObjectAnimator.ofFloat(contentView, View.SCALE_Y, 1f, 0.95f)
            )
            duration = 180
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    popupWindow?.dismiss()
                }
            })
            start()
        }
    }

    private fun buildPopupContent(): LinearLayout {
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            minimumWidth = dpToPx(minWidthDp)
            background = createRoundedBackground(surfaceColor, dpToPx(cornerRadiusDp).toFloat())
            clipToOutline = true
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setRoundRect(
                        0, 0, view.width, view.height,
                        dpToPx(cornerRadiusDp).toFloat()
                    )
                }
            }
            elevation = dpToPx(8).toFloat()

            // Reactions bar (if provided)
            reactions?.takeIf { it.isNotEmpty() }?.let { emojiList ->
                addView(buildReactionsBar(emojiList))
                addView(buildDivider(fullWidth = true))
            }

            // Menu items
            items.forEachIndexed { index, item ->
                addView(buildMenuItemView(item))
                if (index < items.lastIndex) {
                    addView(buildDivider(fullWidth = false))
                }
            }
        }
    }

    private fun buildReactionsBar(emojis: List<String>): LinearLayout {
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dpToPx(12), dpToPx(12), dpToPx(12), dpToPx(12))

            emojis.forEach { emoji ->
                addView(buildReactionButton(emoji))
            }
        }
    }

    private fun buildReactionButton(emoji: String): TextView {
        val size = dpToPx(reactionSizeDp)
        return TextView(context).apply {
            text = emoji
            textSize = 22f
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                marginStart = dpToPx(4)
                marginEnd = dpToPx(4)
            }
            background = createCircularRipple()

            setOnClickListener { view ->
                if (hapticFeedback) {
                    view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                }

                val wasSelected = selectedReaction == emoji
                selectedReaction = if (wasSelected) null else emoji

                // Bounce animation
                AnimatorSet().apply {
                    playSequentially(
                        ObjectAnimator.ofFloat(view, View.SCALE_X, 1f, 1.3f).setDuration(100),
                        ObjectAnimator.ofFloat(view, View.SCALE_X, 1.3f, 1f).setDuration(100)
                    )
                    start()
                }
                AnimatorSet().apply {
                    playSequentially(
                        ObjectAnimator.ofFloat(view, View.SCALE_Y, 1f, 1.3f).setDuration(100),
                        ObjectAnimator.ofFloat(view, View.SCALE_Y, 1.3f, 1f).setDuration(100)
                    )
                    start()
                }

                onReactionPress?.invoke(emoji, !wasSelected)

                view.postDelayed({ dismiss() }, 200)
            }
        }
    }

    private fun buildMenuItemView(item: FocusMenuItem): LinearLayout {
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(
                dpToPx(paddingDp),
                dpToPx(itemVerticalPaddingDp),
                dpToPx(paddingDp),
                dpToPx(itemVerticalPaddingDp)
            )
            background = createRippleBackground()
            isEnabled = !item.disabled
            alpha = if (item.disabled) 0.38f else 1f
            isClickable = !item.disabled
            isFocusable = !item.disabled

            // Icon
            item.iconBitmap?.let { bitmap ->
                addView(ImageView(context).apply {
                    setImageBitmap(bitmap)
                    layoutParams = LinearLayout.LayoutParams(
                        dpToPx(iconSizeDp),
                        dpToPx(iconSizeDp)
                    ).apply {
                        marginEnd = dpToPx(12)
                    }
                    scaleType = ImageView.ScaleType.FIT_CENTER
                    if (item.destructive) {
                        setColorFilter(destructiveColor)
                    }
                })
            }

            // Title + Subtitle
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)

                addView(TextView(context).apply {
                    text = item.title
                    textSize = 17f
                    setTextColor(if (item.destructive) destructiveColor else onSurfaceColor)
                    includeFontPadding = false
                })

                item.subtitle?.let { sub ->
                    addView(TextView(context).apply {
                        text = sub
                        textSize = 13f
                        setTextColor(onSurfaceSecondaryColor)
                        includeFontPadding = false
                    })
                }
            })

            // Submenu chevron
            if (!item.children.isNullOrEmpty()) {
                addView(TextView(context).apply {
                    text = ">"
                    textSize = 18f
                    setTextColor(onSurfaceSecondaryColor)
                    setPadding(dpToPx(8), 0, 0, 0)
                })
            }

            if (!item.disabled) {
                setOnClickListener { view ->
                    if (hapticFeedback) {
                        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    }

                    if (!item.children.isNullOrEmpty()) {
                        showSubmenu(item.children, view)
                    } else {
                        onItemPress(item.id)
                        dismiss()
                    }
                }
            }
        }
    }

    private fun showSubmenu(children: List<FocusMenuItem>, anchor: View) {
        FocusMenuPopup(
            context = context,
            anchorView = anchor,
            items = children,
            reactions = null,
            hapticFeedback = hapticFeedback,
            onItemPress = { id ->
                onItemPress(id)
                dismiss() // Dismiss parent too
            },
            onReactionPress = null,
            onMenuShow = null,
            onMenuDismiss = null
        ).show()
    }

    private fun buildDivider(fullWidth: Boolean): View {
        return View(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dpToPx(1)
            ).apply {
                if (!fullWidth) {
                    marginStart = dpToPx(paddingDp)
                    marginEnd = dpToPx(paddingDp)
                }
            }
            setBackgroundColor(dividerColor)
        }
    }

    private fun calculatePosition(contentView: View): Triple<Int, Int, Boolean> {
        val location = IntArray(2)
        anchorView.getLocationOnScreen(location)

        val screenHeight = context.resources.displayMetrics.heightPixels
        val screenWidth = context.resources.displayMetrics.widthPixels

        val anchorX = location[0]
        val anchorY = location[1]
        val anchorWidth = anchorView.width
        val anchorHeight = anchorView.height
        val popupWidth = contentView.measuredWidth
        val popupHeight = contentView.measuredHeight

        val margin = dpToPx(8)

        // Vertical: prefer below, show above if not enough space
        val spaceBelow = screenHeight - (anchorY + anchorHeight)
        val showAbove = spaceBelow < popupHeight + margin && anchorY > popupHeight + margin

        val yOffset = if (showAbove) {
            -popupHeight - anchorHeight - margin
        } else {
            margin
        }

        // Horizontal: center on anchor, but keep on screen
        var xOffset = (anchorWidth - popupWidth) / 2
        val absoluteX = anchorX + xOffset

        if (absoluteX < margin) {
            xOffset = margin - anchorX
        } else if (absoluteX + popupWidth > screenWidth - margin) {
            xOffset = screenWidth - margin - popupWidth - anchorX
        }

        return Triple(xOffset, yOffset, showAbove)
    }

    private fun showScrim() {
        val rootView = anchorView.rootView as? ViewGroup ?: return

        dimOverlay = View(context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(scrimColor)
            alpha = 0f
            setOnClickListener { dismiss() }
        }

        rootView.addView(dimOverlay)

        ObjectAnimator.ofFloat(dimOverlay, View.ALPHA, 0f, 1f).apply {
            duration = 200
            start()
        }
    }

    private fun removeScrim() {
        dimOverlay?.let { view ->
            ObjectAnimator.ofFloat(view, View.ALPHA, 1f, 0f).apply {
                duration = 150
                addListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        (view.parent as? ViewGroup)?.removeView(view)
                    }
                })
                start()
            }
        }
        dimOverlay = null
    }

    // --- Drawing helpers ---

    private fun createRoundedBackground(color: Int, radius: Float): GradientDrawable {
        return GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius
        }
    }

    private fun createRippleBackground(): RippleDrawable {
        val rippleColor = ColorStateList.valueOf(Color.parseColor("#1F000000"))
        val mask = GradientDrawable().apply { setColor(Color.WHITE) }
        return RippleDrawable(rippleColor, null, mask)
    }

    private fun createCircularRipple(): RippleDrawable {
        val rippleColor = ColorStateList.valueOf(Color.parseColor("#1F000000"))
        val mask = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.WHITE)
        }
        return RippleDrawable(rippleColor, null, mask)
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * context.resources.displayMetrics.density).roundToInt()
    }
}
