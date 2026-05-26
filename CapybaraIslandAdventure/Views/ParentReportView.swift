import SwiftUI

struct ParentReportView: View {
    @EnvironmentObject private var game: GameViewModel

    private var report: ParentReport { game.report() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("家长报告")
                            .font(.largeTitle.weight(.bold))
                        Text("今日学习摘要 · 数据仅保存在本设备")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(Date.now.formatted(date: .long, time: .omitted))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(IslandTheme.deepOcean)
                }

                HStack(spacing: 12) {
                    ProgressSummaryView(title: "今日完成题数", value: "\(report.completedCount)", symbol: "pencil.and.list.clipboard", color: IslandTheme.leaf)
                    ProgressSummaryView(title: "正确率", value: "\(report.accuracy)%", symbol: "checkmark.seal.fill", color: IslandTheme.deepOcean)
                    ProgressSummaryView(title: "待复习错题", value: "\(report.wrongQuestionCount)", symbol: "book.closed.fill", color: IslandTheme.coral)
                }

                IslandCard {
                    VStack(alignment: .leading, spacing: 14) {
                        reportLine("今日学习主题", values: report.topics, fallback: "尚未开始今日探险")
                        reportLine("掌握较好的技能", values: report.strongSkills, fallback: "继续作答后生成")
                        reportLine("需要加强的素养", values: report.competenciesToBuild, fallback: "暂无明显薄弱项")
                        VStack(alignment: .leading, spacing: 7) {
                            Text("高频错误类型")
                                .font(.headline.weight(.bold))
                            if report.frequentErrors.isEmpty {
                                Text("暂无错题记录").foregroundStyle(.secondary)
                            } else {
                                Text(report.frequentErrors.prefix(4).map { "\($0.0)（\($0.1) 次）" }.joined(separator: "；"))
                            }
                        }
                    }
                }

                IslandCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Label("明日建议", systemImage: "sun.max.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(IslandTheme.leaf)
                        Text(report.suggestion)
                            .font(.body)
                            .lineSpacing(5)
                        if report.completedCount > 0 {
                            Text(summarySentence)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var summarySentence: String {
        let strength = report.strongSkills.first ?? "基础模型"
        let issue = report.frequentErrors.first?.0 ?? "暂无高频错误"
        return "今天孩子完成了 \(report.completedCount) 道题，正确 \(report.correctCount) 道。“\(strength)”表现较好；关注“\(issue)”。"
    }

    private func reportLine(_ title: String, values: [String], fallback: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline.weight(.bold))
            Text(values.isEmpty ? fallback : values.joined(separator: "、"))
                .foregroundStyle(values.isEmpty ? .secondary : IslandTheme.ink)
        }
    }
}
