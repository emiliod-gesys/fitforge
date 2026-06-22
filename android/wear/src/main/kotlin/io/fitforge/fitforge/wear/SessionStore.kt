package io.fitforge.fitforge.wear

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONObject

data class WorkoutSessionUi(
    val exerciseName: String = "",
    val setNumber: Int = 1,
    val weight: Double? = null,
    val reps: Int = 0,
    val unitSystem: String = "kg",
    val isCardio: Boolean = false,
    val restEndsAtEpochMs: Long? = null,
    val restTotalSeconds: Int? = null,
    val cleared: Boolean = false,
) {
    val active: Boolean get() = exerciseName.isNotBlank() && !cleared

    val restRemainingSeconds: Int?
        get() {
            val endsAt = restEndsAtEpochMs ?: return null
            val remainingMs = endsAt - System.currentTimeMillis()
            if (remainingMs <= 0) return 0
            return ((remainingMs + 999) / 1000).toInt()
        }

    val restActive: Boolean
        get() = (restRemainingSeconds ?: 0) > 0
}

object SessionStore {
    private val _session = MutableStateFlow(WorkoutSessionUi())
    val session: StateFlow<WorkoutSessionUi> = _session.asStateFlow()

    fun applyPayload(json: String) {
        if (json.contains("\"cleared\":true")) {
            _session.value = WorkoutSessionUi(cleared = true)
            return
        }

        val obj = JSONObject(json)
        _session.value = WorkoutSessionUi(
            exerciseName = obj.optString("exerciseName"),
            setNumber = obj.optInt("setNumber", 1),
            weight = if (obj.has("weight") && !obj.isNull("weight")) obj.getDouble("weight") else null,
            reps = obj.optInt("reps", 0),
            unitSystem = obj.optString("unitSystem", "kg"),
            isCardio = obj.optBoolean("isCardio", false),
            restEndsAtEpochMs = if (obj.has("restEndsAtEpochMs") && !obj.isNull("restEndsAtEpochMs")) {
                obj.getLong("restEndsAtEpochMs")
            } else {
                null
            },
            restTotalSeconds = if (obj.has("restTotalSeconds") && !obj.isNull("restTotalSeconds")) {
                obj.getInt("restTotalSeconds")
            } else {
                null
            },
            cleared = false,
        )
    }
}
