import SwiftUI

enum IslandTheme {
    static let ocean = Color(red: 0.39, green: 0.77, blue: 0.82)
    static let deepOcean = Color(red: 0.12, green: 0.47, blue: 0.58)
    static let sand = Color(red: 0.98, green: 0.89, blue: 0.67)
    static let palm = Color(red: 0.39, green: 0.67, blue: 0.43)
    static let leaf = Color(red: 0.25, green: 0.55, blue: 0.38)
    static let wood = Color(red: 0.65, green: 0.44, blue: 0.28)
    static let shell = Color(red: 1.0, green: 0.98, blue: 0.92)
    static let ink = Color(red: 0.20, green: 0.28, blue: 0.27)
    static let coral = Color(red: 0.96, green: 0.58, blue: 0.46)
}

struct IslandBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.85, green: 0.96, blue: 0.95), IslandTheme.ocean.opacity(0.58)],
                               startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(IslandTheme.sand)
                    .frame(width: geo.size.width * 0.68, height: geo.size.height * 0.73)
                    .offset(x: geo.size.width * 0.06, y: geo.size.height * 0.09)
                Ellipse()
                    .fill(IslandTheme.palm.opacity(0.28))
                    .frame(width: geo.size.width * 0.27, height: geo.size.height * 0.22)
                    .offset(x: geo.size.width * 0.17, y: -geo.size.height * 0.07)
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(IslandTheme.leaf.opacity(0.25))
                        .rotationEffect(.degrees(Double(index * 36)))
                        .offset(x: -geo.size.width * 0.26 + Double(index * 30),
                                y: geo.size.height * 0.19 - Double(index * 16))
                }
            }
            .ignoresSafeArea()
        }
    }
}

struct IslandCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(IslandTheme.shell.opacity(0.96))
                    .shadow(color: IslandTheme.deepOcean.opacity(0.10), radius: 14, y: 6)
            )
    }
}

struct PrimaryIslandButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.title3.weight(.bold))
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(
                    Capsule()
                        .fill(IslandTheme.leaf)
                        .shadow(color: IslandTheme.leaf.opacity(0.28), radius: 10, y: 5)
                )
        }
        .buttonStyle(.plain)
    }
}
