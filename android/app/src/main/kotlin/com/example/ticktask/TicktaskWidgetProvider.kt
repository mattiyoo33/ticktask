package com.example.ticktask

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * Home screen widget that displays text from the Flutter app (e.g. "test-widgets").
 * Data is stored by the home_widget plugin in HomeWidgetPreferences.
 */
class TicktaskWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val text = prefs.getString(KEY_WIDGET_TEXT, DEFAULT_TEXT) ?: DEFAULT_TEXT

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.ticktask_widget)
            views.setTextViewText(R.id.widget_text, text)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    companion object {
        private const val PREFERENCES = "HomeWidgetPreferences"
        private const val KEY_WIDGET_TEXT = "widget_text"
        private const val DEFAULT_TEXT = "test-widgets"
    }
}
