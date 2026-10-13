//
//  SkillPathView.swift
//  DiabetesCare
//
//  "Your Path": where you are (Kid, Teen, Adult), the skills you've
//  learned, what each one opens up, and the step to the next stage when
//  you're ready. Moving up needs a grown-up.
//

import SwiftUI

struct SkillPathView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(ParentGate.self) private var gate
    @Environment(ParentLock.self) private var lock
    @Environment(\.managedObjectContext) private var viewContext
    @State private var progress = SkillProgress.Snapshot()
    @State private var quiz: Skill?
    @State private var movedUp = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PlantCard(growth: growth, streak: progress.streak)
                StageLadder(current: settings.stage)
                    .softPanel()
                if let next = settings.stage.next {
                    nextStageCard(next)
                }
                CardHeader("Skills")
                ForEach(Skill.allCases) { skill in
                    SkillRow(
                        skill: skill,
                        isDone: settings.completedSkills.contains(skill),
                        progress: progressText(for: skill),
                        unlocks: skill.unlocks(at: settings.stage)
                    ) {
                        if skill.isQuiz { quiz = skill }
                    }
                }
                StickerBook()
                Text("Skills are about knowing what to do and building habits. They never tell you how much insulin to take; that plan comes from your care team.")
                    .font(.footnote)
                    .foregroundStyle(Theme.soft)
            }
            .padding()
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .fontDesign(.rounded)
        .instrumentBackground()
        .navigationTitle("Your Path")
        .onAppear(perform: refresh)
        .sheet(item: $quiz, onDismiss: refresh) { skill in
            SkillQuizView(skill: skill)
        }
        .sensoryFeedback(.success, trigger: movedUp)
    }

    private var growth: SproutGrowth {
        settings.plantGrowth(streak: progress.streak)
    }

    private func refresh() {
        progress = SkillProgress.refresh(context: viewContext, settings: settings)
    }

    private func progressText(for skill: Skill) -> String? {
        guard skill == .steadyLogger else { return nil }
        return String(localized: "\(min(progress.streak, SkillHabits.streakGoal)) of \(SkillHabits.streakGoal) days")
    }

    private func nextStageCard(_ next: CareStage) -> some View {
        let needed = settings.stage.skillsToMoveUp
        let done = needed.filter(settings.completedSkills.contains).count
        let ready = settings.stage.isReadyToMoveUp(completed: settings.completedSkills)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(ready ? "Ready for \(next.title)" : "Next: \(next.title)", systemImage: next.symbol)
                    .font(.headline)
                    .foregroundStyle(ready ? Theme.green : Theme.ink)
                Spacer()
                Text("\(done) of \(needed.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.soft)
            }
            ProgressView(value: Double(done), total: Double(max(needed.count, 1)))
                .tint(Theme.green)
            Text(ready
                 ? String(localized: "You've learned what you need. A grown-up can move you up now.")
                 : String(localized: "Learn the skills below to get ready. \(next.summary)"))
                .font(.subheadline)
                .foregroundStyle(Theme.soft)
                .fixedSize(horizontal: false, vertical: true)
            if ready {
                Button("Move Up to \(next.title)") {
                    gate.run(.changeStage) { moveUp(to: next) }
                }
                .buttonStyle(.soft)
                .accessibilityIdentifier("moveUpStage")
            }
        }
        .softPanel(border: ready ? Theme.green : Theme.rule)
    }

    private func moveUp(to next: CareStage) {
        withAnimation(.smooth) { settings.careStage = next }
        if !next.hasParentLock { lock.removePasscode() }
        movedUp += 1
    }
}

