//
//  AppIconPicker.swift
//  DiabetesCare
//
//  Pick the color of the app icon. Kids especially like making the app
//  their own.
//

import SwiftUI
import OSLog
import UIKit

struct AppIconPicker: View {
    /// `nil` is the main green icon.
    private static let choices: [(name: String?, title: String)] = [
        (nil, String(localized: "Garden")),
        ("Sunrise", String(localized: "Sunrise")),
        ("Ocean", String(localized: "Ocean")),
        ("Berry", String(localized: "Berry")),
        ("Midnight", String(localized: "Midnight")),
    ]

    @State private var current = UIApplication.shared.alternateIconName
    @State private var failed = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 16)], spacing: 20) {
                ForEach(Self.choices, id: \.title) { choice in
                    let iconName = choice.name.map { "AppIcon-\($0)" }
                    Button {
                        select(iconName)
                    } label: {
                        VStack(spacing: 8) {
                            Image("IconPreview-\(choice.name ?? "Default")")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(current == iconName ? Theme.green : .clear, lineWidth: 3)
                                        .padding(-5)
                                }
                            Text(choice.title)
                                .font(.subheadline.weight(current == iconName ? .semibold : .regular))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(current == iconName ? .isSelected : [])
                    .accessibilityLabel(choice.title)
                }
            }
            .padding()
        }
        .instrumentBackground()
        .navigationTitle("App Icon")
        .sensoryFeedback(.selection, trigger: current)
        .alert("Couldn't Change the Icon", isPresented: $failed) {
            Button("OK", role: .cancel) {}
        }
    }

    private func select(_ name: String?) {
        guard name != current, UIApplication.shared.supportsAlternateIcons else { return }
        Task {
            do {
                try await UIApplication.shared.setAlternateIconName(name)
                current = name
            } catch {
                Log.data.error("Alternate icon failed: \(error.localizedDescription, privacy: .public)")
                failed = true
            }
        }
    }
}
