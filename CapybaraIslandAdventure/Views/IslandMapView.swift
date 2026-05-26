import SwiftUI

struct IslandMapView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("海岛探险地图")
                            .font(.largeTitle.weight(.bold))
                        Text("沿着小路完成挑战，收集建造营地的材料。")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    rewardShelf
                }

                ForEach(game.chapters) { chapter in
                    LevelSelectionView(chapter: chapter, levels: game.levels.filter { $0.chapterId == chapter.id })
                }
            }
            .padding(24)
        }
    }

    private var rewardShelf: some View {
        HStack(spacing: 10) {
            ForEach(RewardItemType.allCases, id: \.self) { item in
                VStack {
                    Image(systemName: item.symbol)
                    Text("\(game.progress.rewards[item, default: 0])")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(IslandTheme.deepOcean)
                .frame(width: 46, height: 48)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.68)))
                .accessibilityLabel("\(item.title) \(game.progress.rewards[item, default: 0]) 个")
            }
        }
    }
}

struct LevelSelectionView: View {
    @EnvironmentObject private var game: GameViewModel
    let chapter: Chapter
    let levels: [Level]

    var body: some View {
        IslandCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.title)
                            .font(.title3.weight(.bold))
                        Text(chapter.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(chapter.topic)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(IslandTheme.palm.opacity(0.16)))
                }
                HStack(spacing: 12) {
                    ForEach(levels) { level in
                        Button {
                            game.begin(level)
                        } label: {
                            LevelNodeView(level: level, unlocked: game.isUnlocked(level), completed: game.isCompleted(level))
                        }
                        .buttonStyle(.plain)
                        .disabled(!game.isUnlocked(level))
                        if level.id != levels.last?.id {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(IslandTheme.wood.opacity(0.4))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
