import Foundation

enum AnswerType: String, Codable {
    case multipleChoice, numericInput, equationInput, stepChoice
}

enum ReviewStatus: String, Codable {
    case draft, reviewed, approved
}

enum CopyrightStatus: String, Codable {
    case original, adapted, teacherCreated, licensed, publicDomain, unknown
}

enum VisualType: String, Codable {
    case none, route, meet, chase, boat, rectangle, compositeShape, angle
}

enum RewardItemType: String, Codable, CaseIterable {
    case coconut, wood, shell, fish, shrimp, mapPiece

    var title: String {
        switch self {
        case .coconut: return "椰子"
        case .wood: return "木材"
        case .shell: return "贝壳"
        case .fish: return "小鱼"
        case .shrimp: return "小虾"
        case .mapPiece: return "地图碎片"
        }
    }

    var symbol: String {
        switch self {
        case .coconut: return "leaf.circle.fill"
        case .wood: return "square.stack.3d.up.fill"
        case .shell: return "fossil.shell.fill"
        case .fish: return "fish.fill"
        case .shrimp: return "drop.circle.fill"
        case .mapPiece: return "map.fill"
        }
    }
}

struct Reward: Codable, Hashable {
    let itemType: RewardItemType
    let amount: Int
    let message: String
}

struct QuestionSource: Codable, Hashable {
    enum SourceType: String, Codable {
        case curriculumStandard, officialCompetition, textbookInspired, teacherCreated, original, adapted
    }

    let sourceType: SourceType
    let sourceName: String
    let sourceUrl: String?
    let sourceReference: String?
    let adaptationNote: String
    let licenseNote: String
    let author: String
    let reviewedBy: String?
    let createdAt: Date
    let updatedAt: Date
}

struct Question: Identifiable, Codable, Hashable {
    let id: String
    let chapterId: String
    let levelId: String
    let title: String
    let storyContext: String
    let scene: String
    let topic: String
    let subtopic: String
    let gradeBand: String
    let difficulty: String
    let difficultyDescription: String
    let questionText: String
    let answerType: AnswerType
    let options: [String]
    let correctAnswer: String
    let acceptableAnswers: [String]
    let unit: String
    let solutionSteps: [String]
    let equationSolution: [String]
    let hints: [String]
    let skills: [String]
    let coreCompetencies: [String]
    let errorTypes: [String]
    let commonWrongAnswers: [String]
    let wrongAnswerFeedback: [String: String]
    let visualType: VisualType
    let visualData: [String: String]
    let reward: Reward
    let source: QuestionSource
    let reviewStatus: ReviewStatus
    let copyrightStatus: CopyrightStatus
    let notesForParent: String

    var isPublishable: Bool {
        reviewStatus == .approved &&
        [.original, .teacherCreated, .licensed, .publicDomain].contains(copyrightStatus)
    }
}

struct Chapter: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let topic: String
    let colorName: String
}

struct Level: Identifiable, Hashable {
    let id: String
    let chapterId: String
    let order: Int
    let title: String
    let scene: String
    let storyLines: [String]
    let reward: Reward
}

struct AttemptRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let questionId: String
    let answer: String
    let isCorrect: Bool
    let usedHintCount: Int
    let errorType: String?
    let occurredAt: Date
}

struct SavedProgress: Codable {
    var completedLevelIDs: Set<String> = []
    var rewards: [RewardItemType: Int] = [:]
    var attempts: [AttemptRecord] = []
    var masteredWrongQuestionIDs: Set<String> = []
    var soundEnabled = true
    var gentleAnimationsEnabled = true
}

struct ParentReport {
    let completedCount: Int
    let correctCount: Int
    let wrongQuestionCount: Int
    let topics: [String]
    let strongSkills: [String]
    let frequentErrors: [(String, Int)]
    let competenciesToBuild: [String]
    let suggestion: String

    var accuracy: Int {
        completedCount == 0 ? 0 : Int((Double(correctCount) / Double(completedCount) * 100).rounded())
    }
}
