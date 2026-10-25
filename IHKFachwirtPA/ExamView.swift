import SwiftUI
import Combine

struct ExamView: View {
    @Environment(LearningStore.self) private var store
    @State private var selectedPart: ExamPart? = nil
    @State private var questionCount = 40
    @State private var duration = 60
    @State private var questions: [QuizQuestion] = []
    @State private var answers: [String: Int] = [:]
    @State private var index = 0
    @State private var secondsRemaining = 0
    @State private var started = false
    @State private var result: IHKExamResult?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let result {
                resultView(result)
            } else if started {
                examSession
            } else {
                examSetup
            }
        }
        .navigationTitle("Prüfung")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            guard started, result == nil else { return }
            if secondsRemaining > 0 { secondsRemaining -= 1 } else { finishExam() }
        }
    }

    private var examSetup: some View {
        Form {
            Section("Prüfungsteil") {
                Picker("Bereich", selection: $selectedPart) {
                    Text("Gesamttraining").tag(Optional<ExamPart>.none)
                    ForEach(ExamPart.allCases) { part in
                        Text(part.shortTitle).tag(Optional(part))
                    }
                }
            }

            Section("Simulation") {
                Picker("Fragen", selection: $questionCount) {
                    Text("20").tag(20)
                    Text("40").tag(40)
                    Text("60").tag(60)
                }
                Picker("Zeit", selection: $duration) {
                    Text("30 Minuten").tag(30)
                    Text("60 Minuten").tag(60)
                    Text("90 Minuten").tag(90)
                }
            }

            Section("IHK-orientierte Auswertung") {
                Label("Jeder bewertete Bereich wird auf 100 Punkte skaliert", systemImage: "100.circle")
                Label("Bestehensgrenze: mindestens 50 Punkte", systemImage: "checkmark.seal")
                Label("WBQ und TQ werden je Qualifikationsbereich ausgewertet", systemImage: "square.grid.2x2")
                Label("HSQ wird hier als schriftliche Situationsaufgabe zusammengefasst", systemImage: "doc.text")
            }

            Section {
                Text("Die echte IHK-Prüfung enthält überwiegend offene bzw. situationsbezogene Aufgaben. Diese Multiple-Choice-Simulation trainiert Wissen und Punkteorientierung, bildet die Originalprüfung aber nicht 1:1 ab.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Simulation starten") { startExam() }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var examSession: some View {
        VStack(spacing: 0) {
            HStack {
                Label(timeString, systemImage: "timer")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text("\(index + 1)/\(questions.count)")
                    .font(.headline.monospacedDigit())
            }
            .padding()

            ProgressView(value: Double(index + 1), total: Double(max(questions.count, 1)))
                .padding(.horizontal)

            ScrollView {
                if !questions.isEmpty {
                    let question = questions[index]
                    VStack(alignment: .leading, spacing: 18) {
                        Text(store.topic(for: question.topicID)?.title ?? "Thema")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(question.question)
                            .font(.title2.bold())

                        ForEach(Array(question.answers.enumerated()), id: \.offset) { answerIndex, answer in
                            Button {
                                answers[question.id] = answerIndex
                            } label: {
                                HStack {
                                    Image(systemName: answers[question.id] == answerIndex ? "largecircle.fill.circle" : "circle")
                                    Text(answer).multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }

                        HStack {
                            if index > 0 {
                                Button("Zurück") { index -= 1 }.buttonStyle(.bordered)
                            }
                            Spacer()
                            if index + 1 < questions.count {
                                Button("Weiter") { index += 1 }.buttonStyle(.borderedProminent)
                            } else {
                                Button("Abgeben") { finishExam() }.buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
        }
    }

    private func resultView(_ result: IHKExamResult) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: result.passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 62))
                    .foregroundStyle(result.passed ? .green : .orange)

                Text(result.passed ? "Simulation bestanden" : "Noch nicht bestanden")
                    .font(.title.bold())
                Text("\(result.percentage) Punkte")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("Gesamtwert der Trainingssimulation")
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    ForEach(result.sections) { section in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(section.topicTitle).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(section.percentage) P.")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(section.passed ? .green : .red)
                            }
                            ProgressView(value: Double(section.percentage), total: 100)
                            Text(section.passed ? "Bestehensgrenze erreicht" : "Unter 50 Punkten – gezielt wiederholen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bewertungsprinzip").font(.headline)
                    Text("Für dieses Training gilt: Ein einbezogener WBQ- oder TQ-Qualifikationsbereich muss mindestens 50 Punkte erreichen. Bei den handlungsspezifischen Qualifikationen fasst die App die vier Handlungsbereiche zu einer schriftlichen Situationsaufgabe zusammen. Die reale mündliche Leistung aus Fachgespräch und Präsentation ist hier noch nicht enthalten.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

                Button("Neue Simulation") {
                    self.result = nil
                    started = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var timeString: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    private func startExam() {
        let allowedTopicIDs: Set<String>
        if let selectedPart {
            allowedTopicIDs = Set(store.topics.filter { $0.part == selectedPart }.map(\.id))
        } else {
            allowedTopicIDs = Set(store.topics.map(\.id))
        }

        let pool = store.quizQuestions.filter { allowedTopicIDs.contains($0.topicID) }
        questions = balancedQuestions(from: pool, count: min(questionCount, pool.count))
        answers = [:]
        index = 0
        secondsRemaining = duration * 60
        result = nil
        started = true
    }

    private func balancedQuestions(from pool: [QuizQuestion], count: Int) -> [QuizQuestion] {
        let grouped = Dictionary(grouping: pool, by: \.topicID)
        var selected: [QuizQuestion] = []
        let topicIDs = Array(grouped.keys).shuffled()
        var queues = grouped.mapValues { $0.shuffled() }
        var cursor = 0

        while selected.count < count && !topicIDs.isEmpty {
            let topicID = topicIDs[cursor % topicIDs.count]
            if var queue = queues[topicID], !queue.isEmpty {
                selected.append(queue.removeFirst())
                queues[topicID] = queue
            }
            cursor += 1
            if cursor > count * max(topicIDs.count, 1) * 2 { break }
        }
        return selected.shuffled()
    }

    private func finishExam() {
        guard started else { return }
        var correct = 0
        for question in questions {
            let isCorrect = answers[question.id] == question.correctIndex
            if isCorrect { correct += 1 }
            if answers[question.id] != nil {
                store.registerQuizAnswer(question: question, correct: isCorrect)
            }
        }
        store.finishSession(answered: questions.count, correct: correct)

        let sectionResults = makeSectionResults()
        result = IHKExamResult(sections: sectionResults, durationSeconds: duration * 60 - secondsRemaining)
        started = false
    }

    private func makeSectionResults() -> [ExamSectionResult] {
        var output: [ExamSectionResult] = []
        let groupedByPart = Dictionary(grouping: questions) { question in
            store.topic(for: question.topicID)?.part
        }

        for part in ExamPart.allCases {
            guard let partQuestions = groupedByPart[Optional(part)], !partQuestions.isEmpty else { continue }

            if part == .handlung {
                let answeredCorrectly = partQuestions.filter { answers[$0.id] == $0.correctIndex }.count
                output.append(.init(
                    topicID: "handlung-situation",
                    topicTitle: "Schriftliche Situationsaufgabe (HSQ-Training)",
                    earnedPoints: answeredCorrectly,
                    possiblePoints: partQuestions.count
                ))
            } else {
                let grouped = Dictionary(grouping: partQuestions, by: \.topicID)
                for topic in store.topics.filter({ $0.part == part }) {
                    guard let topicQuestions = grouped[topic.id], !topicQuestions.isEmpty else { continue }
                    let answeredCorrectly = topicQuestions.filter { answers[$0.id] == $0.correctIndex }.count
                    output.append(.init(
                        topicID: topic.id,
                        topicTitle: topic.title,
                        earnedPoints: answeredCorrectly,
                        possiblePoints: topicQuestions.count
                    ))
                }
            }
        }
        return output
    }
}
