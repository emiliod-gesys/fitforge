import SwiftUI
import WatchKit

struct ContentView: View {
  @EnvironmentObject private var store: WatchSessionStore
  @State private var restRemaining = 0
  @State private var restVibrated = false

  var body: some View {
    Group {
      if !store.session.active {
        Text("Inicia un entreno en el teléfono")
          .multilineTextAlignment(.center)
      } else if store.session.isCardio {
        VStack(spacing: 8) {
          Text(store.session.exerciseName)
            .font(.headline)
          Text("Cardio solo en el teléfono")
            .font(.caption)
        }
      } else {
        workoutView
      }
    }
    .padding()
    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
      restRemaining = store.session.restRemainingSeconds ?? 0
      if store.session.restActive, restRemaining == 0, !restVibrated {
        WKInterfaceDevice.current().play(.notification)
        restVibrated = true
      }
      if !store.session.restActive {
        restVibrated = false
      }
    }
  }

  private var workoutView: some View {
    VStack(spacing: 8) {
      Text(store.session.exerciseName)
        .font(.headline)
        .multilineTextAlignment(.center)
      Text("Set \(store.session.setNumber)")
      Text("\(formattedWeight()) × \(store.session.reps) reps")

      if store.session.restActive {
        Text("Descanso \(restRemaining)s")
        Button("Saltar descanso") {
          store.sendAction(type: "skip_rest")
        }
        HStack {
          Button("-15s") { store.sendAction(type: "adjust_rest", deltaSeconds: -15) }
          Button("+15s") { store.sendAction(type: "adjust_rest", deltaSeconds: 15) }
        }
      } else {
        Button("Completar set") {
          store.sendAction(type: "complete_set")
        }
      }
    }
  }

  private func formattedWeight() -> String {
    let unit = store.session.unitSystem == "lb" ? "lb" : "kg"
    if let weight = store.session.weight {
      return String(format: "%.1f %@", weight, unit)
    }
    return "- \(unit)"
  }
}

#Preview {
  ContentView()
    .environmentObject(WatchSessionStore())
}
