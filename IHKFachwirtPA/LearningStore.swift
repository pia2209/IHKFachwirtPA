import Foundation
import Observation

@MainActor
@Observable
final class LearningStore {
    private(set) var snapshot: LearningSnapshot

    init() {
        if let loaded = Self.load() {
            snapshot = loaded
            mergeNewFlashcards()
            normalizeForNewDay()
        } else {
            snapshot = Self.fresh()
        }
        persist()
    }

    var topics: [LearningTopic] { QuestionBank.topics }
    var quizQuestions: [QuizQuestion] { QuestionBank.baseQuestions }
    var calculationQuestions: [CalculationQuestion] { QuestionBank.calculationQuestions }
    var flashcards: [Flashcard] { snapshot.flashcards }
    var sessions: [StudySession] { snapshot.sessions }
    var streak: Int { snapshot.streak }
    var dailyGoal: Int { snapshot.dailyGoal }
    var answeredToday: Int { snapshot.answeredToday }
    var totalAnswered: Int { snapshot.totalAnswered }
    var examDate: Date? { snapshot.examDate }

    var dueFlashcards: [Flashcard] {
        snapshot.flashcards.filter { $0.nextReview <= .now }
    }

    var accuracy: Double {
        guard snapshot.totalAnswered > 0 else { return 0 }
        return Double(snapshot.totalCorrect) / Double(snapshot.totalAnswered)
    }

    var goalProgress: Double {
        guard snapshot.dailyGoal > 0 else { return 0 }
        return min(1, Double(snapshot.answeredToday) / Double(snapshot.dailyGoal))
    }

    var daysUntilExam: Int? {
        guard let examDate = snapshot.examDate else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let exam = calendar.startOfDay(for: examDate)
        guard let days = calendar.dateComponents([.day], from: start, to: exam).day else { return nil }
        return max(0, days)
    }

    var wrongQuestions: [QuizQuestion] {
        snapshot.wrongQuestionIDs.compactMap { id in quizQuestions.first { $0.id == id } }
    }

    var favoriteQuestions: [QuizQuestion] {
        snapshot.favoriteQuestionIDs.compactMap { id in quizQuestions.first { $0.id == id } }
    }

    var weakestTopics: [LearningTopic] {
        topics.sorted { progress(for: $0.id) < progress(for: $1.id) }
    }

    var achievements: [Achievement] {
        let masteredCards = snapshot.flashcards.filter { $0.mastery >= 4 }.count
        return [
            Achievement(id: "first", title: "Erster Schritt", subtitle: "Erste Aufgabe beantwortet", icon: "flag.fill", unlocked: totalAnswered >= 1),
            Achievement(id: "goal", title: "Tagesziel", subtitle: "Heute das Tagesziel geschafft", icon: "target", unlocked: dailyGoal > 0 && answeredToday >= dailyGoal),
            Achievement(id: "streak3", title: "Dranbleiben", subtitle: "3 Tage in Folge gelernt", icon: "flame.fill", unlocked: streak >= 3),
            Achievement(id: "streak7", title: "Lernwoche", subtitle: "7 Tage in Folge gelernt", icon: "calendar", unlocked: streak >= 7),
            Achievement(id: "fifty", title: "50 Aufgaben", subtitle: "50 Antworten gesammelt", icon: "checkmark.circle.fill", unlocked: totalAnswered >= 50),
            Achievement(id: "accuracy", title: "Sicher im Stoff", subtitle: "Mindestens 80 % bei 20 Antworten", icon: "scope", unlocked: totalAnswered >= 20 && accuracy >= 0.8),
            Achievement(id: "cards", title: "Karten im Griff", subtitle: "10 Karten auf Stufe 4 oder höher", icon: "rectangle.stack.fill", unlocked: masteredCards >= 10),
            Achievement(id: "favorite", title: "Merkliste", subtitle: "Eine Frage als Favorit gespeichert", icon: "star.fill", unlocked: !snapshot.favoriteQuestionIDs.isEmpty)
        ]
    }

    var unlockedAchievementCount: Int {
        achievements.filter(\.unlocked).count
    }

    func topic(for id: String) -> LearningTopic? {
        topics.first { $0.id == id }
    }

    func progress(for topicID: String) -> Double {
        let stats = snapshot.topicProgress[topicID] ?? TopicProgress()
        let cards = snapshot.flashcards.filter { $0.topicID == topicID }
        let mastery = cards.isEmpty ? 0 : Double(cards.reduce(0) { $0 + $1.mastery }) / Double(cards.count * 5)
        guard stats.answered > 0 else { return mastery }
        return min(1, stats.accuracy * 0.75 + mastery * 0.25)
    }

    func questions(topicID: String?) -> [QuizQuestion] {
        guard let topicID else { return quizQuestions }
        return quizQuestions.filter { $0.topicID == topicID }
    }

    func setDailyGoal(_ goal: Int) {
        snapshot.dailyGoal = min(100, max(5, goal))
        persist()
    }

    func setExamDate(_ date: Date?) {
        snapshot.examDate = date
        persist()
    }

