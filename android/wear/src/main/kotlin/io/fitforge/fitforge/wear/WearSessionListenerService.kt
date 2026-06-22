package io.fitforge.fitforge.wear

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WearSessionListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val path = event.dataItem.uri.path ?: continue
            if (path != PATH_SESSION) continue
            val map = DataMapItem.fromDataItem(event.dataItem).dataMap
            val payload = map.getString("payload") ?: continue
            SessionStore.applyPayload(payload)
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path != PATH_SESSION) return
        val payload = String(messageEvent.data, Charsets.UTF_8)
        SessionStore.applyPayload(payload)
    }

    companion object {
        private const val PATH_SESSION = "/fitforge/workout_session"
    }
}
