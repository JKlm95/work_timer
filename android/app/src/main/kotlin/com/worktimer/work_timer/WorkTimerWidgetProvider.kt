package com.worktimer.work_timer

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WorkTimerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.work_timer_widget)
            val workspace = widgetData.getString("workspaceName", "Domyslny") ?: "Domyslny"
            val runState = widgetData.getString("runState", "idle") ?: "idle"
            val elapsedSeconds = widgetData.getInt("elapsedSeconds", 0)
            val elapsed = formatElapsed(elapsedSeconds)

            views.setTextViewText(R.id.widgetWorkspace, workspace)
            views.setTextViewText(R.id.widgetTimer, elapsed)
            views.setTextViewText(R.id.widgetState, runState)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun formatElapsed(totalSeconds: Int): String {
        val h = totalSeconds / 3600
        val m = (totalSeconds % 3600) / 60
        val s = totalSeconds % 60
        return String.format("%02d:%02d:%02d", h, m, s)
    }
}
