package com.worktimer.work_timer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONException

/**
 * Jedno źródło budowania [RemoteViews] dla Work Timer widget (provider + serwis).
 */
object WorkTimerWidgetUi {
    fun requestUpdate(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, WorkTimerWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        val prefs = context.getSharedPreferences(
            WorkTimerForegroundService.PREFS_HOME_WIDGET,
            Context.MODE_PRIVATE,
        )
        ids.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.work_timer_widget)
            bind(views, context, prefs)
            manager.updateAppWidget(id, views)
        }
    }

    fun bind(views: RemoteViews, context: Context, prefs: android.content.SharedPreferences) {
        if (!AuthPrefs.isSignedIn(context)) {
            views.setTextViewText(R.id.widget_workspace_name, context.getString(R.string.app_name))
            views.setTextViewText(
                R.id.widgetTimer,
                context.getString(R.string.widget_locked_placeholder),
            )
            views.setTextViewText(
                R.id.widgetState,
                context.getString(R.string.widget_sign_in_hint),
            )
            views.setTextColor(
                R.id.widgetState,
                ContextCompat.getColor(context, R.color.widget_status_idle),
            )
            views.setViewVisibility(R.id.widget_workspace_prev, View.GONE)
            views.setViewVisibility(R.id.widget_workspace_next, View.GONE)
            val openApp = AuthPrefs.openAppPendingIntent(context, 190)
            views.setOnClickPendingIntent(R.id.widgetPlay, openApp)
            views.setOnClickPendingIntent(R.id.widgetPause, openApp)
            views.setOnClickPendingIntent(R.id.widgetStop, openApp)
            return
        }

        val parsed = WorkspaceListStore.readWorkspaces(prefs)
        val activeId = prefs.getString("activeWorkspaceId", "default") ?: "default"
        val activeName = prefs.getString("workspaceName", "") ?: ""

        val workspaces =
            if (parsed.isEmpty() && activeId.isNotEmpty()) {
                listOf(WorkspaceListStore.Entry(activeId, activeName.ifEmpty { activeId }))
            } else {
                parsed
            }

        val (displayName, effectiveId) =
            if (workspaces.isEmpty()) {
                Pair(
                    context.getString(R.string.widget_no_workspace),
                    activeId,
                )
            } else {
                val pick = workspaces.find { it.id == activeId } ?: workspaces[0]
                Pair(pick.name, pick.id)
            }

        val runState = (prefs.getString("runState", "idle") ?: "idle").lowercase()
        val elapsedSeconds = prefs.getInt("elapsedSeconds", 0)
        val nextSessionMode = prefs.getString("nextSessionMode", "office") ?: "office"

        views.setTextViewText(R.id.widget_workspace_name, displayName)
        views.setTextViewText(R.id.widgetTimer, formatElapsed(elapsedSeconds))
        views.setTextViewText(R.id.widgetState, statusLabel(context, runState))
        views.setTextColor(R.id.widgetState, statusColor(context, runState))

        val canSwitchWorkspace = runState == "idle"
        val multiple = workspaces.size > 1
        val showArrows = canSwitchWorkspace && multiple
        views.setViewVisibility(
            R.id.widget_workspace_prev,
            if (showArrows) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.widget_workspace_next,
            if (showArrows) View.VISIBLE else View.GONE,
        )

        val playPending =
            if (workspaces.isEmpty()) {
                AuthPrefs.openAppPendingIntent(context, 191)
            } else {
                svcIntent(
                    context,
                    WorkTimerForegroundService.ACTION_PLAY,
                    101,
                    effectiveId,
                    displayName,
                    nextSessionMode,
                )
            }

        views.setOnClickPendingIntent(R.id.widgetPlay, playPending)
        views.setOnClickPendingIntent(
            R.id.widgetPause,
            svcIntent(
                context,
                WorkTimerForegroundService.ACTION_PAUSE,
                102,
                effectiveId,
                displayName,
                nextSessionMode,
            ),
        )
        views.setOnClickPendingIntent(
            R.id.widgetStop,
            svcIntent(
                context,
                WorkTimerForegroundService.ACTION_STOP,
                103,
                effectiveId,
                displayName,
                nextSessionMode,
            ),
        )

        if (showArrows) {
            views.setOnClickPendingIntent(
                R.id.widget_workspace_prev,
                svcIntent(
                    context,
                    WorkTimerForegroundService.ACTION_PREVIOUS_WORKSPACE,
                    104,
                    effectiveId,
                    displayName,
                    nextSessionMode,
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_workspace_next,
                svcIntent(
                    context,
                    WorkTimerForegroundService.ACTION_NEXT_WORKSPACE,
                    105,
                    effectiveId,
                    displayName,
                    nextSessionMode,
                ),
            )
        }
    }

    private fun svcIntent(
        context: Context,
        action: String,
        code: Int,
        workspaceId: String,
        workspaceName: String,
        nextSessionMode: String,
    ): PendingIntent {
        val i = Intent(context, WorkTimerForegroundService::class.java).apply {
            this.action = action
            putExtra(WorkTimerForegroundService.EXTRA_WORKSPACE_ID, workspaceId)
            putExtra(WorkTimerForegroundService.EXTRA_WORKSPACE_NAME, workspaceName)
            putExtra(WorkTimerForegroundService.EXTRA_NEXT_MODE, nextSessionMode)
        }
        return PendingIntent.getService(
            context,
            code,
            i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun statusLabel(context: Context, runState: String): String {
        return when (runState) {
            "running" -> context.getString(R.string.widget_status_running)
            "paused" -> context.getString(R.string.widget_status_paused)
            else -> context.getString(R.string.widget_status_idle)
        }
    }

    private fun statusColor(context: Context, runState: String): Int {
        val resId = when (runState) {
            "running" -> R.color.widget_status_running
            "paused" -> R.color.widget_status_paused
            else -> R.color.widget_status_idle
        }
        return ContextCompat.getColor(context, resId)
    }

    private fun formatElapsed(totalSeconds: Int): String {
        val h = totalSeconds / 3600
        val m = (totalSeconds % 3600) / 60
        val s = totalSeconds % 60
        return String.format("%02d:%02d:%02d", h, m, s)
    }
}

internal object WorkspaceListStore {
    const val KEY_WORKSPACES_JSON = "widget_workspaces_json"

    data class Entry(val id: String, val name: String)

    fun readWorkspaces(prefs: android.content.SharedPreferences): List<Entry> {
        val raw = prefs.getString(KEY_WORKSPACES_JSON, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.optJSONObject(i) ?: continue
                    val id = o.optString("id", "")
                    val name = o.optString("name", "")
                    if (id.isNotEmpty()) {
                        add(Entry(id, name.ifEmpty { id }))
                    }
                }
            }
        } catch (_: JSONException) {
            emptyList()
        }
    }
}
