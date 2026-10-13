//
//  FamilyTransport.swift
//  DiabetesCare
//
//  How change sets travel. `CloudKitFamilyTransport` uses the people's own
//  iCloud accounts; `LoopbackFamilyTransport` keeps everything in memory on
//  one device, for tests and the "see what your family sees" preview.
//

import Foundation

nonisolated protocol FamilyTransport: Sendable {
    /// Publisher: send changes to everyone who follows this person.
    func publish(_ changes: FamilyChangeSet) async throws
    /// Follower: everyone this phone follows.
    func followedPersonIDs() async throws -> [String]
    /// Follower: what changed for one person since `token`. Returns the new
    /// token to pass next time.
    func fetchChanges(for personID: String, since token: Data?) async throws -> (changes: FamilyChangeSet, token: Data?)
    /// Follower: answer a help request. The only thing a follower writes.
    func sendReply(_ reply: FamilyHelpReply, to personID: String) async throws
    /// Publisher: replies to this person's help requests since `token`.
    func fetchReplies(since token: Data?) async throws -> (replies: [FamilyHelpReply], token: Data?)
}

/// Everything in memory. Each publish is kept in order, and a token is the
/// count of publishes already read.
actor LoopbackFamilyTransport: FamilyTransport {
    static let personID = "loopback"

    private var log: [FamilyChangeSet] = []
    private var replies: [FamilyHelpReply] = []

    init() {}

    func publish(_ changes: FamilyChangeSet) async throws {
        log.append(changes)
    }

    func followedPersonIDs() async throws -> [String] {
        log.isEmpty ? [] : [Self.personID]
    }

    func fetchChanges(for personID: String, since token: Data?) async throws -> (changes: FamilyChangeSet, token: Data?) {
        let start = token.flatMap { Int(String(decoding: $0, as: UTF8.self)) } ?? 0
        var merged = FamilyChangeSet()
        for changes in log.dropFirst(start) {
            merged = Self.merge(merged, changes)
        }
        return (merged, Data(String(log.count).utf8))
    }

    func sendReply(_ reply: FamilyHelpReply, to personID: String) async throws {
        replies.append(reply)
    }

    func fetchReplies(since token: Data?) async throws -> (replies: [FamilyHelpReply], token: Data?) {
        let start = token.flatMap { Int(String(decoding: $0, as: UTF8.self)) } ?? 0
        return (Array(replies.dropFirst(start)), Data(String(replies.count).utf8))
    }

    /// Later changes win over earlier ones for the same entry.
    static func merge(_ a: FamilyChangeSet, _ b: FamilyChangeSet) -> FamilyChangeSet {
        let newer = Set(b.deletedIDs + FamilyDiff.fingerprints(of: b.entries).keys)
        var entries = a.entries
        entries.glucose = entries.glucose.filter { !newer.contains($0.id) } + b.entries.glucose
        entries.carbs = entries.carbs.filter { !newer.contains($0.id) } + b.entries.carbs
        entries.insulin = entries.insulin.filter { !newer.contains($0.id) } + b.entries.insulin
        entries.activity = entries.activity.filter { !newer.contains($0.id) } + b.entries.activity
        entries.sites = entries.sites.filter { !newer.contains($0.id) } + b.entries.sites
        let added = Set(FamilyDiff.fingerprints(of: b.entries).keys)
        let deleted = a.deletedIDs.filter { !added.contains($0) } + b.deletedIDs
        return FamilyChangeSet(
            profile: b.profile ?? a.profile,
            entries: entries,
            deletedIDs: deleted,
            helpRequests: a.helpRequests + b.helpRequests
        )
    }
}
