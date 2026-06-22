package io.fitforge.fitforge

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WearSessionBridge(
    context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val appContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(this)
        Holder.instance = this
    }

    fun emitAction(json: String) {
        mainHandler.post {
            eventSink?.success(json)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "publishSession" -> {
                val json = call.arguments as? String
                if (json.isNullOrBlank()) {
                    result.error("invalid_args", "Session payload required", null)
                    return
                }
                publishSession(json)
                result.success(null)
            }
            "clearSession" -> {
                clearSession()
                result.success(null)
            }
            "isWatchAvailable" -> {
                Wearable.getNodeClient(appContext).connectedNodes
                    .addOnSuccessListener { nodes ->
                        result.success(nodes.isNotEmpty())
                    }
                    .addOnFailureListener {
                        result.success(false)
                    }
            }
            else -> result.notImplemented()
        }
    }

    private fun publishSession(json: String) {
        val bytes = json.toByteArray(Charsets.UTF_8)
        val messageClient = Wearable.getMessageClient(appContext)
        Wearable.getNodeClient(appContext).connectedNodes
            .addOnSuccessListener { nodes ->
                for (node in nodes) {
                    messageClient.sendMessage(node.id, PATH_SESSION, bytes)
                }
            }

        val request = PutDataMapRequest.create(PATH_SESSION).apply {
            dataMap.putString("payload", json)
            dataMap.putLong("timestamp", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()

        Wearable.getDataClient(appContext).putDataItem(request)
    }

    private fun clearSession() {
        val empty = """{"cleared":true}"""
        val bytes = empty.toByteArray(Charsets.UTF_8)
        Wearable.getNodeClient(appContext).connectedNodes
            .addOnSuccessListener { nodes ->
                val messageClient = Wearable.getMessageClient(appContext)
                for (node in nodes) {
                    messageClient.sendMessage(node.id, PATH_SESSION, bytes)
                }
            }
        Wearable.getDataClient(appContext).deleteDataItems(
            PutDataMapRequest.create(PATH_SESSION).uri,
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    object Holder {
        var instance: WearSessionBridge? = null
    }

    companion object {
        const val CHANNEL = "io.fitforge.fitforge/watch"
        const val EVENT_CHANNEL = "io.fitforge.fitforge/watch_events"
        const val PATH_SESSION = "/fitforge/workout_session"
        const val PATH_ACTION = "/fitforge/workout_action"
    }
}
