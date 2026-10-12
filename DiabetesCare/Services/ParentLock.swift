//
//  ParentLock.swift
//  DiabetesCare
//
//  A grown-up's 4-digit passcode for the settings a kid or teen shouldn't
//  change alone. Only a salted hash is kept, in the Keychain. Entering it
//  unlocks for a few minutes so a parent can make several changes.
//
//  This is a speed bump for a kid, not security against a determined
//  attacker: four digits, on the kid's own phone.
//

import CryptoKit
import Foundation
import Observation
import OSLog
import Security

/// Where the passcode hash lives. The Keychain in the app, memory in tests.
protocol ParentLockStorage {
    func read() -> Data?
    func write(_ data: Data?)
}

@MainActor
@Observable
final class ParentLock {
    static let shared = ParentLock(storage: KeychainParentLockStorage())

    static let codeLength = 4
    /// How long one correct passcode keeps things unlocked.
    static let unlockDuration: TimeInterval = 5 * 60
    /// Wrong tries before a short wait.
    static let maxAttempts = 5
    static let lockoutDuration: TimeInterval = 30

    @ObservationIgnored private let storage: ParentLockStorage
    private(set) var hasPasscode: Bool
    private(set) var unlockedUntil: Date?
    private(set) var failedAttempts = 0
    private(set) var lockedOutUntil: Date?

    init(storage: ParentLockStorage) {
        self.storage = storage
        self.hasPasscode = storage.read() != nil
    }

    func isUnlocked(now: Date = Date()) -> Bool {
        guard let unlockedUntil else { return false }
        return unlockedUntil > now
    }

    func isLockedOut(now: Date = Date()) -> Bool {
        guard let lockedOutUntil else { return false }
        return lockedOutUntil > now
    }

    static func isValidCode(_ code: String) -> Bool {
        code.count == codeLength && code.allSatisfy(\.isASCII) && code.allSatisfy(\.isNumber)
    }

    /// Sets or replaces the passcode and unlocks.
    func setPasscode(_ code: String, now: Date = Date()) {
        guard Self.isValidCode(code) else { return }
        var salt = Data(count: 16)
        let status = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
        if status != errSecSuccess { salt = Data(UUID().uuidString.utf8) }
        storage.write(salt + Self.hash(code, salt: salt))
        hasPasscode = true
        unlock(now: now)
    }

    /// Checks a passcode. A correct one unlocks for `unlockDuration`.
    @discardableResult
    func verify(_ code: String, now: Date = Date()) -> Bool {
        guard !isLockedOut(now: now), let stored = storage.read(), stored.count > 16 else { return false }
        let salt = stored.prefix(16)
        let expected = stored.dropFirst(16)
        if Self.hash(code, salt: Data(salt)) == Data(expected) {
            failedAttempts = 0
            lockedOutUntil = nil
            unlock(now: now)
            return true
        }
        failedAttempts += 1
        if failedAttempts >= Self.maxAttempts {
            failedAttempts = 0
            lockedOutUntil = now.addingTimeInterval(Self.lockoutDuration)
        }
        return false
    }

    func lock() {
        unlockedUntil = nil
    }

    /// Forgets the passcode, e.g. when the phone moves to the Adult stage.
    func removePasscode() {
        storage.write(nil)
        hasPasscode = false
        unlockedUntil = nil
    }

    private func unlock(now: Date) {
        unlockedUntil = now.addingTimeInterval(Self.unlockDuration)
    }

    private static func hash(_ code: String, salt: Data) -> Data {
        Data(SHA256.hash(data: salt + Data(code.utf8)))
    }
}

/// Keeps the hash in the Keychain, on this device only.
struct KeychainParentLockStorage: ParentLockStorage {
    private let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "DiabetesCare.parentLock",
        kSecAttrAccount as String: "passcode",
    ]

    func read() -> Data? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    func write(_ data: Data?) {
        SecItemDelete(query as CFDictionary)
        guard let data else { return }
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        if status != errSecSuccess {
            Log.data.error("Couldn't save parent passcode: \(status, privacy: .public)")
        }
    }
}

/// For tests and previews.
final class MemoryParentLockStorage: ParentLockStorage {
    private var data: Data?
    init(data: Data? = nil) { self.data = data }
    func read() -> Data? { data }
    func write(_ data: Data?) { self.data = data }
}
