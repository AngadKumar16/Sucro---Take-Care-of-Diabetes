//
//  CriticalAlertBanner.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//

import SwiftUI

struct CriticalAlertBanner: View {
    let alert: AlertType
    let onDismiss: () -> Void
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: alert.icon)
                    .font(.title2)
                    .foregroundStyle(alert.color)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(.headline)
                        .foregroundStyle(alert.color)

                    Text(alert.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)

                Spacer()

                Button("Dismiss", systemImage: "xmark.circle.fill", action: onDismiss)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44, alignment: .topTrailing)
                    .contentShape(.rect)
                    .buttonStyle(.plain)
            }

            Button(action: onAction) {
                Label(alert.actionTitle, systemImage: alert.actionIcon)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(alert.color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .stroke(alert.color, lineWidth: 2)
        )
        .shadow(color: alert.color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        CriticalAlertBanner(alert: .lowGlucose(65), onDismiss: {}, onAction: {})
        CriticalAlertBanner(alert: .highGlucose(290), onDismiss: {}, onAction: {})
        CriticalAlertBanner(alert: .cgmDataStale(minutes: 42), onDismiss: {}, onAction: {})
        CriticalAlertBanner(alert: .siteChangeOverdue(4), onDismiss: {}, onAction: {})
    }
    .padding()
}
