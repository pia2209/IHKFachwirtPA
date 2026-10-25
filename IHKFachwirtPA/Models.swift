import Foundation

enum ExamPart: String, CaseIterable, Codable, Identifiable {
    case wirtschaft = "Wirtschaftsbezogene Qualifikationen"
    case technik = "Technische Qualifikationen"
    case handlung = "Handlungsspezifische Qualifikationen"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .wirtschaft: return "Wirtschaft"
        case .technik: return "Technik"
        case .handlung: return "Handlung"
        }
    }
}

struct LearningTopic: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let part: ExamPart
    let icon: String
}

struct Flashcard: Identifiable, Hashable, Codable {
    let id: UUID
    let topicID: String
    let question: String
    let answer: String
    var mastery: Int
    var nextReview: Date
    var intervalDays: Int

    init(
        id: UUID = UUID(),
        topicID: String,
        question: String,
        answer: String,
        mastery: Int = 0,
        nextReview: Date = .now,
        intervalDays: Int = 0
    ) {
        self.id = id
        self.topicID = topicID
        self.question = question
        self.answer = answer
        self.mastery = mastery
        self.nextReview = nextReview
        self.intervalDays = intervalDays
    }
}

struct QuizQuestion: Identifiable, Hashable, Codable {
    let topicID: String
    let question: String
    let answers: [String]
    let correctIndex: Int
    let explanation: String

    var id: String { "\(topicID)|\(question)" }

    init(
        topicID: String,
        question: String,
        answers: [String],
        correctIndex: Int,
        explanation: String
    ) {
        self.topicID = topicID
        self.question = question
        self.answers = answers
        self.correctIndex = correctIndex
        self.explanation = explanation
    }
}

struct StudySession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let answered: Int
    let correct: Int

    init(id: UUID = UUID(), date: Date = .now, answered: Int, correct: Int) {
        self.id = id
        self.date = date
        self.answered = answered
        self.correct = correct
    }
}

struct TopicProgress: Codable, Hashable {
    var answered: Int = 0
    var correct: Int = 0

    var accuracy: Double {
        guard answered > 0 else { return 0 }
        return Double(correct) / Double(answered)
    }
}

struct LearningSnapshot: Codable {
    var streak: Int
    var dailyGoal: Int
    var answeredToday: Int
    var totalAnswered: Int
    var totalCorrect: Int
    var lastStudyDay: Date?
    var flashcards: [Flashcard]
    var topicProgress: [String: TopicProgress]
    var sessions: [StudySession]
    var examDate: Date?
}

struct ExamResult: Identifiable {
    let id = UUID()
    let answered: Int
    let correct: Int
    let durationSeconds: Int

    var percentage: Int {
        guard answered > 0 else { return 0 }
        return Int((Double(correct) / Double(answered) * 100).rounded())
    }
}

struct CalculationQuestion: Identifiable, Hashable, Codable {
    let id: UUID
    let topicID: String
    let title: String
    let prompt: String
    let expectedValue: Double
    let tolerance: Double
    let unit: String
    let formulaHint: String
    let solution: String
    let points: Int

    init(
        id: UUID = UUID(),
        topicID: String,
        title: String,
        prompt: String,
        expectedValue: Double,
        tolerance: Double = 0.01,
        unit: String,
        formulaHint: String,
        solution: String,
        points: Int = 5
    ) {
        self.id = id
        self.topicID = topicID
        self.title = title
        self.prompt = prompt
        self.expectedValue = expectedValue
        self.tolerance = tolerance
        self.unit = unit
        self.formulaHint = formulaHint
        self.solution = solution
        self.points = points
    }
}

struct ExamSectionResult: Identifiable, Hashable {
    let id = UUID()
    let topicID: String
    let topicTitle: String
    let earnedPoints: Int
    let possiblePoints: Int

    var percentage: Int {
        guard possiblePoints > 0 else { return 0 }
        return Int((Double(earnedPoints) / Double(possiblePoints) * 100).rounded())
    }

    var passed: Bool { percentage >= 50 }
}

struct IHKExamResult: Identifiable {
    let id = UUID()
    let sections: [ExamSectionResult]
    let durationSeconds: Int

    var earnedPoints: Int { sections.reduce(0) { $0 + $1.earnedPoints } }
    var possiblePoints: Int { sections.reduce(0) { $0 + $1.possiblePoints } }
    var percentage: Int {
        guard possiblePoints > 0 else { return 0 }
        return Int((Double(earnedPoints) / Double(possiblePoints) * 100).rounded())
    }
    var passed: Bool { !sections.isEmpty && sections.allSatisfy(\.passed) }
}
