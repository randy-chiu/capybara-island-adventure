import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        HStack(spacing: 48) {
            VStack(alignment: .leading, spacing: 16) {
                Text("卡皮巴拉海岛探险")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(IslandTheme.deepOcean)
                Text("四年级数学 · 漫画剧情探险")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(IslandTheme.leaf)
                IslandCard {
                    HStack(alignment: .top, spacing: 15) {
                        CapybaraAvatarView(size: 76)
                        Text("今天我们要去海岛探险啦！先找到椰子林，再建一个安全营地。")
                            .font(.title3.weight(.medium))
                            .lineSpacing(5)
                            .frame(maxWidth: 400, alignment: .leading)
                    }
                }
                PrimaryIslandButton(title: "开始探险", symbol: "sailboat.fill") {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        game.enterIsland()
                    }
                }
                Text("本地学习 · 无登录 · 无广告 · 不收集个人身份信息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 600, alignment: .leading)

            VStack(spacing: 18) {
                CapybaraAvatarView(size: 230, mood: .celebrating)
                Label("椰子林", systemImage: "leaf.fill")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(IslandTheme.sand))
            }
        }
        .padding(42)
    }
}