    func updateMastery(cardID: UUID, knewIt: Bool) {
        guard let index = snapshot.flashcards.firstIndex(where: { $0.id == cardID }) else { return }
        let topicID = snapshot.flashcards[index].topicID
        if knewIt {
            snapshot.flashcards[index].mastery = min(5, snapshot.flashcards[index].mastery + 1)
            let current = snapshot.flashcards[index].intervalDays
            let interval = min(60, max(1, current == 0 ? 1 : current * 2))
            snapshot.flashcards[index].intervalDays = interval
            snapshot.flashcards[index].nextReview = Calendar.current.date(byAdding: .day, value: interval, to: .now) ?? .now
        } else {
            snapshot.flashcards[index].mastery = max(0, snapshot.flashcards[index].mastery - 1)
            snapshot.flashcards[index].intervalDays = 0
            snapshot.flashcards[index].nextReview = .now
        }
        recordActivity(correct: knewIt, topicID: topicID)
        persist()
    }

    func registerAnswer(topicID: String, correct: Bool) {
        recordActivity(correct: correct, topicID: topicID)
        persist()
    }

    func registerQuizAnswer(question: QuizQuestion, correct: Bool) {
        recordActivity(correct: correct, topicID: question.topicID)
        if correct {
            snapshot.wrongQuestionIDs.removeAll { $0 == question.id }
        } else if !snapshot.wrongQuestionIDs.contains(question.id) {
            snapshot.wrongQuestionIDs.insert(question.id, at: 0)
        }
        persist()
    }

    func clearWrongQuestions() {
        snapshot.wrongQuestionIDs = []
        persist()
    }

    func isFavorite(_ id: String) -> Bool {
        snapshot.favoriteQuestionIDs.contains(id)
    }

    func toggleFavorite(_ id: String) {
        if let index = snapshot.favoriteQuestionIDs.firstIndex(of: id) {
            snapshot.favoriteQuestionIDs.remove(at: index)
        } else {
            snapshot.favoriteQuestionIDs.insert(id, at: 0)
        }
        persist()
    }

    func finishSession(answered: Int, correct: Int) {
        guard answered > 0 else { return }
        snapshot.sessions.append(StudySession(answered: answered, correct: correct))
        if snapshot.sessions.count > 100 {
            snapshot.sessions.removeFirst(snapshot.sessions.count - 100)
        }
        persist()
    }

    func resetProgress() {
        let goal = snapshot.dailyGoal
        let examDate = snapshot.examDate
        let favorites = snapshot.favoriteQuestionIDs
        snapshot = Self.fresh()
        snapshot.dailyGoal = goal
        snapshot.examDate = examDate
        snapshot.favoriteQuestionIDs = favorites
        persist()
    }

    func rollDayIfNeeded() {
        normalizeForNewDay()
        persist()
    }

    private func recordActivity(correct: Bool, topicID: String) {
        normalizeForNewDay()
        let calendar = Calendar.current
        if let last = snapshot.lastStudyDay, calendar.isDateInToday(last) {
            // Der Streak für heute ist bereits gezählt.
        } else if let last = snapshot.lastStudyDay, calendar.isDateInYesterday(last) {
            snapshot.streak += 1
        } else {
            snapshot.streak = 1
        }

        snapshot.lastStudyDay = .now
        snapshot.answeredToday += 1
        snapshot.totalAnswered += 1
        if correct { snapshot.totalCorrect += 1 }

        var progress = snapshot.topicProgress[topicID] ?? TopicProgress()
        progress.answered += 1
        if correct { progress.correct += 1 }
        snapshot.topicProgress[topicID] = progress
    }

    private func normalizeForNewDay() {
        guard let last = snapshot.lastStudyDay, !Calendar.current.isDateInToday(last) else { return }
        snapshot.answeredToday = 0
        if !Calendar.current.isDateInYesterday(last) {
            snapshot.streak = 0
        }
    }

    private func mergeNewFlashcards() {
        let known = Set(snapshot.flashcards.map(\.question))
        let missing = QuestionBank.flashcards.filter { !known.contains($0.question) }
        guard !missing.isEmpty else { return }
        snapshot.flashcards.append(contentsOf: missing)
    }

    private func persist() {
        do {
            let url = Self.storeURL
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
        } catch {
            // Der aktuelle Stand bleibt für diese Sitzung im Speicher.
        }
    }

    private static func load() -> LearningSnapshot? {
        guard let data = try? Data(contentsOf: storeURL) else { return nil }
        return try? JSONDecoder().decode(LearningSnapshot.self, from: data)
    }

    private static func fresh() -> LearningSnapshot {
        LearningSnapshot(
            streak: 0,
            dailyGoal: 20,
            answeredToday: 0,
            totalAnswered: 0,
            totalCorrect: 0,
            lastStudyDay: nil,
            flashcards: QuestionBank.flashcards,
            topicProgress: [:],
            sessions: [],
            examDate: nil,
            favoriteQuestionIDs: [],
            wrongQuestionIDs: []
        )
    }

    private static var storeURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent("IHKFachwirtPA", isDirectory: true)
            .appendingPathComponent("learning.json")
    }
}
