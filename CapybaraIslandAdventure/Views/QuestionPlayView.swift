import SwiftUI

struct QuestionPlayView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var questionIndex = 0
    @State private var response = ""
    @State private var shownHints = 0
    @State private var result: Bool?
    @State private var message = ""
    @State private var showSolution = false

    private var question: Question? {
        game.activeQuestions.indices.contains(questionIndex) ? game.activeQuestions[questionIndex] : nil
    }

    var body: some View {
        if let level = game.activeLevel, let question {
            VStack(spacing: 14) {
                topBar(level: level)
                HStack(alignment: .top, spacing: 18) {
                    coachPanel(question: question)
                        .frame(width: 270)
                    ScrollView {
                        VStack(spacing: 14) {
                            IslandCard {
                                QuestionCardView(question: question)
                            }
                            QuestionDiagramView(question: question)
                            answerPanel(question: question)
                        }
                        .padding(.bottom, 18)
                    }
                }
            }
            .padding(20)
            .sheet(isPresented: $showSolution) {
                ExplanationView(question: question) {
                    showSolution = false
                }
            }
        }
    }

    private func topBar(level: Level) -> some View {
        HStack {
            Button {
                game.closeAdventure()
            } label: {
                Label("退出关卡", systemImage: "chevron.left")
            }
            Spacer()
            VStack {
                Text(game.isReviewChallenge ? "错题重新挑战" : "\(level.id) \(level.title)")
                    .font(.headline.weight(.bold))
                Text("第 \(questionIndex + 1) 题 / 共 \(game.activeQuestions.count) 题")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("提示 \(shownHints)/3")
                .font(.caption.weight(.semibold))
                .foregroundStyle(IslandTheme.deepOcean)
        }
        .padding(.horizontal, 6)
    }

    private func coachPanel(question: Question) -> some View {
        VStack(spacing: 12) {
            CapybaraAvatarView(size: 108, mood: result == false ? .thinking : .happy)
            IslandCard {
                Text(coachMessage)
                    .font(.subheadline.weight(.medium))
                    .lineSpacing(4)
            }
            VStack(spacing: 8) {
                ForEach(Array(question.hints.prefix(shownHints).enumerated()), id: \.offset) { offset, hint in
                    HintBubbleView(text: hint, index: offset + 1)
                }
            }
        }
    }

    private var coachMessage: String {
        if result == true { return "答对啦！这个数字就是我们需要的线索。" }
        if result == false { return message }
        return "先画个图，小巴就不迷路啦。认真读题，再开始计算。"
    }

    private func answerPanel(question: Question) -> some View {
        IslandCard {
            VStack(spacing: 12) {
                if question.answerType == .multipleChoice || question.answerType == .stepChoice {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(question.options, id: \.self) { option in
                            Button {
                                response = option
                            } label: {
                                Text(option + (question.unit.isEmpty ? "" : " \(question.unit)"))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .foregroundStyle(IslandTheme.ink)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(response == option ? IslandTheme.sand : .white))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(response == option ? IslandTheme.coral : IslandTheme.ocean.opacity(0.22), lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    HStack {
                        TextField(question.answerType == .equationInput ? "输入答案，如 65/14" : "输入数字", text: $response)
                            .font(.title3)
                            .textFieldStyle(.plain)
                            .keyboardType(.numbersAndPunctuation)
                            .padding(13)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                        Text(question.unit)
                            .font(.headline)
                            .frame(width: 70, alignment: .leading)
                    }
                }

                if result == true {
                    Label("回答正确，线索收好啦！", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(IslandTheme.leaf)
                } else if result == false {
                    Label("咦，我们发现了一个数学陷阱！", systemImage: "sparkle.magnifyingglass")
                        .foregroundStyle(IslandTheme.coral)
                }

                HStack(spacing: 10) {
                    if result != true {
                        Button("看一点提示") {
                            withAnimation { shownHints = min(shownHints + 1, question.hints.count) }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(shownHints >= question.hints.count)
                        Button(result == false ? "再试一次" : "检查答案") {
                            checkAnswer(question)
                        }
                        .buttonStyle(FilledButtonStyle())
                        .disabled(response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Button(questionIndex == game.activeQuestions.count - 1 ? "完成挑战" : "下一题") {
                            advance()
                        }
                        .buttonStyle(FilledButtonStyle())
                    }
                    Button("看完整讲解") {
                        showSolution = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    private func checkAnswer(_ question: Question) {
        let correct = game.submit(response, for: question, usedHintCount: shownHints)
        result = correct
        message = correct ? "" : game.feedback(for: response, question: question)
    }

    private func advance() {
        if questionIndex < game.activeQuestions.count - 1 {
            questionIndex += 1
            response = ""
            shownHints = 0
            result = nil
            message = ""
            showSolution = false
        } else {
            game.completeCurrentLevel()
        }
    }
}

struct ExplanationView: View {
    let question: Question
    let dismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(question.questionText)
                        .font(.headline)
                    QuestionDiagramView(question: question)
                    solutionBlock(title: "一步一步讲解", lines: question.solutionSteps, symbol: "list.number")
                    if !question.equationSolution.isEmpty {
                        solutionBlock(title: "用 x 来建模", lines: question.equationSolution, symbol: "function")
                    }
                    solutionBlock(title: "可以练习的能力", lines: question.skills + question.coreCompetencies, symbol: "star.fill")
                    Text("小巴说：答错也没关系，说明我们发现了一个数学陷阱。")
                        .font(.subheadline.weight(.medium))
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(IslandTheme.sand.opacity(0.35)))
                }
                .padding(22)
            }
            .navigationTitle("讲解：\(question.title)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("继续思考", action: dismiss)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func solutionBlock(title: String, lines: [String], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(IslandTheme.deepOcean)
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text("\(index + 1). \(line)")
                    .font(.body)
            }
        }
    }
}

private struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(IslandTheme.leaf.opacity(configuration.isPressed ? 0.75 : 1)))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(IslandTheme.deepOcean)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().fill(IslandTheme.ocean.opacity(configuration.isPressed ? 0.20 : 0.12)))
    }
}
