package com.tapcare.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews

/**
 * TapCare home-screen widget.
 *
 * Reads the care snapshot written by the Flutter side via the `home_widget`
 * package and renders it with [RemoteViews]. Two layouts are supported and the
 * widget is resizable in both directions (`android:resizeMode` in
 * `tapcare_widget_info.xml`): the launcher picks the small or the large
 * layout from the size the user grants it.
 *
 * Data lives in the shared preferences file that `home_widget` writes:
 *   context.getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
 */
class TapCareWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREF_NAME = "HomeWidgetPreferences"
        const val OPEN_APP = "com.tapcare.app.OPEN_APP"

        /** Launcher cell width (dp) at which the large layout looks right. */
        private const val LARGE_WIDTH_DP = 250
        private const val LARGE_HEIGHT_DP = 110
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id))
        }
    }

    /** Redraw when the user resizes the widget. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle?
    ) {
        appWidgetManager.updateAppWidget(appWidgetId, buildViews(context, appWidgetManager, appWidgetId))
    }

    /** Re-render every placed instance — used after new data arrives. */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, TapCareWidgetProvider::class.java)
        )
        onUpdate(context, manager, ids)
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int
    ): RemoteViews {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        fun s(key: String, fallback: String = ""): String =
            prefs.getString(key, fallback) ?: fallback

        val hasNudge = s("has_nudge", "0") == "1"
        val unseen = s("unseen", "0") == "1"
        val partner = s("partner_name", "Buddy")
        val partnerEmoji = s("partner_emoji", "💛")

        val layoutRes =
            if (isLarge(manager, appWidgetId)) R.layout.tapcare_widget_large
            else R.layout.tapcare_widget_small

        val views = RemoteViews(context.packageName, layoutRes)

        views.setTextViewText(R.id.widget_partner, "$partnerEmoji $partner")
        views.setTextViewText(R.id.widget_meter, "${s("love_meter", "0")}%")
        views.setTextViewText(R.id.widget_streak, "${s("streak", "0")} 🔥")
        views.setTextViewText(R.id.widget_sent, s("sent", "0"))
        views.setTextViewText(R.id.widget_received, s("received", "0"))
        views.setTextViewText(R.id.widget_together, s("together", "Since today 💞"))
        views.setTextViewText(R.id.widget_quote, s("quote", "Care without words 💛"))

        // Latest nudge card — what the other person sent is what you see.
        views.setTextViewText(R.id.widget_latest_emoji, s("latest_emoji", "💗"))
        val latestText = s("latest_text", "")
        views.setTextViewText(
            R.id.widget_latest_text,
            when {
                !hasNudge -> "No nudge yet 💛"
                latestText.isEmpty() -> "Care sent 💛"
                latestText.length > 110 -> latestText.substring(0, 110) + "…"
                else -> latestText
            }
        )
        val latestTime = s("latest_time", "")
        val latestFrom = s("latest_from", "TapCare")
        views.setTextViewText(
            R.id.widget_latest_from,
            when {
                !hasNudge -> "Tap to send the first one"
                latestTime.isEmpty() -> latestFrom
                else -> "$latestFrom · $latestTime"
            }
        )

        // Soft glow ring when something is still waiting to be opened.
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (unseen) R.drawable.widget_bg_unseen else R.drawable.widget_bg
        )

        // Gentle reveal: RemoteViews plays these sequentially when the widget
        // appears or refreshes. A repeating ValueAnimator would leak here —
        // the provider only lives for the length of the broadcast.
        views.setFloat(R.id.widget_meter, "alpha", 0.4f)
        views.setFloat(R.id.widget_meter, "scaleX", 0.88f)
        views.setFloat(R.id.widget_meter, "scaleY", 0.88f)
        views.setFloat(R.id.widget_latest_row, "alpha", 0.3f)
        views.setFloat(R.id.widget_latest_row, "translationY", 24f)
        views.setFloat(R.id.widget_meter, "alpha", 1f)
        views.setFloat(R.id.widget_meter, "scaleX", 1f)
        views.setFloat(R.id.widget_meter, "scaleY", 1f)
        views.setFloat(R.id.widget_latest_row, "alpha", 1f)
        views.setFloat(R.id.widget_latest_row, "translationY", 0f)

        views.setViewVisibility(R.id.widget_latest_row, View.VISIBLE)

        val open = openAppIntent(context)
        views.setOnClickPendingIntent(R.id.widget_root, open)
        views.setOnClickPendingIntent(R.id.widget_meter, open)

        return views
    }

    private fun isLarge(manager: AppWidgetManager, appWidgetId: Int): Boolean {
        val opts = manager.getAppWidgetOptions(appWidgetId)
        val minWidth = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return minWidth >= LARGE_WIDTH_DP || minHeight >= LARGE_HEIGHT_DP
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent(Intent.ACTION_MAIN)
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        launch.putExtra(OPEN_APP, true)

        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getActivity(context, 0, launch, flags)
    }
}
