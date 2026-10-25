import SwiftUI

struct CalculationView: View {
    @Environment(LearningStore.self) private var store
    @State private var selectedTopicID: String?
    @State private var questions: [CalculationQuestion] = []
    @State private var index = 0
    @State private var input = ""
    @State private var checked = false
    @State private var isCorrect = false
    @State private var correctCount = 0
    @State private var finished = false
    @State private var showHint = false

    var body: some View {
        Group {
            if finished {
                resultView
            } else if questions.isEmpty {
                setupView
            } else {
                sessionView
            }
        }
        .navigationTitle("Rechentraining")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var setupView: some View {
        Form {
            Section("Aufgabenbereich") {
                Picker("Thema", selection: $selectedTopicID) {
                    Text("Gemischt").tag(Optional<String>.none)
                    ForEach(store.topics.filter { topic in
                        store.calculationQuestions.contains { $0.topicID == topic.id }
                    }) { topic in
                        Text(topic.title).tag(Optional(topic.id))
                    }
                }
            }
            Section("So funktioniert es") {
                Label("Ergebnis selbst berechnen und eingeben", systemImage: "square.and.pencil")
                Label("Formelhinweis bei Bedarf einblendbar", systemImage: "lightbulb")
                Label("Lösungsweg nach der Abgabe", systemImage: "list.number")
            }
            Section {
                let available = store.calculationQuestions.filter { selectedTopicID == nil || $0.topicID == selectedTopicID }.count
                Button(available == 0 ? "Keine Aufgaben vorhanden" : "\(min(10, available)) Rechenaufgaben starten") {
                    start()
                }
                .disabled(available == 0)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var sessionView: some View {
        let question = questions[index]
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(store.topic(for: question.topicID)?.title ?? "Rechnen")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(index + 1)/\(questions.count)")
                        .font(.headline.monospacedDigit())
                }

                ProgressView(value: Double(index + 1), total: Double(questions.count))

                Text(question.title).font(.title2.bold())
                Text(question.prompt).font(.body)

                if showHint && !checked {
                    Label(question.formulaHint, systemImage: "function")
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }

                HStack {
                    TextField("Ergebnis", text: $input)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Text(question.unit).foregroundStyle(.secondary)
                }

                if !checked {
                    HStack {
                        Button(showHint ? "Hinweis ausblenden" : "Formelhinweis") { showHint.toggle() }
                            .buttonStyle(.bordered)
                        Spacer()
                        Button("Prüfen") { check(question) }
                            .buttonStyle(.borderedProminent)
                            .disabled(parsedInput == nil)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(isCorrect ? "Richtig" : "Noch nicht richtig", systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(isCorrect ? .green : .red)
                        Text("Richtiges Ergebnis: \(formatted(question.expectedValue)) \(question.unit)")
                            .font(.headline)
                        Text(question.solution)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                    Button(index + 1 == questions.count ? "Auswertung" : "Nächste Aufgabe") { advance() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
        }
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Image(systemName: correctCount >= questions.count / 2 ? "checkmark.seal.fill" : "function")
                .font(.system(size: 60))
            Text("Rechentraining beendet").font(.title.bold())
            Text("\(correctCount) von \(questions.count) richtig")
                .font(.title2.bold())
            Text("Wiederhole besonders die Formeln, bei denen du einen Hinweis benötigt oder falsch gerechnet hast.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Neue Runde") {
                questions = []
                finished = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var parsedInput: Double? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        if text.hasSuffix(".") { text.removeLast() }
        guard !text.isEmpty else { return nil }
        return Double(text)
    }

    private func start() {
        let pool = store.calculationQuestions.filter { selectedTopicID == nil || $0.topicID == selectedTopicID }
        questions = Array(pool.shuffled().prefix(min(10, pool.count)))
        index = 0
        input = ""
        checked = false
        correctCount = 0
        finished = false
        showHint = false
    }

    private func check(_ question: CalculationQuestion) {
        guard let value = parsedInput else { return }
        let allowed = max(question.tolerance, abs(question.expectedValue) * 0.002)
        isCorrect = abs(value - question.expectedValue) <= allowed
        if isCorrect { correctCount += 1 }
        checked = true
        store.registerAnswer(topicID: question.topicID, correct: isCorrect)
    }

    private func advance() {
        if index + 1 >= questions.count {
            store.finishSession(answered: questions.count, correct: correctCount)
            finished = true
        } else {
            index += 1
            input = ""
            checked = false
            isCorrect = false
            showHint = false
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}
