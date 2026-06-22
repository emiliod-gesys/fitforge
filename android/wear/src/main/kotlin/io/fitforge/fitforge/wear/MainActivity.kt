package io.fitforge.fitforge.wear

import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                WorkoutCompanionScreen()
            }
        }
    }
}

@Composable
private fun WorkoutCompanionScreen() {
    val session by SessionStore.session.collectAsState()
    var restRemaining by remember(session.restEndsAtEpochMs) {
        mutableIntStateOf(session.restRemainingSeconds ?: 0)
    }
    val scope = rememberCoroutineScope()
    val context = androidx.compose.ui.platform.LocalContext.current

    LaunchedEffect(session.restEndsAtEpochMs) {
        var vibrated = false
        while (true) {
            val remaining = session.restRemainingSeconds ?: 0
            restRemaining = remaining
            if (remaining == 0 && session.restEndsAtEpochMs != null && !vibrated) {
                vibrateRestComplete(context)
                vibrated = true
            }
            if (session.restEndsAtEpochMs == null) {
                vibrated = false
            }
            delay(1000)
        }
    }

    if (!session.active) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = stringResource(R.string.waiting_for_phone),
                textAlign = TextAlign.Center,
            )
        }
        return
    }

    if (session.isCardio) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(session.exerciseName, textAlign = TextAlign.Center)
            Text(stringResource(R.string.cardio_unsupported), textAlign = TextAlign.Center)
        }
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(session.exerciseName, textAlign = TextAlign.Center)
        Text(stringResource(R.string.set_label, session.setNumber))
        val unit = if (session.unitSystem == "lb") "lb" else "kg"
        Text("${session.weight ?: "-"} $unit × ${session.reps} reps")

        if (session.restActive) {
            Text("${stringResource(R.string.rest_label)} ${restRemaining}s")
            Button(
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    scope.launch { WatchActionSender.send(context, "skip_rest") }
                },
            ) {
                Text(stringResource(R.string.skip_rest))
            }
            Button(
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    scope.launch { WatchActionSender.send(context, "adjust_rest", -15) }
                },
            ) {
                Text(stringResource(R.string.minus_15))
            }
            Button(
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    scope.launch { WatchActionSender.send(context, "adjust_rest", 15) }
                },
            ) {
                Text(stringResource(R.string.plus_15))
            }
        } else {
            Button(
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    scope.launch { WatchActionSender.send(context, "complete_set") }
                },
            ) {
                Text(stringResource(R.string.complete_set))
            }
        }
    }
}

private fun vibrateRestComplete(context: android.content.Context) {
    val vibrator = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
        val manager = context.getSystemService(VibratorManager::class.java)
        manager?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Vibrator::class.java)
    } ?: return

    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
        vibrator.vibrate(VibrationEffect.createOneShot(400, VibrationEffect.DEFAULT_AMPLITUDE))
    } else {
        @Suppress("DEPRECATION")
        vibrator.vibrate(400)
    }
}
