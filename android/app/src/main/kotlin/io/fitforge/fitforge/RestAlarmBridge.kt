package io.fitforge.fitforge

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class RestAlarmBridge(
    context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "schedule" -> {
                val id = call.argument<Int>("id")
                val countdownId = call.argument<Int>("countdownId")
                val atMillis = call.argument<Number>("atMillis")?.toLong()
                val title = call.argument<String>("title") ?: "FORGEN"
                val body = call.argument<String>("body") ?: ""
                if (id == null || countdownId == null || atMillis == null) {
                    result.error("bad_args", "Faltan datos de la alarma de descanso", null)
                    return
                }
                RestAlarmScheduler.schedule(
                    appContext,
                    id,
                    countdownId,
                    atMillis,
                    title,
                    body,
                    call.argument<Boolean>("playSound") ?: true,
                    call.argument<Boolean>("vibrate") ?: true,
                )
                result.success(null)
            }
            "cancel" -> {
                val id = call.argument<Int>("id")
                val countdownId = call.argument<Int>("countdownId") ?: 0
                if (id == null) {
                    result.error("bad_args", "Falta el id de la alarma de descanso", null)
                    return
                }
                RestAlarmScheduler.cancel(
                    appContext,
                    id,
                    countdownId,
                    call.argument<Boolean>("keepVisible") ?: false,
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "forgen/rest_alarm"
    }
}
