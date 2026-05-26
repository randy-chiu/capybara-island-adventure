import Foundation
import SwiftUI

enum MainDestination: String, CaseIterable {
    case map = "海岛地图"
    case mistakes = "错题本"
    case report = "家长报告"
    case settings = "设置"

    var symbol: String {
        switch self {
        case .map: return "map.fill"
        case .mistakes: return "book.closed.fill"
        case .report: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

enum AdventureFlow {
    case story
    case questions
    case reward
}

final class GameViewModel: ObservableObject {
    let bank: QuestionBank
    let chapters = AdventureContent.chapters
    let levels = AdventureContent.levels

    @Published var hasStarted = false
    @Published var destination: MainDestination = .map
    @Published var activeLevel: Level?
    @Published var activeQuestions: [Question] = []
    @Published var flow: AdventureFlow?
    @Published var isReviewChallenge = false
    @Published private(set) var progress: SavedProgress

    private let store: ProgressStore

    init(bank: QuestionBank = QuestionBank(), store: ProgressStore = ProgressStore()) {
        self.bank = bank
        self.store = store
        progress = store.load()
    }

    func enterIsland() {
        hasStarted = true
        destination = .map
    }

    func isUnlocked(_ level: Level) -> Bool {
        level.order == 1 || levels.prefix(level.order - 1).last.map { progress.completedLevelIDs.contains($0.id) } == true
    }

    func isCompleted(_ level: Level) -> Bool {
        progress.completedLevelIDs.contains(level.id)
    }

    func begin(_ level: Level) {
        guard isUnlocked(level) else { return }
        activeLevel = level
        activeQuestions = bank.questions(levelId: level.id)
        isReviewChallenge = false
        flow = .story
    }

    func beginQuestions() {
        flow = .questions
    }

    func review(_ question: Question) {
        activeLevel = levels.first { $0.id == question.levelId }
        activeQuestions = [question]
        isReviewChallenge = true
        flow = .questions
    }

    func closeAdventure() {
        activeLevel = nil
        activeQuestions = []
        flow = nil
        isReviewChallenge = false
    }

    func submit(_ answer: String, for question: Question, usedHintCount: Int) -> Bool {
        let cleanAnswer = normalized(answer)
        let allowed = ([question.correctAnswer] + question.acceptableAnswers).map(normalized)
        let correct = allowed.contains(cleanAnswer)
        let matchedError = correct ? nil : question.commonWrongAnswers.first(where: { normalized($0) == cleanAnswer })
        let error = correct ? nil : (matchedError.flatMap { _ in question.errorTypes.first } ?? question.errorTypes.first ?? "需要重新检查")
        progress.attempts.append(AttemptRecord(
            id: UUID(), questionId: question.id, answer: answer, isCorrect: correct,
            usedHintCount: usedHintCount, errorType: error, occurredAt: Date()
        ))
        if correct && isReviewChallenge {
            progress.masteredWrongQuestionIDs.insert(question.id)
        }
        persist()
        return correct
    }

    func feedback(for answer: String, question: Question) -> String {
        question.wrongAnswerFeedback.first { normalized($0.key) == normalized(answer) }?.value
            ?? "咦，我们发现了一个数学陷阱！先看看提示，再试一次。"
    }

    func completeCurrentLevel() {
        guard let level = activeLevel else { return }
        if isReviewChallenge {
            closeAdventure()
            destination = .mistakes
            return
        }
        if !progress.completedLevelIDs.contains(level.id) {
            progress.completedLevelIDs.insert(level.id)
            progress.rewards[level.reward.itemType, default: 0] += level.reward.amount
        }
        persist()
        flow = .reward
    }

    func finishReward() {
        closeAdventure()
        destination = .map
    }

    var wrongQuestions: [Question] {
        bank.recommendedReview(from: progress.attempts, mastered: progress.masteredWrongQuestionIDs)
    }

    func report(for date: Date = Date()) -> ParentReport {
        let todaysAttempts = progress.attempts.filter { Calendar.current.isDate($0.occurredAt, inSameDayAs: date) }
        let grouped = Dictionary(grouping: todaysAttempts, by: \.questionId)
        let questions = grouped.keys.compactMap(bank.question(id:))
        let correct = grouped.values.filter { $0.contains(where: \.isCorrect) }.count
        let errors = bank.errorCounts(from: todaysAttempts.filter { !$0.isCorrect })
        let skillStats = bank.skillAccuracy(from: todaysAttempts)
        let strengths = skillStats.filter { $0.1 >= 0.7 }.prefix(3).map(\.0)
        let weakQuestionIDs = Set(todaysAttempts.filter { !$0.isCorrect }.map(\.questionId))
        let weakCompetencies = questions.filter { weakQuestionIDs.contains($0.id) }.flatMap(\.coreCompetencies)
        let competencies = Array(Dictionary(grouping: weakCompetencies, by: { $0 }).keys).prefix(3).map { $0 }
        let topics = Array(Set(questions.map(\.topic))).sorted()
        let focus = errors.first?.0 ?? "路线图与图形表达"
        let suggestion = grouped.isEmpty
            ? "今天还没有探险记录。建议从椰子林关卡开始，用路线图热身。"
            : "建议明天先复习“\(focus)”相关讲解，再完成 2 道同类型挑战题。"
        return ParentReport(
            completedCount: grouped.count, correctCount: correct, wrongQuestionCount: weakQuestionIDs.count,
            topics: topics, strongSkills: Array(strengths), frequentErrors: errors,
            competenciesToBuild: Array(competencies), suggestion: suggestion
        )
    }

    func resetProgress() {
        progress = SavedProgress()
        store.erase()
        closeAdventure()
    }

    func updateSound(_ enabled: Bool) {
        progress.soundEnabled = enabled
        persist()
    }

    func updateAnimations(_ enabled: Bool) {
        progress.gentleAnimationsEnabled = enabled
        persist()
    }

    private func persist() {
        store.save(progress)
        objectWillChange.send()
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "平方米", with: "")
            .replacingOccurrences(of: "米/分", with: "")
            .replacingOccurrences(of: "分钟", with: "")
            .replacingOccurrences(of: "米", with: "")
            .replacingOccurrences(of: "篮", with: "")
            .replacingOccurrences(of: "度", with: "")
            .replacingOccurrences(of: "°", with: "")
            .lowercased()
    }
}
