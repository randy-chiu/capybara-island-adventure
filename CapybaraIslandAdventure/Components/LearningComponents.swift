import SwiftUI

struct LevelNodeView: View {
    let level: Level
    let unlocked: Bool
    let completed: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(completed ? IslandTheme.palm : (unlocked ? IslandTheme.sand : .gray.opacity(0.3)))
                    .frame(width: 58, height: 58)
                Image(systemName: completed ? "checkmark.star.fill" : (unlocked ? "pawprint.fill" : "lock.fill"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(completed ? .white : IslandTheme.wood)
            }
            Text(level.id)
                .font(.caption.weight(.bold))
            Text(level.title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .frame(width: 84)
        }
        .foregroundStyle(IslandTheme.ink)
        .opacity(unlocked ? 1 : 0.64)
    }
}

struct HintBubbleView: View {
    let text: String
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(IslandTheme.coral)
            Text("提示 \(index)：\(text)")
                .font(.body.weight(.medium))
                .foregroundStyle(IslandTheme.ink)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(IslandTheme.sand.opacity(0.38)))
    }
}

struct QuestionCardView: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(question.title)
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(question.difficulty) · \(question.difficultyDescription)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(IslandTheme.deepOcean)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(IslandTheme.ocean.opacity(0.18)))
            }
            Text(question.storyContext)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(question.questionText)
                .font(.title3.weight(.medium))
                .foregroundStyle(IslandTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Label(question.subtopic, systemImage: "tag.fill")
                .font(.caption)
                .foregroundStyle(IslandTheme.leaf)
        }
    }
}

struct RewardView: View {
    let reward: Reward
    let animate: Bool
    @State private var bob = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: reward.itemType.symbol)
                .font(.system(size: 54))
                .foregroundStyle(IslandTheme.coral, IslandTheme.sand)
                .scaleEffect(bob ? 1.08 : 0.94)
                .offset(y: bob ? -4 : 2)
            Text("+\(reward.amount) \(reward.itemType.title)")
                .font(.title3.weight(.bold))
        }
        .onAppear {
            guard animate else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }
}

struct ProgressSummaryView: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(IslandTheme.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.75)))
    }
}