/// Kid → Teen → Adult, with the current stage filled in.
struct StageLadder: View {
    let current: CareStage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // At the largest text sizes the three steps stack instead.
            ViewThatFits(in: .horizontal) {
                ladder
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(CareStage.allCases, id: \.self) { stage in
                        Label(stage.title, systemImage: isReached(stage) ? "checkmark.circle.fill" : "circle")
                            .font(.headline.weight(stage == current ? .bold : .regular))
                            .foregroundStyle(stage == current ? Theme.green : (isReached(stage) ? Theme.ink : Theme.soft))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Stage: \(current.title)")
            }

            Text(current.summary)
                .font(.subheadline)
                .foregroundStyle(Theme.soft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var ladder: some View {
        HStack(spacing: 0) {
            ForEach(Array(CareStage.allCases.enumerated()), id: \.element) { index, stage in
                if index > 0 {
                    Rectangle()
                        .fill(isReached(stage) ? Theme.green : Theme.rule)
                        .frame(height: 3)
                }
                VStack(spacing: 6) {
                    Image(systemName: stage.symbol)
                        .font(.title3)
                        .foregroundStyle(isReached(stage) ? Theme.onAccent : Theme.soft)
                        .frame(width: 48, height: 48)
                        .background(isReached(stage) ? Theme.green : Theme.card, in: .circle)
                        .overlay(Circle().strokeBorder(stage == current ? Theme.ink : Theme.rule, lineWidth: stage == current ? 2 : 1))
                    Text(stage.title)
                        .font(.caption.weight(stage == current ? .bold : .regular))
                        .foregroundStyle(stage == current ? Theme.ink : Theme.soft)
                }
                .fixedSize()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stage: \(current.title)")
        .accessibilityValue("\(CareStage.allCases.firstIndex(of: current).map { $0 + 1 } ?? 1) of \(CareStage.allCases.count)")
    }

    private func isReached(_ stage: CareStage) -> Bool {
        guard let a = CareStage.allCases.firstIndex(of: stage), let b = CareStage.allCases.firstIndex(of: current) else { return false }
        return a <= b
    }
}

struct SkillRow: View {
    let skill: Skill
    let isDone: Bool
    let progress: String?
    let unlocks: [Feature]
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isDone ? "checkmark" : skill.symbol)
                    .font(.headline)
                    .foregroundStyle(isDone ? Theme.onAccent : Theme.green)
                    .frame(width: 44, height: 44)
                    .background(isDone ? Theme.green : Theme.green.opacity(0.12), in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(skill.summary)
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                        .fixedSize(horizontal: false, vertical: true)
                    if !unlocks.isEmpty {
                        Label("Opens: \(unlocks.map(\.approvalReason).formatted(.list(type: .and)))", systemImage: "lock.open")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.amber)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                status
            }
            .softPanel()
        }
        .buttonStyle(SetupOptionButtonStyle())
        .disabled(!skill.isQuiz)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isDone ? "Learned" : (progress ?? (skill.isQuiz ? "Not yet" : "In progress")))
        .accessibilityHint(skill.isQuiz ? (isDone ? "Take the check again" : "Take a 3-question check") : "")
        .accessibilityIdentifier("skill.\(skill.rawValue)")
    }

    @ViewBuilder
    private var status: some View {
        if isDone {
            Text("Learned")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.green)
        } else if let progress {
            Text(progress)
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.soft)
        } else if skill.isQuiz {
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.soft)
        } else {
            Text("Habit")
                .font(.caption)
                .foregroundStyle(Theme.soft)
        }
    }
}

/// The plant at the top of Your Path, with what helps it grow.
struct PlantCard: View {
    let growth: SproutGrowth
    let streak: Int

    var body: some View {
        HStack(spacing: 16) {
            SproutView(growth: growth, size: 110)
            VStack(alignment: .leading, spacing: 6) {
                Text(growth.name)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.green)
                    .contentTransition(.opacity)
                Text(growth == .flower
                     ? String(localized: "Fully grown. Keep it blooming with your daily logs.")
                     : String(localized: "Skills, stickers and logging every day help your plant grow."))
                    .font(.subheadline)
                    .foregroundStyle(Theme.soft)
                    .fixedSize(horizontal: false, vertical: true)
                if streak > 0 {
                    Label("\(streak)-day streak", systemImage: "flame.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.amber)
                }
            }
            Spacer(minLength: 0)
        }
        .softPanel()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("plantCard")
    }
}
