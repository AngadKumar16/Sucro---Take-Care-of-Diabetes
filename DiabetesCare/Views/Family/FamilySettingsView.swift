//
//  FamilySettingsView.swift
//  DiabetesCare
//
//  Settings › Family: share your log with family over iCloud, see exactly
//  what they see, and follow someone else.
//

import CloudKit
import SwiftUI

struct FamilySettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(FamilyService.self) private var family
    @Environment(ParentGate.self) private var gate
    @State private var invite: SharingInvite?
    @State private var preview: FamilyPreview?
    @State private var showStopConfirm = false
    @FocusState private var editingContact: Bool

    var body: some View {
        Form {
            if settings.appRole == .selfCare {
                if settings.stage != .adult { grownUpSection }
                shareSection
                whatSection
            }
            followingSection
            if let error = family.lastError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Theme.vermilion)
                }
                .listRowBackground(Theme.card)
            }
        }
        .instrumentBackground()
        .navigationTitle("Family")
        .refreshable { await family.refreshFollowed() }
        // The phone pad has no return key.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { editingContact = false }
            }
        }
        .sheet(item: $invite) { invite in
            CloudSharingSheet(share: invite.share, container: invite.container)
                .ignoresSafeArea()
        }
        .navigationDestination(item: $preview) { preview in
            CaregiverView(person: preview.person, store: preview.store, isPreview: true)
        }
    }

    // MARK: - Grown-up

    private var grownUpSection: some View {
        let locked = gate.needsApproval(.editGrownUpContact)
        return Section {
            TextField("Name", text: Bindable(settings).grownUpName)
                .textContentType(.name)
                .disabled(locked)
                .focused($editingContact)
            TextField("Phone Number", text: Bindable(settings).grownUpPhone)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .disabled(locked)
                .focused($editingContact)
                .accessibilityIdentifier("grownUpPhone")
            if locked {
                Button("Unlock to Change", systemImage: "lock.fill") {
                    gate.run(.editGrownUpContact) {}
                }
                .accessibilityIdentifier("unlockGrownUp")
            }
        } header: {
            Text("Grown-Up to Call")
        } footer: {
            Text("Get Help on Today shows Call and Text buttons for this person. Works without iCloud.")
        }
        .listRowBackground(Theme.card)
    }

    // MARK: - Sharing

    private var shareSection: some View {
        Section {
            if family.isCloudAvailable {
                if settings.familySharingEnabled {
                    LabeledContent("Sharing", value: String(localized: "On"))
                    if let last = family.lastPublished {
                        LabeledContent("Last Sent") {
                            Text(last, format: .relative(presentation: .named))
                        }
                    }
                    Button("Invite Family", systemImage: "person.badge.plus", action: startSharing)
                    Button("Stop Sharing", systemImage: "xmark.circle", role: .destructive) {
                        gate.run(.stopSharing) { showStopConfirm = true }
                    }
                    .parentLockBadge(gate.needsApproval(.stopSharing))
                    .confirmationDialog("Stop Sharing?", isPresented: $showStopConfirm, titleVisibility: .visible) {
                        Button("Stop Sharing", role: .destructive) {
                            Task { await family.stopSharing() }
                        }
                    } message: {
                        Text("Family will stop getting your readings and alerts, and what was shared is removed from iCloud.")
                    }
                } else {
                    Button(action: startSharing) {
                        HStack {
                            Label("Share with Family", systemImage: "person.2.fill")
                            Spacer()
                            if family.isWorking { ProgressView() }
                        }
                    }
                    .disabled(family.isWorking)
                }
            } else {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud Sharing Not Set Up Yet")
                            .font(.headline)
                        Text("This build of \(AppInfo.name) isn't connected to iCloud yet, so it can't send readings to family. Everything else works, and you can preview below what family will see.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.soft)
                    }
                } icon: {
                    Image(systemName: "icloud.slash")
                }
            }
            Button("See What Family Sees", systemImage: "eye", action: showPreview)
                .accessibilityIdentifier("familyPreview")
        } header: {
            Text("Share Your Log")
        } footer: {
            Text(footer)
        }
        .listRowBackground(Theme.card)
    }

    private var footer: String {
        switch settings.stage {
        case .kid:
            String(localized: "Family gets every reading, low and high alerts, and your \"I need help\" taps.")
        case .teen:
            String(localized: "Family can see how you're doing, and only gets alerts for urgent lows and highs. Your notes stay on your phone.")
        case .adult:
            String(localized: "Family can see your readings and gets alerts for urgent lows only. Your notes stay on your phone.")
        }
    }

    private var whatSection: some View {
        Section("What's Shared") {
            Label("Glucose, meals, insulin, activity and site changes from the last \(FamilySharing.historyDays) days", systemImage: "list.bullet.clipboard")
            Label("Your name, stage, ranges and skills", systemImage: "person.text.rectangle")
            Label(settings.stage == .kid ? "Notes" : "Not your notes", systemImage: "note.text")
            Label("Never photos, and never anyone outside your family. It goes from your iCloud to theirs, not to us.", systemImage: "lock.fill")
        }
        .font(.subheadline)
        .listRowBackground(Theme.card)
    }

    // MARK: - Following

    @ViewBuilder
    private var followingSection: some View {
        Section {
            if family.followed.isEmpty {
                Text(family.isCloudAvailable
                     ? String(localized: "When someone invites you, open the invitation on this phone and they'll show up here.")
                     : String(localized: "Following someone needs iCloud sharing, which isn't set up in this build yet."))
                    .font(.subheadline)
                    .foregroundStyle(Theme.soft)
            } else {
                ForEach(family.followed) { person in
                    NavigationLink(value: GrowthDestination.person(person.id)) {
                        FollowedPersonRow(person: person)
                    }
                    .swipeActions {
                        Button("Remove", role: .destructive) { family.unfollow(person) }
                    }
                }
            }
        } header: {
            Text("People You Follow")
        }
        .listRowBackground(Theme.card)
    }

    // MARK: - Actions

    private func startSharing() {
        Task {
            do {
                if let share = try await family.startSharing(), let container = family.cloudContainer {
                    invite = SharingInvite(share: share, container: container)
                }
            } catch {
                family.lastError = error.localizedDescription
            }
        }
    }

    private func showPreview() {
        Task {
            do {
                let made = try await family.makePreview()
                preview = FamilyPreview(person: made.person, store: made.store)
            } catch {
                family.lastError = error.localizedDescription
            }
        }
    }
}

struct FollowedPersonRow: View {
    let person: FamilyPerson

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: person.profile?.stage.symbol ?? "person.fill")
                .foregroundStyle(Theme.green)
                .frame(width: 36, height: 36)
                .background(Theme.green.opacity(0.12), in: .circle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.displayName).font(.headline)
                if let sync = person.lastSync {
                    Text("Updated \(sync, format: .relative(presentation: .named))")
                        .font(.caption)
                        .foregroundStyle(Theme.soft)
                }
            }
        }
    }
}

struct SharingInvite: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
}

struct FamilyPreview: Identifiable, Hashable {
    let id = UUID()
    let person: FamilyPerson
    let store: PersistenceController

    static func == (a: FamilyPreview, b: FamilyPreview) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// The system screen for inviting people to an iCloud share.
struct CloudSharingSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadOnly, .allowPrivate]
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}
}
