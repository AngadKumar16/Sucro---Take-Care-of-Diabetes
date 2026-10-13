//
//  WatchBridge.swift
//  DiabetesCare
//
//  Talks to the Apple Watch app over WatchConnectivity: sends the glance
//  snapshot whenever it changes, and logs what the watch sends (fast
//  sugar, a glucose check, carbs). Nothing goes through a server.
//

import CoreData
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

    /// A message from the watch, read off WatchConnectivity's queue.
    struct Request: Sendable {
        var action: String
        var grams: Double?
        var mgdl: Double?

        nonisolated init(_ message: [String: Any]) {
            action = message["action"] as? String ?? ""
            grams = message["grams"] as? Double
            mgdl = message["mgdl"] as? Double
        }
    }

    /// Handles a message from the watch. Returns whether it worked.
    func handle(_ request: Request) -> Bool {
        let context = PersistenceController.shared.container.viewContext
        switch WatchMessage(rawValue: request.action) {
        case .logFastSugar:
            let grams = request.grams ?? 15
            LowTreatmentService.logFastCarbs(grams: grams, context: context)
            return true
        case .logCarbs:
            guard let grams = request.grams, (1...500).contains(grams) else { return false }
            IntentActions.logCarbs(grams: grams, context: context)
            return true
        case .logGlucose:
            guard let mgdl = request.mgdl, SettingsStore.plausibleGlucose.contains(mgdl) else { return false }
            IntentActions.logGlucose(mgdl: mgdl, context: context)
            return true
        case .refresh:
            GlanceWriter.shared.update()
            return true
        case nil:
            return false
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
        let request = Request(message)
        let reply = UncheckedReply(handler: replyHandler)
        Task { @MainActor in
            let ok = WatchBridge.shared.handle(request)
            reply.handler(["ok": ok])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        let request = Request(userInfo)
        Task { @MainActor in _ = WatchBridge.shared.handle(request) }
    }
}

/// WatchConnectivity's reply handler is safe to call from any queue.
private struct UncheckedReply: @unchecked Sendable {
    let handler: ([String: Any]) -> Void
}
