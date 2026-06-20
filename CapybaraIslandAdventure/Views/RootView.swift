import SwiftUI

struct RootView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ZStack {
            IslandBackgroundView()
            if !game.hasStarted {
                HomeView()
                    .transition(.opacity)
            } else if game.isIn3DAdventure {
                Island3DGameView()
            } else if let flow = game.flow {
                switch flow {
                case .story:
                    StoryDialogueView()
                case .questions:
                    QuestionPlayView()
                case .reward:
                    LevelRewardView()
                }
            } else {
                MainShellView()
            }
        }
        .foregroundStyle(IslandTheme.ink)
    }
}

struct MainShellView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CapybaraAvatarView(size: 54)
                VStack(alignment: .leading) {
                    Text("小巴的海岛")
                        .font(.headline.weight(.bold))
                    Text("别急别急，我们一步一步来。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    game.openAdventureIsland()
                } label: {
                    Label("返回小岛", systemImage: "gamecontroller.fill")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(Capsule().fill(IslandTheme.leaf))
                }
                .buttonStyle(.plain)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(MainDestination.allCases, id: \.self) { item in
                            Button {
                                game.destination = item
                            } label: {
                                Label(item.rawValue, systemImage: item.symbol)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(game.destination == item ? .white : IslandTheme.deepOcean)
                                    .background(Capsule().fill(game.destination == item ? IslandTheme.deepOcean : .white.opacity(0.55)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: 500)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(.white.opacity(0.30))

            switch game.destination {
            case .map:
                IslandMapView()
            case .mistakes:
                WrongQuestionsView()
            case .report:
                ParentReportView()
            case .settings:
                SettingsView()
            }
        }
    }
}
