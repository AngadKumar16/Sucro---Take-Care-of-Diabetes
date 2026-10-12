//
//  SkillQuizView.swift
//  DiabetesCare
//
//  Three questions after a guide. One at a time, with the reason shown
//  after each answer. All three right finishes the skill.
//

import SwiftUI

struct SkillQuizView: View {
    let skill: Skill

    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    @State private var index = 0
    @State private var chosen: Int?
    @State private var correct = 0
    @State private var showGuide = false
    @State private var finished = false

    private var questions: [QuizQuestion] { skill.questions }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if finished {
                        result
                    } else if index < questions.count {
                        question(questions[index])
                    }
                }
                .padding(20)
                .frame(maxWidth: 600, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .fontDesign(.rounded)
            .instrumentBackground()
            .navigationTitle(skill.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showGuide) {
                if let guide = skill.guide { GuideSheet(guide: guide) }
            }
            .sensoryFeedback(.success, trigger: finished) { _, done in done && correct == questions.count }
        }
    }

    private func question(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Question \(index + 1) of \(questions.count)")
                    .friendlyLabel()
                Spacer()
                if skill.guide != nil {
                    Button("Read the Guide", systemImage: "book") { showGuide = true }
                        .font(.subheadline)
                }
            }
            ProgressView(value: Double(index), total: Double(questions.count))
                .tint(Theme.green)
            Text(question.prompt)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(question.options.enumerated()), id: \.offset) { option, text in
                Button { answer(option, for: question) } label: {
                    HStack(spacing: 12) {
                        Text(text)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        if let chosen, option == question.answer {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green)
                                .accessibilityLabel(chosen == option ? "Correct" : "Right answer")
                        } else if chosen == option {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.vermilion)
                                .accessibilityLabel("Not quite")
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(background(for: option, question: question), in: .rect(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.rule, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.ink)
                .disabled(chosen != nil)
                .accessibilityIdentifier("quiz.option.\(option)")
            }

            if chosen != nil {
                Text(question.explanation)
                    .foregroundStyle(Theme.soft)
                    .fixedSize(horizontal: false, vertical: true)
                Button(index + 1 < questions.count ? "Next Question" : "See How You Did", action: next)
                    .buttonStyle(.soft)
            }
        }
    }

    private func background(for option: Int, question: QuizQuestion) -> Color {
        guard let chosen else { return Theme.card }
        if option == question.answer { return Theme.green.opacity(0.15) }
        if option == chosen { return Theme.vermilion.opacity(0.12) }
        return Theme.card
    }

    @ViewBuilder
    private var result: some View {
        let passed = correct == questions.count
        VStack(spacing: 16) {
            Image(systemName: passed ? "star.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(passed ? Theme.green : Theme.amber)
                .accessibilityHidden(true)
            Text(passed ? "Skill Learned!" : "\(correct) of \(questions.count) Right")
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text(passed
                 ? String(localized: "\(skill.title) is done. Nice work.")
                 : String(localized: "Read the guide again and try once more. You need all \(questions.count)."))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.soft)
            if passed {
                Button("Done") { dismiss() }
                    .buttonStyle(.soft)
            } else {
                Button("Try Again", action: restart)
                    .buttonStyle(.soft)
                if skill.guide != nil {
                    Button("Read the Guide") { showGuide = true }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func answer(_ option: Int, for question: QuizQuestion) {
        withAnimation(.snappy) { chosen = option }
        if option == question.answer { correct += 1 }
    }

    private func next() {
        withAnimation(.smooth) {
            chosen = nil
            if index + 1 < questions.count {
                index += 1
            } else {
                finished = true
                if correct == questions.count { settings.complete(skill) }
            }
        }
    }

    private func restart() {
        withAnimation(.smooth) {
            index = 0
            correct = 0
            chosen = nil
            finished = false
        }
    }
}

#Preview {
    SkillQuizView(skill: .treatingLows)
        .environment(SettingsStore(defaults: UserDefaults(suiteName: "preview")!))
}
