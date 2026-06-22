package io.fitforge.fitforge.wear

import android.content.Context
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.tasks.await
import org.json.JSONObject

object WatchActionSender {
    private const val PATH_ACTION = "/fitforge/workout_action"

    suspend fun send(context: Context, type: String, deltaSeconds: Int? = null) {
        val payload = JSONObject().apply {
            put("type", type)
            if (deltaSeconds != null) put("deltaSeconds", deltaSeconds)
        }.toString()

        val nodeClient = Wearable.getNodeClient(context)
        val messageClient = Wearable.getMessageClient(context)
        val nodes = nodeClient.connectedNodes.await()
        val bytes = payload.toByteArray(Charsets.UTF_8)
        for (node in nodes) {
            messageClient.sendMessage(node.id, PATH_ACTION, bytes).await()
        }
    }
}
