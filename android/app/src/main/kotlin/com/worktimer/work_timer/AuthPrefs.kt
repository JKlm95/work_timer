package com.worktimer.work_timer

import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object AuthPrefs {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val AUTH_KEY = "flutter.auth_signed_in_for_native_v1"

    fun isSignedIn(context: Context): Boolean {
        val p = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return p.getString(AUTH_KEY, null) == "1"
    }

    fun openAppPendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
