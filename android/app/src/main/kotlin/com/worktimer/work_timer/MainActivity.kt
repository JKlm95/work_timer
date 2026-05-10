package com.worktimer.work_timer

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private val channelName = "work_timer/service_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val workspaceId = call.argument<String>("workspaceId") ?: "default"
                        val workspaceName = call.argument<String>("workspaceName") ?: "Domyslny"
                        val nextMode = call.argument<String>("nextSessionMode") ?: "office"
                        val intent = Intent(this, WorkTimerForegroundService::class.java).apply {
                            action = WorkTimerForegroundService.ACTION_PLAY
                            putExtra(WorkTimerForegroundService.EXTRA_WORKSPACE_ID, workspaceId)
                            putExtra(WorkTimerForegroundService.EXTRA_WORKSPACE_NAME, workspaceName)
                            putExtra(WorkTimerForegroundService.EXTRA_NEXT_MODE, nextMode)
                        }
                        startService(intent)
                        result.success(true)
                    }

                    "pause" -> {
                        startService(
                            Intent(this, WorkTimerForegroundService::class.java).apply {
                                action = WorkTimerForegroundService.ACTION_PAUSE
                            },
                        )
                        result.success(true)
                    }

                    "stop" -> {
                        startService(
                            Intent(this, WorkTimerForegroundService::class.java).apply {
                                action = WorkTimerForegroundService.ACTION_STOP
                            },
                        )
                        result.success(true)
                    }

                    "sync" -> {
                        val runState = call.argument<String>("runState") ?: "idle"
                        val elapsedSeconds = call.argument<Int>("elapsedSeconds") ?: 0
                        val workspaceId = call.argument<String>("workspaceId") ?: "default"
                        val workspaceName = call.argument<String>("workspaceName") ?: "Domyslny"
                        val nextMode = call.argument<String>("nextSessionMode") ?: "office"
                        startService(
                            Intent(this, WorkTimerForegroundService::class.java).apply {
                                action = WorkTimerForegroundService.ACTION_SYNC
                                putExtra(WorkTimerForegroundService.EXTRA_RUN_STATE, runState)
                                putExtra(WorkTimerForegroundService.EXTRA_ELAPSED_SECONDS, elapsedSeconds)
                                putExtra(WorkTimerForegroundService.EXTRA_WORKSPACE_ID, workspaceId)
                                putExtra(WorkTimerForegroundService.EXTRA_WORKSPACE_NAME, workspaceName)
                                putExtra(WorkTimerForegroundService.EXTRA_NEXT_MODE, nextMode)
                            },
                        )
                        result.success(true)
                    }

                    "getNativeTimerSnapshot" -> {
                        result.success(WorkTimerForegroundService.getMirrorSnapshot())
                    }

                    "syncWidgetWorkspaces" -> {
                        val json = call.argument<String>("workspacesJson") ?: "[]"
                        val selectedId =
                            call.argument<String>("selectedWorkspaceId") ?: "default"
                        val prefs =
                            getSharedPreferences(WorkTimerForegroundService.PREFS_HOME_WIDGET, MODE_PRIVATE)
                        var nameForSelected =
                            prefs.getString("workspaceName", "Domyslny") ?: "Domyslny"
                        runCatching {
                            val arr = JSONArray(json)
                            for (i in 0 until arr.length()) {
                                val o = arr.optJSONObject(i) ?: continue
                                if (o.optString("id") == selectedId) {
                                    nameForSelected = o.optString("name", nameForSelected)
                                    break
                                }
                            }
                        }
                        prefs.edit().apply {
                            putString(WorkspaceListStore.KEY_WORKSPACES_JSON, json)
                            putString("activeWorkspaceId", selectedId)
                            putString("workspaceName", nameForSelected)
                            apply()
                        }
                        WorkTimerWidgetUi.requestUpdate(this)
                        result.success(true)
                    }

                    "getWidgetWorkspaceSelection" -> {
                        val prefs =
                            getSharedPreferences(WorkTimerForegroundService.PREFS_HOME_WIDGET, MODE_PRIVATE)
                        result.success(
                            mapOf(
                                "activeWorkspaceId" to (prefs.getString("activeWorkspaceId", "default") ?: "default"),
                                "workspaceName" to (prefs.getString("workspaceName", "") ?: ""),
                            ),
                        )
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
