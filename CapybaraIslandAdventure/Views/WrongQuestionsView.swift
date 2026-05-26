import SwiftUI

struct WrongQuestionsView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var expandedID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("错题复盘小屋")
                    .font(.largeTitle.weight(.bold))
                Text("答错不是失败，是找到了下一次探险的路线。完成重新挑战后，这道题会离开待复习列表。")
                    .foregroundStyle(.secondary)

                let errors = game.bank.errorCounts(from: game.progress.attempts.filter { !$0.isCorrect })
                if !errors.isEmpty {
                    IslandCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("发现的数学陷阱")
                                .font(.headline.weight(.bold))
                            HStack(spacing: 10) {
                                ForEach(errors.prefix(4), id: \.0) { item in
                                    Text("\(item.0) × \(item.1)")
                                        .font(.caption.weight(.semibold))
                                        .padding(9)
                                        .background(Capsule().fill(IslandTheme.sand.opacity(0.5)))
                                }
                            }
                        }
                    }
                }

                if game.wrongQuestions.isEmpty {
                    IslandCard {
                        HStack(spacing: 18) {
                            CapybaraAvatarView(size: 80, mood: .celebrating)
                            Text("目前没有待复习的错题。继续探险，保持认真检查的好习惯！")
                                .font(.headline)
                        }
                    }
                } else {
                    ForEach(game.wrongQuestions) { question in
                        WrongQuestionRow(question: question, expanded: expandedID == question.id) {
                            withAnimation { expandedID = expandedID == question.id ? nil : question.id }
                        } challenge: {
                            game.review(question)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct WrongQuestionRow: View {
    let question: Question
    let expanded: Bool
    let toggle: () -> Void
    let challenge: () -> Void

    var body: some View {
        IslandCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(question.title)
                            .font(.headline.weight(.bold))
                        Text("\(question.topic) · \(question.subtopic) · 难度 \(question.difficulty)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("重新挑战", action: challenge)
                        .buttonStyle(.borderedProminent)
                        .tint(IslandTheme.leaf)
                    Button(expanded ? "收起讲解" : "查看讲解", action: toggle)
                        .buttonStyle(.bordered)
                        .tint(IslandTheme.deepOcean)
                }
                Text(question.questionText)
                    .font(.subheadline)
                if expanded {
                    QuestionDiagramView(question: question)
                    ForEach(question.hints, id: \.self) { hint in
                        HintBubbleView(text: hint, index: (question.hints.firstIndex(of: hint) ?? 0) + 1)
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        Text("完整讲解").font(.headline)
                        ForEach(question.solutionSteps, id: \.self) { step in
                            Text("• \(step)").font(.subheadline)
                        }
                    }
                }
            }
        }
    }
}
