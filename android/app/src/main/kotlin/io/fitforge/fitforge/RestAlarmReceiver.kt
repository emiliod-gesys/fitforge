package io.fitforge.fitforge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build

/**
 * Muestra el fin del descanso aunque el proceso de Flutter esté congelado.
 * Samsung aplaza las alarmas inexactas del plugin; esta la dispara AlarmManager.
 */
class RestAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(RestAlarmScheduler.EXTRA_ID, 0)
        if (id == 0) return
        val countdownId = intent.getIntExtra(RestAlarmScheduler.EXTRA_COUNTDOWN_ID, 0)
        val title = intent.getStringExtra(RestAlarmScheduler.EXTRA_TITLE) ?: "FORGEN"
        val playSound = intent.getBooleanExtra(RestAlarmScheduler.EXTRA_SOUND, true)
        val vibrate = intent.getBooleanExtra(RestAlarmScheduler.EXTRA_VIBRATE, true)

        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (countdownId != 0 && countdownId != id) manager.cancel(countdownId)
        manager.cancel(id)
        val channelId = RestAlarmScheduler.ensureDoneChannel(context, manager, playSound, vibrate)
        val notification = Notification.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_stat_forgen)
            .setContentTitle(title)
            .setContentText(null)
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setColor(Color.parseColor("#4A9EFF"))
            .setContentIntent(RestAlarmScheduler.launchIntent(context, id))
            .build()
        try {
            manager.notify(id, notification)
        } catch (_: SecurityException) {
        }
    }
}

object RestAlarmScheduler {
    const val ACTION = "io.fitforge.fitforge.REST_ALARM"
    const val EXTRA_ID = "id"
    const val EXTRA_COUNTDOWN_ID = "countdownId"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"
    const val EXTRA_SOUND = "playSound"
    const val EXTRA_VIBRATE = "vibrate"

    private const val COUNTDOWN_CHANNEL = "fitforge_rest_countdown"
    private const val DONE_BOTH = "fitforge_rest_done_both"
    private const val DONE_SOUND = "fitforge_rest_done_sound"
    private const val DONE_VIBRATE = "fitforge_rest_done_vibrate"

    fun schedule(
        context: Context,
        id: Int,
        countdownId: Int,
        atMillis: Long,
        title: String,
        body: String,
        playSound: Boolean,
        vibrate: Boolean,
    ) {
        val app = context.applicationContext
        val manager = app.getSystemService(NotificationManager::class.java) ?: return
        ensureCountdownChannel(manager)
        try {
            if (countdownId != 0 && countdownId != id) manager.cancel(countdownId)
            manager.notify(
                id,
                Notification.Builder(app, COUNTDOWN_CHANNEL)
                    .setSmallIcon(R.drawable.ic_stat_forgen)
                    .setContentTitle(body.ifBlank { "FORGEN" })
                    .setWhen(atMillis)
                    .setShowWhen(true)
                    .setUsesChronometer(true)
                    .setChronometerCountDown(true)
                    .setOnlyAlertOnce(true)
                    .setCategory(Notification.CATEGORY_PROGRESS)
                    .setVisibility(Notification.VISIBILITY_PUBLIC)
                    .setColor(Color.parseColor("#4A9EFF"))
                    .setContentIntent(launchIntent(app, id))
                    .build(),
            )
        } catch (_: SecurityException) {
            // Sin permiso de notificaciones no hay barra que mostrar.
        }

        val alarmIntent = Intent(app, RestAlarmReceiver::class.java).apply {
            action = ACTION
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_COUNTDOWN_ID, countdownId)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_SOUND, playSound)
            putExtra(EXTRA_VIBRATE, vibrate)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        PendingIntent.getBroadcast(app, id, alarmIntent, PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE)
            ?.cancel()
        val operation = PendingIntent.getBroadcast(app, id, alarmIntent, flags)
        val alarmManager = app.getSystemService(android.app.AlarmManager::class.java) ?: return
        val trigger = atMillis.coerceAtLeast(System.currentTimeMillis() + 250)
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
        if (canExact) {
            alarmManager.setAlarmClock(
                android.app.AlarmManager.AlarmClockInfo(trigger, launchIntent(app, id)),
                operation,
            )
        } else {
            alarmManager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, trigger, operation)
        }
    }

    fun cancel(context: Context, id: Int, countdownId: Int, keepVisible: Boolean) {
        val app = context.applicationContext
        val alarmIntent = Intent(app, RestAlarmReceiver::class.java).apply { action = ACTION }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val operation = PendingIntent.getBroadcast(app, id, alarmIntent, flags)
        app.getSystemService(android.app.AlarmManager::class.java)?.cancel(operation)
        operation.cancel()
        val manager = app.getSystemService(NotificationManager::class.java) ?: return
        if (countdownId != 0 && countdownId != id) manager.cancel(countdownId)
        if (!keepVisible) manager.cancel(id)
    }

    fun launchIntent(context: Context, requestCode: Int): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        launch.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(context, requestCode, launch, flags)
    }

    fun ensureDoneChannel(
        context: Context,
        manager: NotificationManager,
        playSound: Boolean,
        vibrate: Boolean,
    ): String {
        val id = when {
            playSound && vibrate -> DONE_BOTH
            playSound -> DONE_SOUND
            else -> DONE_VIBRATE
        }
        if (manager.getNotificationChannel(id) != null) return id
        val channel = NotificationChannel(id, "Descanso entre series", NotificationManager.IMPORTANCE_MAX)
        channel.description = "Aviso al terminar el descanso entre series"
        channel.enableVibration(vibrate)
        channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        if (playSound) {
            val sound = Uri.parse("android.resource://${context.packageName}/raw/rest_timer_bell")
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            channel.setSound(sound, attrs)
        } else {
            channel.setSound(null, null)
        }
        manager.createNotificationChannel(channel)
        return id
    }

    private fun ensureCountdownChannel(manager: NotificationManager) {
        if (manager.getNotificationChannel(COUNTDOWN_CHANNEL) != null) return
        val channel = NotificationChannel(
            COUNTDOWN_CHANNEL,
            "Descanso en curso",
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        channel.setSound(null, null)
        channel.enableVibration(false)
        channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        manager.createNotificationChannel(channel)
    }
}
