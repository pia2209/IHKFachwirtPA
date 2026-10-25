import SwiftUI

struct QuizView: View {
    @Environment(LearningStore.self) private var store
    @State private var selectedTopicID: String?
    @State private var sessionQuestions: [QuizQuestion] = []
    @State private var index = 0
    @State private var selected: Int?
    @State private var answered = false
    @State private var correctCount = 0
    @State private var isRunning = false
    @State private var isFinished = false

    var body: some View {
        Group {
            if isFinished {
                quizResult
            } else if isRunning, !sessionQuestions.isEmpty {
                quizSession
            } else {
                setup
            }
        }
        .navigationTitle("Multiple Choice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var setup: some View {
        Form {
            Section("Lernmodus") {
                Picker("Thema", selection: $selectedTopicID) {
                    Text("Gemischt").tag(Optional<String>.none)
                    ForEach(store.topics) { topic in
                        Text(topic.title).tag(Optional(topic.id))
                    }
                }
            }

            Section("Fehlertraining") {
                if store.wrongQuestions.isEmpty {
                    Label("Aktuell keine offenen Fehlerfragen", systemImage: "checkmark.seal")
                        .foregroundStyle(.secondary)
                } else {
                    Button("\(store.wrongQuestions.count) Fehlerfragen wiederholen") { startErrorQuiz() }
                    Button("Fehlerliste leeren", role: .destructive) { store.clearWrongQuestions() }
                }
            }

            Section("Empfehlung") {
                Label("Direktes Feedback nach jeder Antwort", systemImage: "checkmark.bubble")
                Label("Fehler fließen in deine Schwächenanalyse ein", systemImage: "scope")
                Label("10 Fragen pro Lernblock", systemImage: "10.circle")
            }

            Section {
                Button("10 Fragen starten") { startQuiz(count: 10) }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var quizSession: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let question = sessionQuestions[index]

                HStack {
                    Text(store.topic(for: question.topicID)?.title ?? "Thema")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        store.toggleFavorite(question.id)
                    } label: {
                        Image(systemName: store.isFavorite(question.id) ? "star.fill" : "star")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(store.isFavorite(question.id) ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")

                    Text("\(index + 1)/\(sessionQuestions.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(index + 1), total: Double(sessionQuestions.count))

                Text(question.question)
                    .font(.title2.bold())

                ForEach(Array(question.answers.enumerated()), id: \.offset) { answerIndex, answer in
                    Button {
                        choose(answerIndex, question: question)
                    } label: {
                        HStack(alignment: .top) {
                            Text(answer)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if answered {
                                if answerIndex == question.correctIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if answerIndex == selected {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(answered)
                }

                if answered {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selected == question.correctIndex ? "Richtig" : "Noch nicht ganz")
                            .font(.headline)
                        Text(question.explanation)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    Button(index + 1 == sessionQuestions.count ? "Auswertung" : "Nächste Frage") {
                        advance()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
        }
    }

    private var quizResult: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "chart.bar.doc.horizontal.fill")
                .font(.system(size: 56))
            Text("Lernblock abgeschlossen")
                .font(.title.bold())
            Text("\(correctCount) von \(sessionQuestions.count) richtig")
                .font(.title2.monospacedDigit())
            Text("\(percentage)% Trefferquote")
                .foregroundStyle(.secondary)

            Button("Neuen Lernblock starten") {
                isFinished = false
                isRunning = false
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    private var percentage: Int {
        guard !sessionQuestions.isEmpty else { return 0 }
        return Int((Double(correctCount) / Double(sessionQuestions.count) * 100).rounded())
    }

    private func startQuiz(count: Int) {
        let pool = store.questions(topicID: selectedTopicID).shuffled()
        sessionQuestions = Array(pool.prefix(min(count, pool.count)))
        index = 0
        selected = nil
        answered = false
        correctCount = 0
        isRunning = true
        isFinished = false
    }

    private func startErrorQuiz() {
        sessionQuestions = Array(store.wrongQuestions.shuffled().prefix(20))
        index = 0
        selected = nil
        answered = false
        correctCount = 0
        isRunning = true
        isFinished = false
    }

    private func choose(_ answerIndex: Int, question: QuizQuestion) {
        guard !answered else { return }
        selected = answerIndex
        answered = true
        let correct = answerIndex == question.correctIndex
        if correct { correctCount += 1 }
        store.registerQuizAnswer(question: question, correct: correct)
    }

    private func advance() {
        if index + 1 >= sessionQuestions.count {
            store.finishSession(answered: sessionQuestions.count, correct: correctCount)
            isFinished = true
            isRunning = false
        } else {
            index += 1
            selected = nil
            answered = false
        }
    }
}
