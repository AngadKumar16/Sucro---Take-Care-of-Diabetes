//
//  SchoolCardView.swift
//  DiabetesCare
//
//  A one-page card for school, a coach or a sitter: the signs of a low,
//  what to do, the person's ranges, and who to call. Shared as a PDF.
//  It's safety information, so it's never behind the grown-up passcode.
//

import SwiftUI

struct SchoolCardView: View {
    @Environment(SettingsStore.self) private var settings
    @AppStorage("schoolCard.notes") private var notes = ""
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SchoolCard(notes: notes)
                    .environment(settings)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Extra notes for the card")
                        .friendlyLabel()
                    TextField("Snack in backpack, nurse's office in room 104…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(12)
                        .background(Theme.card, in: .rect(cornerRadius: 14))
                        .accessibilityIdentifier("schoolCardNotes")
                }
                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Label("Share or Print", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.soft)
                    .accessibilityIdentifier("shareSchoolCard")
                }
                Text("General information, not medical advice. Ask your diabetes team to review the card, and follow the care plan they give you.")
                    .font(.footnote)
                    .foregroundStyle(Theme.soft)
            }
            .padding()
        }
        .instrumentBackground()
        .navigationTitle("School & Sitter Card")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: notes) {
            // Re-render after typing settles.
            try? await Task.sleep(for: .milliseconds(400))
            pdfURL = renderPDF()
        }
    }

    private func renderPDF() -> URL? {
        let name = settings.userName.isEmpty ? "Care" : settings.userName
        let url = URL.temporaryDirectory.appending(path: "\(name) - Diabetes Card.pdf")
        let renderer = ImageRenderer(content:
            SchoolCard(notes: notes)
                .environment(settings)
                .frame(width: 540)
                .padding(36)
                .background(Color.white)
                .environment(\.colorScheme, .light)
        )
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdf = CGContext(consumer: consumer, mediaBox: &box, nil) else { return nil }
        renderer.render { size, draw in
            pdf.beginPDFPage(nil)
            // Center at the top of a Letter page, scaled down if tall.
            let scale = min(1, box.height / size.height)
            pdf.translateBy(x: (box.width - size.width * scale) / 2, y: box.height - size.height * scale)
            pdf.scaleBy(x: scale, y: scale)
            draw(pdf)
            pdf.endPDFPage()
        }
        pdf.closePDF()
        return url
    }
}

/// The card itself.
struct SchoolCard: View {
    @Environment(SettingsStore.self) private var settings
    let notes: String

    var body: some View {
        let name = settings.userName.trimmingCharacters(in: .whitespaces)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name.isEmpty ? String(localized: "I have type 1 diabetes") : String(localized: "\(name) has type 1 diabetes"))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Low blood sugar can happen fast. Never leave someone alone with a low.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                }
                Spacer()
                Image(systemName: "cross.case.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.vermilion)
                    .accessibilityHidden(true)
            }

            section("Signs of a low", symbol: "exclamationmark.triangle.fill", color: Theme.vermilion) {
                Text("Shaky · sweaty · pale · hungry · headache · grumpy or confused · sleepy · trouble concentrating")
            }

            section("If low (below \(settings.formattedGlucose(settings.targetLow))) or showing signs", symbol: "1.circle.fill", color: Theme.vermilion) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("1. Give 15 g of fast sugar: 4 oz juice, 4 glucose tabs, or regular soda.")
                    Text("2. Wait 15 minutes, then check again.")
                    Text("3. Still low? Repeat. Once back in range, have a snack if a meal is more than an hour away.")
                    Text("4. Call the grown-up below.")
                }
            }

            section("Emergency", symbol: "phone.fill", color: Theme.vermilion) {
                Text("Can't swallow, passed out or having a seizure: call 911. Don't give food or drink. Use glucagon if prescribed.")
                    .fontWeight(.semibold)
            }

            section("Ranges", symbol: "target", color: Theme.green) {
                Text("Low below \(settings.formattedGlucose(settings.targetLow)) · Target \(settings.glucoseValueString(settings.targetLow))–\(settings.formattedGlucose(settings.targetHigh)) · High above \(settings.formattedGlucose(settings.targetHigh))")
            }

            if let contact = settings.grownUpContact {
                section("Call", symbol: "person.fill", color: Theme.green) {
                    Text("\(contact.name): \(contact.phone)")
                        .font(.title3.weight(.semibold).monospacedDigit())
                }
            }

            if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                section("Notes", symbol: "note.text", color: Theme.soft) {
                    Text(notes)
                }
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(20)
        .background(Theme.card, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.vermilion, lineWidth: 2))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("schoolCard")
    }

    private func section(_ title: String, symbol: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(color)
            content()
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack { SchoolCardView() }
        .environment(SettingsStore())
}
