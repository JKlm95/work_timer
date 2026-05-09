package com.worktimer.work_timer

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
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
            if (!AuthPrefs.isSignedIn(context)) {
                views.setTextViewText(R.id.widgetWorkspace, context.getString(R.string.app_name))
                views.setTextViewText(
                    R.id.widgetTimer,
                    context.getString(R.string.widget_locked_placeholder),
                )
                views.setTextViewText(
                    R.id.widgetState,
                    context.getString(R.string.widget_sign_in_hint),
                )
                val openApp = AuthPrefs.openAppPendingIntent(context, 190)
                views.setOnClickPendingIntent(R.id.widgetPlay, openApp)
                views.setOnClickPendingIntent(R.id.widgetPause, openApp)
                views.setOnClickPendingIntent(R.id.widgetStop, openApp)
            } else {
                val workspace = widgetData.getString("workspaceName", "Domyslny") ?: "Domyslny"
                val workspaceId = widgetData.getString("activeWorkspaceId", "default") ?: "default"
                val nextSessionMode = widgetData.getString("nextSessionMode", "office") ?: "office"
                val runState = widgetData.getString("runState", "idle") ?: "idle"
                val elapsedSeconds = widgetData.getInt("elapsedSeconds", 0)
                val elapsed = formatElapsed(elapsedSeconds)

                views.setTextViewText(R.id.widgetWorkspace, workspace)
                views.setTextViewText(R.id.widgetTimer, elapsed)
                views.setTextViewText(R.id.widgetState, runState)

                views.setOnClickPendingIntent(
                    R.id.widgetPlay,
                    pendingIntent(
                        context,
                        WorkTimerForegroundService.ACTION_PLAY,
                        101,
                        workspaceId,
                        workspace,
                        nextSessionMode,
                    ),
                )
                views.setOnClickPendingIntent(
                    R.id.widgetPause,
                    pendingIntent(
                        context,
                        WorkTimerForegroundService.ACTION_PAUSE,
                        102,
                        workspaceId,
                        workspace,
                        nextSessionMode,
                    ),
                )
                views.setOnClickPendingIntent(
                    R.id.widgetStop,
                    pendingIntent(
                        context,
                        WorkTimerForegroundService.ACTION_STOP,
                        103,
                        workspaceId,
                        workspace,
                        nextSessionMode,
                    ),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun pendingIntent(
        context: Context,
        action: String,
        code: Int,
        workspaceId: String,
        workspaceName: String,
        nextSessionMode: String,
    ): PendingIntent {
        val intent = Intent(context, WorkTimerForegroundService::class.java).apply {
            this.action = action
            putExtra(WorkTimerForegroundService.EXTRA_WORKSPACE_ID, workspaceId)
            putExtra(WorkTimerForegroundService.EXTRA_WORKSPACE_NAME, workspaceName)
            putExtra(WorkTimerForegroundService.EXTRA_NEXT_MODE, nextSessionMode)
        }
        return PendingIntent.getService(
            context,
            code,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun formatElapsed(totalSeconds: Int): String {
        val h = totalSeconds / 3600
        val m = (totalSeconds % 3600) / 60
        val s = totalSeconds % 60
        return String.format("%02d:%02d:%02d", h, m, s)
    }
}
