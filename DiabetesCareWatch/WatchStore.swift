//
//  WatchStore.swift
//  DiabetesCare Watch
//
//  Receives the glance snapshot from the phone and sends what's logged on
//  the watch back to it. Keeps the last snapshot for complications.
//

import Foundation
import Observation
import WatchConnectivity
import WidgetKit

@MainActor
@Observable
final class WatchStore: NSObject {
    static let shared = WatchStore()

    private(set) var snapshot: GlanceSnapshot? = GlanceSnapshot.load()
    /// What happened to the last thing sent: shown briefly.
    var status: String?

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
            session.activate()
        }
    }

    func receive(_ snapshot: GlanceSnapshot) {
        self.snapshot = snapshot
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Sends a request to the phone. Uses a live message when the phone is
    /// reachable, otherwise queues it to be delivered later.
    func send(_ action: WatchMessage, grams: Double? = nil, mgdl: Double? = nil, done: String) {
        var message: [String: Any] = ["action": action.rawValue]
        if let grams { message["grams"] = grams }
        if let mgdl { message["mgdl"] = mgdl }
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(message, replyHandler: { reply in
                let ok = reply["ok"] as? Bool ?? false
                Task { @MainActor in WatchStore.shared.status = ok ? done : String(localized: "Couldn't log that. Try on your phone.") }
            }, errorHandler: { _ in
                session.transferUserInfo(message)
                Task { @MainActor in WatchStore.shared.status = String(localized: "Saved. It'll reach your phone soon.") }
            })
        } else {
            session.transferUserInfo(message)
            status = String(localized: "Saved. It'll reach your phone soon.")
        }
    }
}

extension WatchStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Self.decode(context)
        if session.isReachable {
            session.sendMessage(["action": WatchMessage.refresh.rawValue], replyHandler: nil)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Self.decode(applicationContext)
    }

    nonisolated private static func decode(_ context: [String: Any]) {
        guard let data = context["glance"] as? Data,
              let snapshot = try? JSONDecoder().decode(GlanceSnapshot.self, from: data) else { return }
        Task { @MainActor in WatchStore.shared.receive(snapshot) }
    }
}
