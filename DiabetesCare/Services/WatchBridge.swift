//
//  WatchBridge.swift
//  DiabetesCare
//
//  Talks to the Apple Watch app over WatchConnectivity: sends the glance
//  snapshot whenever it changes, and logs what the watch sends (fast
//  sugar, a glucose check, carbs). Nothing goes through a server.
//

import Foundation
import OSLog
import WatchConnectivity

@MainActor
final class WatchBridge: NSObject {
    static let shared = WatchBridge()

    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    func start() {
        guard let session, session.delegate == nil else { return }
        session.delegate = self
        session.activate()
    }

    func send(_ snapshot: GlanceSnapshot) {
        guard let session, session.activationState == .activated, session.isPaired, session.isWatchAppInstalled,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        do {
            try session.updateApplicationContext(["glance": data])
        } catch {
            Log.data.error("Watch update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Handles a message from the watch. Returns a reply for it.
    func handle(_ message: [String: Any]) -> [String: Any] {
        let context = PersistenceController.shared.container.viewContext
        switch WatchMessage(rawValue: message["action"] as? String ?? "") {
        case .logFastSugar:
            let grams = message["grams"] as? Double ?? 15
            LowTreatmentService.logFastCarbs(grams: grams, context: context)
            return ["ok": true]
        case .logCarbs:
            guard let grams = message["grams"] as? Double, (1...500).contains(grams) else { return ["ok": false] }
            IntentActions.logCarbs(grams: grams, context: context)
            return ["ok": true]
        case .logGlucose:
            guard let mgdl = message["mgdl"] as? Double, SettingsStore.plausibleGlucose.contains(mgdl) else { return ["ok": false] }
            IntentActions.logGlucose(mgdl: mgdl, context: context)
            return ["ok": true]
        case .refresh:
            GlanceWriter.shared.update()
            return ["ok": true]
        case nil:
            return ["ok": false]
        }
    }
}

extension WatchBridge: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            Task { @MainActor in GlanceWriter.shared.update() }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        let sendable = message.compactMapValues { $0 as? any Sendable }
        Task { @MainActor in
            let reply = WatchBridge.shared.handle(sendable)
            replyHandler(reply)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        let sendable = userInfo.compactMapValues { $0 as? any Sendable }
        Task { @MainActor in _ = WatchBridge.shared.handle(sendable) }
    }
}
