package com.worktimer.work_timer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.max

class WorkTimerForegroundService : Service() {
    companion object {
        const val ACTION_PLAY = "com.worktimer.work_timer.action.PLAY"
        const val ACTION_PAUSE = "com.worktimer.work_timer.action.PAUSE"
        const val ACTION_STOP = "com.worktimer.work_timer.action.STOP"
        const val ACTION_SYNC = "com.worktimer.work_timer.action.SYNC"
        const val ACTION_PREVIOUS_WORKSPACE = "com.worktimer.work_timer.action.PREVIOUS_WORKSPACE"
        const val ACTION_NEXT_WORKSPACE = "com.worktimer.work_timer.action.NEXT_WORKSPACE"
        const val EXTRA_WORKSPACE_ID = "workspaceId"
        const val EXTRA_WORKSPACE_NAME = "workspaceName"
        const val EXTRA_NEXT_MODE = "nextSessionMode"
        const val EXTRA_ELAPSED_SECONDS = "elapsedSeconds"
        const val EXTRA_RUN_STATE = "runState"

        private const val CHANNEL_ID = "work_timer_channel"
        private const val NOTIFICATION_ID = 61234
        const val PREFS_HOME_WIDGET = "HomeWidgetPreferences"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val TIMER_SESSION_KEY = "flutter.timer_session_v1"
        private const val TAG = "WorkTimerService"

        @Volatile
        private var mirrorRunState: String = "idle"

        @Volatile
        private var mirrorElapsedSeconds: Int = 0

        @Volatile
        private var mirrorWorkspaceId: String = "default"

        @Volatile
        private var mirrorWorkspaceName: String = "Domyslny"

        @Volatile
        private var mirrorSessionMode: String = "office"

        fun publishMirrorForFlutter(
            runState: String,
            elapsedSeconds: Int,
            workspaceId: String,
            workspaceName: String,
            sessionMode: String,
        ) {
            mirrorRunState = runState
            mirrorElapsedSeconds = elapsedSeconds
            mirrorWorkspaceId = workspaceId
            mirrorWorkspaceName = workspaceName
            mirrorSessionMode = sessionMode
        }

        fun getMirrorSnapshot(): Map<String, Any> {
            return mapOf(
                "runState" to mirrorRunState,
                "elapsedSeconds" to mirrorElapsedSeconds,
                "workspaceId" to mirrorWorkspaceId,
                "workspaceName" to mirrorWorkspaceName,
                "sessionMode" to mirrorSessionMode,
            )
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var ticker: Runnable? = null

    private var runState: String = "idle"
    private var elapsedSeconds: Int = 0
    private var workspaceId: String = "default"
    private var workspaceName: String = "Domyslny"
    private var sessionMode: String = "office"
    private var sessionStartIso: String = isoNow()
    private var resumeAtMs: Long? = null
    private var accumulatedMs: Long = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand action=${intent?.action}")
        val action = intent?.action
        if (!AuthPrefs.isSignedIn(this) && isTimerOrWorkspaceAction(action)) {
            startActivity(
                Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                },
            )
            stopSelf()
            return START_NOT_STICKY
        }
        when (action) {
            ACTION_PREVIOUS_WORKSPACE -> {
                handleWorkspaceStep(next = false)
                return finishIfWorkspaceOnlyIntent()
            }
            ACTION_NEXT_WORKSPACE -> {
                handleWorkspaceStep(next = true)
                return finishIfWorkspaceOnlyIntent()
            }
            ACTION_PLAY -> handlePlay(intent!!)
            ACTION_PAUSE -> handlePause()
            ACTION_STOP -> handleStop()
            ACTION_SYNC -> handleSync(intent)
            else -> handleSync(intent)
        }
        return START_STICKY
    }

    private fun isTimerOrWorkspaceAction(action: String?): Boolean {
        return action == ACTION_PLAY ||
            action == ACTION_PAUSE ||
            action == ACTION_STOP ||
            action == ACTION_PREVIOUS_WORKSPACE ||
            action == ACTION_NEXT_WORKSPACE
    }

