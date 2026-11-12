package com.lagcheck.android.data

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.lagcheck.android.MainActivity
import com.lagcheck.android.R
import java.util.Calendar

/** Local-only reminder. It never starts a Check, uses the network, or emits telemetry. */
class PreMatchReminder(private val context: Context) {
    private val prefs = context.getSharedPreferences("lagcheck_prefs", Context.MODE_PRIVATE)
    val enabled get() = prefs.getBoolean("pre_match_reminder_enabled", false)
    val hour get() = prefs.getInt("pre_match_reminder_hour", 20)
    val minute get() = prefs.getInt("pre_match_reminder_minute", 0)
    val gameId get() = prefs.getString("pre_match_reminder_game", null)
    val permissionDenied get() = prefs.getBoolean("pre_match_reminder_permission_denied", false)
    val language get() = prefs.getString("pref_language", "Português (Brasil)") ?: "Português (Brasil)"
    fun schedule(gameId: String, hour: Int = this.hour, minute: Int = this.minute) {
        cancelAlarm()
        prefs.edit().putBoolean("pre_match_reminder_enabled", true).putString("pre_match_reminder_game", gameId).putInt("pre_match_reminder_hour", hour).putInt("pre_match_reminder_minute", minute).apply()
        alarmManager().setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextTrigger(hour, minute), alarmIntent())
    }
    fun cancel() { cancelAlarm(); prefs.edit().putBoolean("pre_match_reminder_enabled", false).remove("pre_match_reminder_game").apply() }
    fun markPermissionDenied() { cancel(); prefs.edit().putBoolean("pre_match_reminder_permission_denied", true).apply() }
    fun markPermissionGranted() { prefs.edit().putBoolean("pre_match_reminder_permission_denied", false).apply() }
    fun clearIfGameUnavailable(availableIds: Set<String>) { if (enabled && gameId !in availableIds) cancel() }
    private fun cancelAlarm() = alarmManager().cancel(alarmIntent())
    private fun alarmManager() = context.getSystemService(AlarmManager::class.java)
    private fun alarmIntent() = PendingIntent.getBroadcast(context, REQUEST_CODE, Intent(context, PreMatchReminderReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun nextTrigger(hour: Int, minute: Int) = Calendar.getInstance().run { set(Calendar.HOUR_OF_DAY, hour); set(Calendar.MINUTE, minute); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0); if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1); timeInMillis }
    companion object { const val REQUEST_CODE = 51051; const val CHANNEL_ID = "pre_match_reminder" }
}

class PreMatchReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val reminder = PreMatchReminder(context); val gameId = reminder.gameId ?: return
        val openApp = PendingIntent.getActivity(context, PreMatchReminder.REQUEST_CODE, Intent(context, MainActivity::class.java).putExtra(MainActivity.EXTRA_REMINDER_GAME_ID, gameId), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notifications = context.getSystemService(NotificationManager::class.java)
        notifications.createNotificationChannel(NotificationChannel(PreMatchReminder.CHANNEL_ID, "Pre-match reminder", NotificationManager.IMPORTANCE_DEFAULT))
        val copy = when {
            reminder.language.startsWith("English") -> "Playing now? Run a Check first."
            reminder.language.startsWith("Español") -> "¿Vas a jugar? Haz un Check antes."
            else -> "Vai jogar agora? Faça um Check antes."
        }
        notifications.notify(PreMatchReminder.REQUEST_CODE, NotificationCompat.Builder(context, PreMatchReminder.CHANNEL_ID).setSmallIcon(R.mipmap.ic_launcher).setContentTitle("LagCheck").setContentText(copy).setAutoCancel(true).setContentIntent(openApp).build())
        if (reminder.enabled) reminder.schedule(gameId, reminder.hour, reminder.minute)
    }
}
