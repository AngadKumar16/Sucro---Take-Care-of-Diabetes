//
//  Toast.swift
//  DiabetesCare
//
//  "Logged 30 g carbs · Undo": a short confirmation after logging or
//  deleting, with a way to take it back. One at a time, gone after a few
//  seconds. Its haptic says what kind of thing happened.
//

import CoreData
import SwiftUI

@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    /// What happened, which picks the haptic.
    enum Kind: Equatable {
        /// Saved; in range or nothing to flag.
        case saved
        /// Saved, and it's a low or urgent high worth noticing.
        case attention
        /// Something was deleted.
        case removed
    }

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let kind: Kind
        /// Off when the form that saved already gave the success haptic.
        let haptic: Bool
        let undo: (() -> Void)?

        static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
    }

    private(set) var current: Toast?
    /// Bumped when Undo is tapped, for its haptic.
    private(set) var undoCount = 0

    /// UI tests turn toasts off so they don't cover what a test taps,
    /// except tests about toasts (`-toasts`).
    @ObservationIgnored private let isEnabled: Bool = {
        let arguments = ProcessInfo.processInfo.arguments
        return !arguments.contains("-uiTesting") || arguments.contains("-toasts")
    }()

    func show(_ message: String, kind: Kind = .saved, haptic: Bool = true, undo: (() -> Void)? = nil) {
        guard isEnabled else { return }
        current = Toast(message: message, kind: kind, haptic: haptic, undo: undo)
    }

    func dismiss(_ toast: Toast) {
        if current?.id == toast.id { current = nil }
    }

    func performUndo() {
        guard let toast = current else { return }
        current = nil
        toast.undo?()
        undoCount += 1
    }

    // MARK: - Undo helpers

    /// Undo for a new entry: delete it again.
    static func undoInsert(_ objectID: NSManagedObjectID, in context: NSManagedObjectContext) -> () -> Void {
        {
            DataService.shared.delete(objectID, context: context)
        }
    }

    /// Captures an entry before it's deleted, so Undo can put it back with
    /// the same id and values.
    static func undoDelete(of object: NSManagedObject) -> () -> Void {
        let context = object.managedObjectContext
        let entityName = object.entity.name ?? ""
        let keys = Array(object.entity.attributesByName.keys)
        let values = object.dictionaryWithValues(forKeys: keys)
        return {
            guard let context else { return }
            let restored = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            for (key, value) in values where !(value is NSNull) {
                restored.setValue(value, forKey: key)
            }
            do {
                try context.save()
            } catch {
                context.rollback()
            }
        }
    }
}

/// Shows the current toast at the bottom of the screen.
struct ToastOverlay: ViewModifier {
    @State private var center = ToastCenter.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = center.current {
                    ToastView(toast: toast, onUndo: center.performUndo)
                        .padding(.horizontal)
                        .padding(.bottom, 64)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                        .task(id: toast.id) {
                            AccessibilityNotification.Announcement(toast.message).post()
                            try? await Task.sleep(for: .seconds(toast.undo == nil ? 3 : 5))
                            withAnimation(.smooth) { center.dismiss(toast) }
                        }
                }
            }
            .animation(reduceMotion ? .default : .bouncy(duration: 0.4), value: center.current)
            // The haptic language: success for a save, warning when the
            // value needs attention, a light tap for deletes and undo.
            .sensoryFeedback(trigger: center.current) { _, toast -> SensoryFeedback? in
                guard let toast, toast.haptic else { return nil }
                switch toast.kind {
                case .saved: return .success
                case .attention: return .warning
                case .removed: return .impact(weight: .light)
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: center.undoCount)
    }
}

private struct ToastView: View {
    let toast: ToastCenter.Toast
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
            Spacer(minLength: 0)
            if toast.undo != nil {
                Button("Undo", action: onUndo)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.green)
                    .accessibilityIdentifier("toastUndo")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: .capsule)
        .overlay(Capsule().strokeBorder(Theme.rule))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("toast")
    }

    private var icon: String {
        switch toast.kind {
        case .saved: "checkmark.circle.fill"
        case .attention: "exclamationmark.circle.fill"
        case .removed: "trash.circle.fill"
        }
    }

    private var color: Color {
        switch toast.kind {
        case .saved: Theme.green
        case .attention: Theme.vermilion
        case .removed: Theme.soft
        }
    }
}

extension View {
    func toastOverlay() -> some View { modifier(ToastOverlay()) }
}
