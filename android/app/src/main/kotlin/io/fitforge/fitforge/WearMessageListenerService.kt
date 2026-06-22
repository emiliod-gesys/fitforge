package io.fitforge.fitforge

import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WearMessageListenerService : WearableListenerService() {
    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path != WearSessionBridge.PATH_ACTION) return
        val json = String(messageEvent.data, Charsets.UTF_8)
        WearSessionBridge.Holder.instance?.emitAction(json)
    }
}
