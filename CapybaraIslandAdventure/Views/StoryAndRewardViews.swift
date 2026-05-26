import SwiftUI

struct StoryDialogueView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var lineIndex = 0

    var body: some View {
        if let level = game.activeLevel {
            VStack(spacing: 22) {
                HStack {
                    Button("返回地图") { game.closeAdventure() }
                    Spacer()
                    Text("\(level.id)  \(level.title)")
                        .font(.title3.weight(.bold))
                    Spacer()
                    Color.clear.frame(width: 70)
                }
                .foregroundStyle(IslandTheme.deepOcean)

                Spacer()
                HStack(spacing: 25) {
                    CapybaraAvatarView(size: 156, mood: .happy)
                    IslandCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("小巴")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(IslandTheme.leaf)
                            Text(level.storyLines[lineIndex])
                                .font(.title2.weight(.medium))
                                .lineSpacing(7)
                                .frame(width: 520, minHeight: 76, alignment: .leading)
                            Text("\(lineIndex + 1) / \(level.storyLines.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                PrimaryIslandButton(title: lineIndex == level.storyLines.count - 1 ? "开始挑战" : "继续听故事",
                                    symbol: lineIndex == level.storyLines.count - 1 ? "pencil.and.list.clipboard" : "arrow.right") {
                    if lineIndex < level.storyLines.count - 1 {
                        withAnimation { lineIndex += 1 }
                    } else {
                        game.beginQuestions()
                    }
                }
            }
            .padding(28)
        }
    }
}

struct LevelRewardView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        if let level = game.activeLevel {
            VStack(spacing: 22) {
                CapybaraAvatarView(size: 142, mood: .celebrating)
                Text("闯关成功！")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(IslandTheme.deepOcean)
                IslandCard {
                    VStack(spacing: 16) {
                        RewardView(reward: level.reward, animate: game.progress.gentleAnimationsEnabled)
                        Text(level.reward.message)
                            .font(.headline)
                        if let next = game.levels.first(where: { $0.order == level.order + 1 }) {
                            Label("新关卡已解锁：\(next.id) \(next.title)", systemImage: "lock.open.fill")
                                .foregroundStyle(IslandTheme.leaf)
                        } else {
                            Text("小巴完成了第一段海岛探险！")
                                .foregroundStyle(IslandTheme.leaf)
                        }
                    }
                    .frame(width: 430)
                }
                PrimaryIslandButton(title: "回到海岛地图", symbol: "map.fill") {
                    game.finishReward()
                }
            }
        }
    }
}
