//
//  AppDelegate.swift
//  DiabetesCare
//
//  The UIKit hooks family sharing needs: accepting an iCloud invitation,
//  and waking up when CloudKit says something shared has changed, so a
//  parent's alert arrives without opening the app. Both only do anything
//  once iCloud is set up (`FamilyCloud.isAvailable`).
//

import CloudKit
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if FamilyCloud.isAvailable, !FamilyService.shared.followed.isEmpty {
            application.registerForRemoteNotifications()
        }
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = FamilySceneDelegate.self
        return configuration
    }

    nonisolated func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo) != nil else { return .noData }
        await FamilyService.shared.refreshFollowed()
        return .newData
    }
}

/// Receives iCloud share invitations opened on this phone.
final class FamilySceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            accept(metadata)
        }
    }

    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        accept(cloudKitShareMetadata)
    }

    private func accept(_ metadata: CKShare.Metadata) {
        Task { @MainActor in
            await FamilyService.shared.accept(metadata)
        }
    }
}
