import Foundation
import WatchConnectivity
import Combine

struct WorkoutSessionModel: Equatable {
  var exerciseName: String = ""
  var setNumber: Int = 1
  var weight: Double?
  var reps: Int = 0
  var unitSystem: String = "kg"
  var isCardio: Bool = false
  var restEndsAtEpochMs: Int?
  var restTotalSeconds: Int?
  var cleared: Bool = false

  var active: Bool { !exerciseName.isEmpty && !cleared }

  var restRemainingSeconds: Int? {
    guard let endsAt = restEndsAtEpochMs else { return nil }
    let remainingMs = endsAt - Int(Date().timeIntervalSince1970 * 1000)
    if remainingMs <= 0 { return 0 }
    return (remainingMs + 999) / 1000
  }

  var restActive: Bool { (restRemainingSeconds ?? 0) > 0 }

  static func decode(from json: String) -> WorkoutSessionModel {
    if json.contains("\"cleared\":true") {
      return WorkoutSessionModel(cleared: true)
    }
    guard let data = json.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return WorkoutSessionModel()
    }

    return WorkoutSessionModel(
      exerciseName: object["exerciseName"] as? String ?? "",
      setNumber: object["setNumber"] as? Int ?? 1,
      weight: object["weight"] as? Double,
      reps: object["reps"] as? Int ?? 0,
      unitSystem: object["unitSystem"] as? String ?? "kg",
      isCardio: object["isCardio"] as? Bool ?? false,
      restEndsAtEpochMs: object["restEndsAtEpochMs"] as? Int,
      restTotalSeconds: object["restTotalSeconds"] as? Int,
      cleared: false
    )
  }
}

final class WatchSessionStore: NSObject, ObservableObject, WCSessionDelegate {
  @Published private(set) var session = WorkoutSessionModel()
  private var sessionRef: WCSession?

  override init() {
    super.init()
    if WCSession.isSupported() {
      sessionRef = WCSession.default
      sessionRef?.delegate = self
      sessionRef?.activate()
    }
  }

  func sendAction(type: String, deltaSeconds: Int? = nil) {
    guard let sessionRef, sessionRef.activationState == .activated else { return }
    var payload: [String: Any] = ["type": type]
    if let deltaSeconds { payload["deltaSeconds"] = deltaSeconds }
    guard let data = try? JSONSerialization.data(withJSONObject: payload),
          let json = String(data: data, encoding: .utf8) else { return }

    if sessionRef.isReachable {
      sessionRef.sendMessage(["action": json], replyHandler: nil, errorHandler: nil)
    }
  }

  private func applyPayload(_ json: String) {
    DispatchQueue.main.async {
      self.session = WorkoutSessionModel.decode(from: json)
    }
  }

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    if let payload = session.receivedApplicationContext["payload"] as? String {
      applyPayload(payload)
    }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    if let payload = applicationContext["payload"] as? String {
      applyPayload(payload)
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    if let payload = message["payload"] as? String {
      applyPayload(payload)
    }
  }
}
