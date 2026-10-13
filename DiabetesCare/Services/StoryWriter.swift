//
//  StoryWriter.swift
//  DiabetesCare
//
//  Rewords the day's story in a warmer voice with Apple's on-device model,
//  when the phone has Apple Intelligence. The template sentence is always
//  the source of truth: the model may only restate it, and its answer is
//  thrown away unless every number from the template is still there and
//  nothing reads like advice. Nothing leaves the phone.
//

import Foundation
import FoundationModels
import OSLog

@MainActor
enum StoryWriter {
    private static var cache: [String: String] = [:]

    /// The model's wording of `template`, or `nil` to keep the template.
    static func reword(_ template: String, stage: CareStage) async -> String? {
        let key = "\(stage.rawValue)|\(template)"
        if let cached = cache[key] { return cached }
        guard SystemLanguageModel.default.availability == .available else { return nil }

        let audience = switch stage {
        case .kid: "a child about 8 to 12 years old"
        case .teen: "a teenager"
        case .adult: "an adult"
        }
        let session = LanguageModelSession(instructions: """
            You rewrite a short summary of someone's glucose log so it sounds warm and encouraging, for \(audience) living with type 1 diabetes.
            Rules: keep every fact and every number exactly as given, including units and times. Add no new facts. \
            Give no advice, no instructions, and never mention insulin, doses or food choices. \
            At most two short sentences. No emoji. Reply with the rewritten summary only.
            """)
        do {
            let response = try await session.respond(to: template, options: GenerationOptions(temperature: 0.4))
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isFaithful(text, to: template) else { return nil }
            cache[key] = text
            return text
        } catch {
            Log.data.error("Story rewording failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// The safety check: every number in the template survives, it's not
    /// much longer, and nothing sounds like dosing or advice.
    nonisolated static func isFaithful(_ text: String, to template: String) -> Bool {
        guard !text.isEmpty, text.count <= template.count * 2 + 40 else { return false }
        let numbers = { (s: String) in
            Set(s.split(whereSeparator: { !$0.isNumber && $0 != "." && $0 != "," }).map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: ".,")) }.filter { !$0.isEmpty })
        }
        guard numbers(template).isSubset(of: numbers(text)) else { return false }
        let lowered = text.lowercased()
        let banned = ["insulin", "dose", "bolus", "units", "you should", "try to", "make sure", "eat ", "take "]
        return !banned.contains { lowered.contains($0) && !template.lowercased().contains($0) }
    }
}
