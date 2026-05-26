import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var showResetAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("设置与隐私")
                    .font(.largeTitle.weight(.bold))
                IslandCard {
                    VStack(spacing: 4) {
                        Toggle("游戏音效（预留设置）", isOn: Binding(
                            get: { game.progress.soundEnabled },
                            set: game.updateSound
                        ))
                        .padding(.vertical, 10)
                        Divider()
                        Toggle("轻柔奖励动画", isOn: Binding(
                            get: { game.progress.gentleAnimationsEnabled },
                            set: game.updateAnimations
                        ))
                        .padding(.vertical, 10)
                    }
                    .tint(IslandTheme.leaf)
                }

                IslandCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("儿童隐私说明")
                            .font(.headline.weight(.bold))
                        Text("本版本无需账号和登录；学习进度、作答记录与错题仅保存在本设备；不含广告、内购、外链或第三方分析 SDK；不收集儿童个人身份信息。")
                            .lineSpacing(5)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("清除本机学习进度", systemImage: "trash")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
        }
        .alert("清除所有进度？", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) {
                game.resetProgress()
            }
        } message: {
            Text("已解锁关卡、奖励、错题和作答报告都会从本机删除。")
        }
    }
}
