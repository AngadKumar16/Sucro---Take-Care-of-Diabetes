//
//  DoctorQuestionsView.swift
//  DiabetesCare
//
//  Questions saved whenever they come up, so none are forgotten at the
//  next appointment. Open questions are printed at the end of the report.
//

import SwiftUI

struct DoctorQuestionsView: View {
    @State private var kit = KitStore.shared
    @State private var draft = ""
    @FocusState private var draftFocused: Bool

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Ask the doctor about…", text: $draft, axis: .vertical)
                        .focused($draftFocused)
                        .submitLabel(.done)
                        .onSubmit(add)
                        .accessibilityIdentifier("questionField")
                    Button("Add", systemImage: "plus.circle.fill", action: add)
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } footer: {
                Text("Questions you haven't asked yet are added to the end of your PDF report.")
            }
            .listRowBackground(Theme.card)

            if !kit.questions.isEmpty {
                Section("Questions") {
                    ForEach(kit.questions) { question in
                        Button {
                            withAnimation { kit.toggleAsked(question) }
                        } label: {
                            Label {
                                Text(question.text)
                                    .strikethrough(question.asked)
                                    .foregroundStyle(question.asked ? .secondary : .primary)
                            } icon: {
                                Image(systemName: question.asked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Theme.green)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .accessibilityValue(question.asked ? "Asked" : "Not asked yet")
                    }
                    .onDelete { kit.removeQuestions(at: $0, in: kit.questions) }
                }
                .listRowBackground(Theme.card)
            }
        }
        .instrumentBackground()
        .navigationTitle("Doctor Visit")
        .sensoryFeedback(.selection, trigger: kit.questions.map(\.asked))
    }

    private func add() {
        withAnimation { kit.addQuestion(draft) }
        draft = ""
    }
}

#Preview {
    NavigationStack { DoctorQuestionsView() }
}
