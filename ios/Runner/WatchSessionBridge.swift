import Flutter
import UIKit
import WatchConnectivity

final class WatchSessionBridge: NSObject, WCSessionDelegate {
  static let shared = WatchSessionBridge()

  private let channelName = "io.fitforge.fitforge/watch"
  private let eventChannelName = "io.fitforge.fitforge/watch_events"

  private var methodChannel: FlutterMethodChannel?
  private var eventSink: FlutterEventSink?
  private var session: WCSession?

  func register(with messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    methodChannel?.setMethodCallHandler(handle)

    let events = FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger)
    events.setStreamHandler(self)

    if WCSession.isSupported() {
      session = WCSession.default
      session?.delegate = self
      session?.activate()
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "publishSession":
      guard let json = call.arguments as? String else {
        result(FlutterError(code: "invalid_args", message: "Session payload required", details: nil))
        return
      }
      publishSession(json)
      result(nil)
    case "clearSession":
      publishSession("{\"cleared\":true}")
      result(nil)
    case "isWatchAvailable":
      let available = session?.isPaired == true && session?.isWatchAppInstalled == true
      result(available)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func publishSession(_ json: String) {
    guard let session = session, session.activationState == .activated else { return }

    if session.isReachable {
      session.sendMessage(["payload": json], replyHandler: nil) { _ in
        self.updateApplicationContext(json)
      }
    } else {
      updateApplicationContext(json)
    }
  }

  private func updateApplicationContext(_ json: String) {
    guard let session = session, session.activationState == .activated else { return }
    do {
      try session.updateApplicationContext(["payload": json])
    } catch {
      // Context updates can fail when the payload is unchanged; ignore.
    }
  }

  private func emitAction(_ json: String) {
    DispatchQueue.main.async {
      self.eventSink?(json)
    }
  }

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    guard let json = message["action"] as? String else { return }
    emitAction(json)
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    guard let json = message["action"] as? String else {
      replyHandler([:])
      return
    }
    emitAction(json)
    replyHandler(["ok": true])
  }
}

extension WatchSessionBridge: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
