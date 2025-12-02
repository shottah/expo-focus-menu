package expo.modules.focusmenu

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoFocusMenuModule : Module() {
    override fun definition() = ModuleDefinition {
        Name("ExpoFocusMenu")

        // The native view component
        View(ExpoFocusMenuView::class) {
            // Events that fire back to JS
            Events(
                "onItemPress",
                "onReactionPress",
                "onMenuShow",
                "onMenuDismiss"
            )

            // Props from JS
            Prop("items") { view: ExpoFocusMenuView, items: List<Map<String, Any?>> ->
                view.setMenuItems(items)
            }

            Prop("reactions") { view: ExpoFocusMenuView, reactions: List<String>? ->
                view.setReactions(reactions)
            }

            Prop("hapticFeedback") { view: ExpoFocusMenuView, enabled: Boolean ->
                view.configureHapticFeedback(enabled)
            }
        }
    }
}
