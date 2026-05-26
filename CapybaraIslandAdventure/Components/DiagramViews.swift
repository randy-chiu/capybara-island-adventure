import SwiftUI

struct RouteDiagramView: View {
    let question: Question

    var body: some View {
        VStack(spacing: 10) {
            switch question.visualType {
            case .meet:
                meetDiagram
            case .chase:
                chaseDiagram
            case .boat:
                boatDiagram
            default:
                routeDiagram
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(IslandTheme.ink)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(IslandTheme.ocean.opacity(0.12)))
    }

    private var routeDiagram: some View {
        VStack(spacing: 8) {
            HStack {
                Text(question.visualData["from"] ?? "出发地")
                Spacer()
                Text(question.visualData["to"] ?? "目的地")
            }
            HStack(spacing: 8) {
                Circle().fill(IslandTheme.coral).frame(width: 12)
                Rectangle().fill(IslandTheme.wood.opacity(0.55)).frame(height: 3)
                Image(systemName: "figure.walk")
                    .foregroundStyle(IslandTheme.leaf)
                Rectangle().fill(IslandTheme.wood.opacity(0.55)).frame(height: 3)
                Circle().fill(IslandTheme.palm).frame(width: 12)
            }
            Text([question.visualData["distance"], question.visualData["speed"], question.visualData["time"]]
                .compactMap { $0 }.joined(separator: " · "))
        }
    }

    private var meetDiagram: some View {
        VStack(spacing: 9) {
            HStack {
                Label(question.visualData["left"] ?? "小巴", systemImage: "pawprint.fill")
                Spacer()
                Label(question.visualData["right"] ?? "小海龟", systemImage: "tortoise.fill")
            }
            HStack {
                Image(systemName: "arrow.right").foregroundStyle(IslandTheme.coral)
                Rectangle().fill(IslandTheme.wood.opacity(0.4)).frame(height: 3)
                Image(systemName: "heart.fill").foregroundStyle(IslandTheme.coral)
                Rectangle().fill(IslandTheme.wood.opacity(0.4)).frame(height: 3)
                Image(systemName: "arrow.left").foregroundStyle(IslandTheme.palm)
            }
            Text(question.visualData["distance"] ?? question.visualData["time"] ?? "")
        }
    }

    private var chaseDiagram: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(question.visualData["follower"] ?? "小巴", systemImage: "pawprint.fill")
                Image(systemName: "arrow.right").foregroundStyle(IslandTheme.coral)
                Spacer()
                Text("领先 \(question.visualData["lead"] ?? "")")
                Spacer()
                Label(question.visualData["leader"] ?? "伙伴", systemImage: "arrow.right.circle.fill")
            }
            Capsule().fill(IslandTheme.sand).frame(height: 7)
            Text("追及时关注速度差，也别忘记前方伙伴仍在移动。")
                .foregroundStyle(.secondary)
        }
    }

    private var boatDiagram: some View {
        VStack(spacing: 8) {
            HStack {
                Text(question.visualData["from"] ?? "营地")
                Spacer()
                Image(systemName: "sailboat.fill").foregroundStyle(IslandTheme.deepOcean)
                Spacer()
                Text(question.visualData["to"] ?? "虾岛")
            }
            HStack {
                Image(systemName: "water.waves")
                Text("水流 \(question.visualData["current"] ?? "顺水 / 逆水")")
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(IslandTheme.deepOcean)
            Text(question.visualData["distance"] ?? "\(question.visualData["downstream"] ?? "") / \(question.visualData["upstream"] ?? "")")
        }
    }
}

struct GeometryDiagramView: View {
    let question: Question

    var body: some View {
        VStack(spacing: 8) {
            if question.visualType == .angle {
                angleDiagram
            } else if question.visualType == .compositeShape {
                compositeDiagram
            } else {
                rectangleDiagram
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18).fill(IslandTheme.sand.opacity(0.28)))
    }

    private var rectangleDiagram: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(IslandTheme.palm.opacity(0.24))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(IslandTheme.leaf, lineWidth: 3))
                    .frame(width: 170, height: 88)
                Text(question.visualData["area"] ?? "")
                    .font(.caption.weight(.bold))
            }
            Text("长 \(question.visualData["length"] ?? "?")   宽 \(question.visualData["width"] ?? question.visualData["oldWidth"] ?? "?")")
                .font(.caption.weight(.medium))
                .foregroundStyle(IslandTheme.ink)
        }
    }

    private var compositeDiagram: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(IslandTheme.palm.opacity(0.35))
                    .overlay(Rectangle().stroke(IslandTheme.leaf, lineWidth: 2))
                    .frame(width: 170, height: 106)
                if question.visualData["cutout"] != nil {
                    Rectangle()
                        .fill(IslandTheme.shell)
                        .overlay(Rectangle().stroke(IslandTheme.coral, style: StrokeStyle(lineWidth: 2, dash: [4])))
                        .frame(width: 58, height: 38)
                } else {
                    Rectangle()
                        .fill(IslandTheme.sand.opacity(0.8))
                        .frame(width: 54, height: 44)
                        .offset(x: 45, y: 82)
                }
            }
            Text("大图形 \(question.visualData["outer"] ?? "")   \(compositeDetail)")
                .font(.caption)
        }
    }

    private var compositeDetail: String {
        if let cutout = question.visualData["cutout"] { return "缺口 \(cutout)" }
        if let addon = question.visualData["addon"] { return "拼块 \(addon)" }
        return "中央 \(question.visualData["inner"] ?? "")"
    }

    private var angleDiagram: some View {
        VStack(spacing: 6) {
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 18, y: 72))
                    path.addLine(to: CGPoint(x: 182, y: 72))
                    path.move(to: CGPoint(x: 100, y: 72))
                    path.addLine(to: CGPoint(x: 138, y: 20))
                }
                .stroke(IslandTheme.wood, lineWidth: 3)
                Text(question.visualData["angle"] ?? question.visualData["angleA"] ?? "")
                    .font(.caption.weight(.bold))
                    .offset(x: 22, y: 12)
            }
            .frame(width: 200, height: 80)
            Text(question.visualData["relation"] ?? "角度线索")
                .font(.caption)
                .foregroundStyle(IslandTheme.deepOcean)
        }
    }
}

struct QuestionDiagramView: View {
    let question: Question

    var body: some View {
        if [.route, .meet, .chase, .boat].contains(question.visualType) {
            RouteDiagramView(question: question)
        } else {
            GeometryDiagramView(question: question)
        }
    }
}