    private fun finishIfWorkspaceOnlyIntent(): Int {
        if (runState != "idle" || ticker != null) {
            return START_STICKY
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        return START_NOT_STICKY
    }

    private fun handleWorkspaceStep(next: Boolean) {
        val homePrefs = getSharedPreferences(PREFS_HOME_WIDGET, MODE_PRIVATE)
        val prefState = (homePrefs.getString("runState", "idle") ?: "idle").lowercase()
        if (prefState == "running" || prefState == "paused") {
            WorkTimerWidgetUi.requestUpdate(this)
            return
        }
        if (runState == "running" || runState == "paused") {
            WorkTimerWidgetUi.requestUpdate(this)
            return
        }

        var list = WorkspaceListStore.readWorkspaces(homePrefs)
        val activeId = homePrefs.getString("activeWorkspaceId", "default") ?: "default"
        val activeName = homePrefs.getString("workspaceName", "") ?: ""
        if (list.isEmpty() && activeId.isNotEmpty()) {
            list = listOf(WorkspaceListStore.Entry(activeId, activeName.ifEmpty { activeId }))
        }
        if (list.size <= 1) {
            WorkTimerWidgetUi.requestUpdate(this)
            return
        }

        var idx = list.indexOfFirst { it.id == activeId }
        if (idx < 0) idx = 0
        val len = list.size
        val newIdx = if (next) {
            (idx + 1) % len
        } else {
            (idx - 1 + len) % len
        }
        val pick = list[newIdx]
        val mode = homePrefs.getString("nextSessionMode", sessionMode) ?: sessionMode
        homePrefs.edit().apply {
            putString("activeWorkspaceId", pick.id)
            putString("workspaceName", pick.name)
            apply()
        }
        workspaceId = pick.id
        workspaceName = pick.name
        val elapsed = homePrefs.getInt("elapsedSeconds", 0)
        publishMirrorForFlutter(
            "idle",
            elapsed,
            pick.id,
            pick.name,
            mode,
        )
        WorkTimerWidgetUi.requestUpdate(this)
    }

    override fun onDestroy() {
        stopTicker()
        super.onDestroy()
    }

    private fun handlePlay(intent: Intent) {
        val homePrefs = getSharedPreferences(PREFS_HOME_WIDGET, MODE_PRIVATE)
        workspaceId =
            intent.getStringExtra(EXTRA_WORKSPACE_ID)
                ?: homePrefs.getString("activeWorkspaceId", workspaceId)
                ?: workspaceId
        workspaceName =
            intent.getStringExtra(EXTRA_WORKSPACE_NAME)
                ?: homePrefs.getString("workspaceName", workspaceName)
                ?: workspaceName
        sessionMode =
            intent.getStringExtra(EXTRA_NEXT_MODE)
                ?: homePrefs.getString("nextSessionMode", sessionMode)
                ?: sessionMode
        if (runState == "idle") {
            runState = "running"
            sessionStartIso = isoNow()
            accumulatedMs = 0L
            elapsedSeconds = 0
            resumeAtMs = System.currentTimeMillis()
        } else if (runState == "paused") {
            runState = "running"
            resumeAtMs = System.currentTimeMillis()
        }
        logState("handlePlay")
        startForegroundWithNotification()
        startTicker()
        persistAndRender()
    }

    private fun handlePause() {
        if (runState != "running" || resumeAtMs == null) return
        val now = System.currentTimeMillis()
        accumulatedMs += now - (resumeAtMs ?: now)
        resumeAtMs = null
        elapsedSeconds = (accumulatedMs / 1000L).toInt()
        runState = "paused"
        logState("handlePause")
        startForegroundWithNotification()
        stopTicker()
        persistAndRender()
    }

    private fun handleStop() {
        if (runState == "idle") return
        if (runState == "running" && resumeAtMs != null) {
            val now = System.currentTimeMillis()
            accumulatedMs += now - (resumeAtMs ?: now)
        }
        val totalMs = accumulatedMs
        if (totalMs > 0L) {
            Log.d(TAG, "handleStop persisting entry totalMs=$totalMs")
            appendEntryToLocalQueue(totalMs)
        }

        runState = "idle"
        elapsedSeconds = 0
        accumulatedMs = 0L
        resumeAtMs = null
        logState("handleStop-beforeClear")
        persistAndRender()
        clearTimerSession()
        stopTicker()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun handleSync(intent: Intent?) {
        if (intent == null) return
        intent.getStringExtra(EXTRA_WORKSPACE_ID)?.let { workspaceId = it }
        intent.getStringExtra(EXTRA_WORKSPACE_NAME)?.let { workspaceName = it }
        intent.getStringExtra(EXTRA_NEXT_MODE)?.let { sessionMode = it }
        intent.getStringExtra(EXTRA_RUN_STATE)?.let { runState = it }
        val appliedElapsedSync = intent.hasExtra(EXTRA_ELAPSED_SECONDS)
        if (appliedElapsedSync) {
            elapsedSeconds = intent.getIntExtra(EXTRA_ELAPSED_SECONDS, elapsedSeconds)
            accumulatedMs = elapsedSeconds * 1000L
        }
        when (runState) {
            "running" -> {
                // Flutter sync is authoritative for elapsed at this instant; stale resumeAtMs
                // otherwise keeps counting from an old PLAY anchor (desync widget vs app).
                if (appliedElapsedSync || resumeAtMs == null) {
                    resumeAtMs = System.currentTimeMillis()
                }
            }
            "paused" -> {
                resumeAtMs = null
            }
            "idle" -> {
                resumeAtMs = null
                accumulatedMs = 0L
                elapsedSeconds = 0
            }
        }
        logState("handleSync")
        persistAndRender()
    }

    private fun startTicker() {
        stopTicker()
        ticker = object : Runnable {
            override fun run() {
                if (runState == "running" && resumeAtMs != null) {
                    val now = System.currentTimeMillis()
                    elapsedSeconds = ((accumulatedMs + (now - (resumeAtMs ?: now))) / 1000L).toInt()
                    Log.d(TAG, "ticker elapsed=${elapsedSeconds}s")
                    persistAndRender()
                    updateNotification()
                }
                handler.postDelayed(this, 1000L)
            }
        }
        handler.post(ticker!!)
    }

    private fun stopTicker() {
        ticker?.let { handler.removeCallbacks(it) }
        ticker = null
    }

    private fun startForegroundWithNotification() {
        createChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
    }

    private fun updateNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingOpen = PendingIntent.getActivity(
            this,
            1,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("Work Timer")
            .setContentText("$workspaceName • ${formatElapsed(elapsedSeconds)} • $runState")
            .setContentIntent(pendingOpen)
            .setOngoing(runState != "idle")
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Work Timer",
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }

    private fun persistAndRender() {
        Log.d(
            TAG,
            "persistAndRender state=$runState elapsed=${elapsedSeconds}s workspace=$workspaceId",
        )
        val homePrefs = getSharedPreferences(PREFS_HOME_WIDGET, MODE_PRIVATE).edit()
        homePrefs.putString("workspaceName", workspaceName)
        homePrefs.putString("runState", runState)
        homePrefs.putInt("elapsedSeconds", elapsedSeconds)
        homePrefs.putString("activeWorkspaceId", workspaceId)
        homePrefs.putString("nextSessionMode", sessionMode)
        homePrefs.apply()

        saveTimerSession()
        WorkTimerForegroundService.publishMirrorForFlutter(
            runState,
            elapsedSeconds,
            workspaceId,
            workspaceName,
            sessionMode,
        )
        WorkTimerWidgetUi.requestUpdate(this)
    }

    private fun saveTimerSession() {
        if (runState == "idle") return
        val resumeAtIso = if (runState == "running" && resumeAtMs != null) {
            isoFromMs(resumeAtMs!!)
        } else {
            null
        }
        val json = JSONObject()
            .put("runState", runState)
            .put("workspaceId", workspaceId)
            .put("sessionMode", sessionMode)
            .put("sessionStart", sessionStartIso)
            .put("accumulatedMs", max(accumulatedMs, 0L))
            .put("resumeAt", resumeAtIso ?: JSONObject.NULL)
            .toString()
        getSharedPreferences(FLUTTER_PREFS, MODE_PRIVATE)
            .edit()
            .putString(TIMER_SESSION_KEY, json)
            .apply()
        Log.d(TAG, "saveTimerSession state=$runState accumulatedMs=$accumulatedMs")
    }

    private fun clearTimerSession() {
        getSharedPreferences(FLUTTER_PREFS, MODE_PRIVATE)
            .edit()
            .remove(TIMER_SESSION_KEY)
            .apply()
        Log.d(TAG, "clearTimerSession")
    }

    private fun appendEntryToLocalQueue(totalMs: Long) {
        val startMs = parseIso(sessionStartIso) ?: System.currentTimeMillis()
        val endMs = startMs + totalMs
        val entry = JSONObject()
            .put("id", System.currentTimeMillis().toString())
            .put("workspaceId", workspaceId)
            .put("start", isoFromMs(startMs))
            .put("end", isoFromMs(endMs))
            .put("mode", sessionMode)
            .put("updatedAt", isoNow())
            .put("isDeleted", false)

        val prefs = getSharedPreferences(FLUTTER_PREFS, MODE_PRIVATE)
        val pendingKey = "flutter.work_entries_pending_v2_$workspaceId"
        val monthKey = "flutter.work_entries_current_month_v2_$workspaceId"

        fun appendToArray(key: String) {
            val raw = prefs.getString(key, "[]") ?: "[]"
            val arr = org.json.JSONArray(raw)
            arr.put(entry)
            prefs.edit().putString(key, arr.toString()).apply()
        }

        appendToArray(pendingKey)
        appendToArray(monthKey)
    }

    private fun formatElapsed(totalSeconds: Int): String {
        val h = totalSeconds / 3600
        val m = (totalSeconds % 3600) / 60
        val s = totalSeconds % 60
        return String.format("%02d:%02d:%02d", h, m, s)
    }

    private fun isoNow(): String = isoFromMs(System.currentTimeMillis())

    private fun isoFromMs(ms: Long): String {
        val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        fmt.timeZone = TimeZone.getTimeZone("UTC")
        return fmt.format(Date(ms))
    }

    private fun parseIso(value: String): Long? {
        return runCatching {
            val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            fmt.timeZone = TimeZone.getTimeZone("UTC")
            fmt.parse(value)?.time
        }.getOrNull()
    }

    private fun logState(prefix: String) {
        Log.d(
            TAG,
            "$prefix state=$runState elapsed=${elapsedSeconds}s accumulatedMs=$accumulatedMs workspace=$workspaceId resumeAtMs=$resumeAtMs",
        )
    }
}
