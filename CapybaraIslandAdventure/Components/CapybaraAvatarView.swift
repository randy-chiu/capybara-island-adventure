import SwiftUI

struct CapybaraAvatarView: View {
    var size: CGFloat = 112
    var mood: Mood = .happy

    enum Mood {
        case happy, thinking, celebrating
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(IslandTheme.sand.opacity(0.7))
            Ellipse()
                .fill(Color(red: 0.66, green: 0.48, blue: 0.33))
                .frame(width: size * 0.67, height: size * 0.62)
                .offset(y: size * 0.08)
            Circle()
                .fill(Color(red: 0.61, green: 0.43, blue: 0.30))
                .frame(width: size * 0.18)
                .offset(x: -size * 0.21, y: -size * 0.21)
            Circle()
                .fill(Color(red: 0.61, green: 0.43, blue: 0.30))
                .frame(width: size * 0.18)
                .offset(x: size * 0.21, y: -size * 0.21)
            Ellipse()
                .fill(Color(red: 0.77, green: 0.59, blue: 0.41))
                .frame(width: size * 0.44, height: size * 0.27)
                .offset(y: size * 0.14)
            eye.offset(x: -size * 0.15, y: -size * 0.04)
            eye.offset(x: size * 0.15, y: -size * 0.04)
            nose
            if mood == .celebrating {
                Image(systemName: "sparkles")
                    .foregroundStyle(IslandTheme.coral)
                    .offset(x: size * 0.35, y: -size * 0.32)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("小巴，卡皮巴拉探险伙伴")
    }

    private var eye: some View {
        Circle()
            .fill(IslandTheme.ink)
            .frame(width: size * 0.065)
    }

    private var nose: some View {
        VStack(spacing: size * 0.015) {
            Capsule()
                .fill(IslandTheme.ink)
                .frame(width: size * 0.10, height: size * 0.055)
            if mood == .thinking {
                Circle().stroke(IslandTheme.ink, lineWidth: 2).frame(width: size * 0.07, height: size * 0.07)
            } else {
                Capsule().fill(IslandTheme.ink).frame(width: size * 0.14, height: 2)
            }
        }
        .offset(y: size * 0.12)
    }
}
