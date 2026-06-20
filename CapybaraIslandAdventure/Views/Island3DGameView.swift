import SwiftUI
import RealityKit
import UIKit
import Combine

@MainActor
final class Island3DSession: ObservableObject {
    enum FishingState {
        case idle, waiting, bite, caught
    }

    @Published var movement = SIMD2<Float>.zero
    @Published var baitCount = 0
    @Published var nearPier = false
    @Published var nearBridge = false
    @Published var nearChest = false
    @Published var fishingState: FishingState = .idle
    @Published var caughtFish = false
    @Published var showBridgePuzzle = false
    @Published var bridgeOpen = false
    @Published var chestOpened = false
    @Published var showCompletion = false
    @Published var shellCount = 0
    @Published var toast: String?

    var questProgress: String {
        if chestOpened { return "任务完成 · 星光宝藏已找到" }
        if bridgeOpen { return "任务 3/3 · 探索新区域" }
        if caughtFish { return "任务 2/3 · 前往闪光断桥" }
        return "任务 1/3 · 收集鱼饵并钓鱼"
    }

    var objective: String {
        if chestOpened { return "今天的探险完成了！下一座小岛正在准备中。" }
        if bridgeOpen { return nearChest ? "宝箱就在眼前，打开看看吧！" : "穿过新修好的桥，寻找金色光柱下的宝箱。" }
        if caughtFish { return nearBridge ? "桥被水冲坏了，看看需要多少块木板。" : "带着银鳞鱼去北边的断桥。" }
        if baitCount == 0 { return "先自由逛逛，在草地上找到闪光的鱼饵。" }
        if nearPier { return "鱼影出现了！现在可以抛竿。" }
        return "鱼饵准备好了，沿着木栈道去海边。"
    }

    var actionTitle: String? {
        if nearChest && bridgeOpen && !chestOpened { return "打开宝箱" }
        if nearBridge && caughtFish && !bridgeOpen { return "检查断桥" }
        guard nearPier, baitCount > 0, !caughtFish else { return nil }
        switch fishingState {
        case .idle: return "抛竿钓鱼"
        case .waiting: return "安静等待…"
        case .bite: return "鱼上钩了！收线"
        case .caught: return nil
        }
    }

    func collectBait() {
        baitCount += 1
        showToast(baitCount == 1 ? "找到鱼饵！海边似乎有鱼影。" : "又找到一份鱼饵！")
    }

    func performAction() {
        if nearChest && bridgeOpen && !chestOpened {
            chestOpened = true
            shellCount += 1
            showToast("找到星光贝壳！今天的海岛任务完成啦！")
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                self.showCompletion = true
            }
            return
        }
        if nearBridge && caughtFish && !bridgeOpen {
            showBridgePuzzle = true
            return
        }
        guard nearPier, baitCount > 0, !caughtFish else { return }
        switch fishingState {
        case .idle:
            fishingState = .waiting
            showToast("浮标落水了……注意水面的动静。")
            Task {
                try? await Task.sleep(for: .seconds(1.8))
                guard self.fishingState == .waiting else { return }
                self.fishingState = .bite
                self.showToast("扑通！快点收线！")
            }
        case .waiting:
            break
        case .bite:
            fishingState = .caught
            caughtFish = true
            baitCount = max(0, baitCount - 1)
            showToast("新任务：带着银鳞鱼前往红色光柱标记的断桥！")
        case .caught:
            break
        }
    }

    func solveBridge(answer: Int) {
        guard answer == 6 else {
            showToast("木板数量还不对。可以在桥边数一数每段的长度。")
            return
        }
        showBridgePuzzle = false
        bridgeOpen = true
        showToast("正好 6 块！断桥修好，椰子林开放啦！")
    }

    private func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(2.6))
            if self.toast == message { self.toast = nil }
        }
    }
}

struct Island3DGameView: View {
    @EnvironmentObject private var game: GameViewModel
    @StateObject private var session = Island3DSession()

    var body: some View {
        ZStack {
            RealityIslandView(session: session)
                .ignoresSafeArea()

            KeyboardMovementCapture(movement: $session.movement)
                .frame(width: 1, height: 1)

            VStack(spacing: 0) {
                topHUD
                Spacer()
                if let toast = session.toast {
                    Text(toast)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(IslandTheme.ink)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.8), lineWidth: 1))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                bottomControls
            }
            .padding(20)
        }
        .foregroundStyle(IslandTheme.ink)
        .animation(.easeInOut(duration: 0.25), value: session.toast)
        .sheet(isPresented: $session.showBridgePuzzle) {
            BridgeMathPuzzle(session: session)
        }
        .sheet(isPresented: $session.showCompletion) {
            AdventureCompletionView(session: session)
        }
    }

    private var topHUD: some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                game.openLearningCenter()
            } label: {
                Label("学习中心", systemImage: "map.fill")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("小巴的第一个海岛日")
                    .font(.headline.weight(.heavy))
                Text(session.questProgress)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(IslandTheme.deepOcean)
                Text(session.objective)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))

            Spacer()

            HStack(spacing: 12) {
                Label("\(session.baitCount)", systemImage: "sparkles")
                Label(session.caughtFish ? "1" : "0", systemImage: "fish.fill")
                Label("\(session.shellCount)", systemImage: "seal.fill")
            }
            .font(.headline.weight(.bold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var bottomControls: some View {
        HStack(alignment: .bottom) {
            VStack(spacing: 7) {
                VirtualJoystick(movement: $session.movement)
                Text("拖动摇杆移动 · Mac 可用方向键/WASD")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            Spacer()
            if let actionTitle = session.actionTitle {
                Button {
                    session.performAction()
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: session.nearBridge ? "hammer.fill" : "fish.fill")
                            .font(.title2)
                        Text(actionTitle)
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 132, height: 82)
                    .background(Capsule().fill(session.fishingState == .bite ? IslandTheme.coral : IslandTheme.leaf))
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(session.fishingState == .waiting)
            }
        }
    }
}

private struct AdventureCompletionView: View {
    @ObservedObject var session: Island3DSession

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(IslandTheme.sand.opacity(0.65))
                    .frame(width: 150, height: 150)
                Image(systemName: "seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(IslandTheme.coral)
            }
            Text("海岛任务完成！")
                .font(.largeTitle.weight(.heavy))
            Text("小巴收集了鱼饵、钓到银鳞鱼，还用数学修好了断桥。")
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
            Label("获得：星光贝壳 × 1", systemImage: "sparkles")
                .font(.title2.weight(.bold))
                .foregroundStyle(IslandTheme.deepOcean)
            Button("继续在岛上逛逛") {
                session.showCompletion = false
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Capsule().fill(IslandTheme.leaf))
            .buttonStyle(.plain)
        }
        .padding(36)
        .presentationDetents([.medium])
    }
}

private struct KeyboardMovementCapture: UIViewRepresentable {
    @Binding var movement: SIMD2<Float>

    func makeUIView(context: Context) -> MovementKeyView {
        let view = MovementKeyView()
        view.onMovementChanged = { movement = $0 }
        return view
    }

    func updateUIView(_ uiView: MovementKeyView, context: Context) {
        uiView.onMovementChanged = { movement = $0 }
        if uiView.window != nil, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }

    final class MovementKeyView: UIView {
        var onMovementChanged: ((SIMD2<Float>) -> Void)?
        private var pressedKeys = Set<String>()

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { becomeFirstResponder() }
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            var handled = false
            for press in presses {
                guard let key = press.key, let token = token(for: key) else { continue }
                pressedKeys.insert(token)
                handled = true
            }
            if handled { publishMovement() } else { super.pressesBegan(presses, with: event) }
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            var handled = false
            for press in presses {
                guard let key = press.key, let token = token(for: key) else { continue }
                pressedKeys.remove(token)
                handled = true
            }
            if handled { publishMovement() } else { super.pressesEnded(presses, with: event) }
        }

        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            pressedKeys.removeAll()
            publishMovement()
            super.pressesCancelled(presses, with: event)
        }

        private func token(for key: UIKey) -> String? {
            switch key.keyCode {
            case .keyboardUpArrow, .keyboardW: return "up"
            case .keyboardDownArrow, .keyboardS: return "down"
            case .keyboardLeftArrow, .keyboardA: return "left"
            case .keyboardRightArrow, .keyboardD: return "right"
            default: return nil
            }
        }

        private func publishMovement() {
            let x = (pressedKeys.contains("right") ? 1 : 0) - (pressedKeys.contains("left") ? 1 : 0)
            let y = (pressedKeys.contains("down") ? 1 : 0) - (pressedKeys.contains("up") ? 1 : 0)
            onMovementChanged?(SIMD2(Float(x), Float(y)))
        }
    }
}

private struct VirtualJoystick: View {
    @Binding var movement: SIMD2<Float>
    @State private var knobOffset: CGSize = .zero
    private let radius: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 118, height: 118)
                .overlay(Circle().stroke(.white.opacity(0.75), lineWidth: 2))
            Circle()
                .fill(IslandTheme.deepOcean.opacity(0.86))
                .frame(width: 54, height: 54)
                .overlay(Image(systemName: "figure.walk").foregroundStyle(.white).font(.title2))
                .offset(knobOffset)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let vector = CGVector(dx: value.translation.width, dy: value.translation.height)
                    let length = max(1, sqrt(vector.dx * vector.dx + vector.dy * vector.dy))
                    let scale = min(1, radius / length)
                    knobOffset = CGSize(width: vector.dx * scale, height: vector.dy * scale)
                    movement = SIMD2(Float(knobOffset.width / radius), Float(knobOffset.height / radius))
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.22)) { knobOffset = .zero }
                    movement = .zero
                }
        )
        .accessibilityLabel("移动小巴")
    }
}

private struct BridgeMathPuzzle: View {
    @ObservedObject var session: Island3DSession

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                CapybaraAvatarView(size: 112, mood: .thinking)
                Text("断桥只差最后一段")
                    .font(.largeTitle.weight(.heavy))
                Text("断桥缺口长 12 米，每块木板能铺 2 米。小巴需要准备几块木板，才能刚好铺满？")
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)

                HStack(spacing: 14) {
                    ForEach([4, 6, 8], id: \.self) { answer in
                        Button("\(answer) 块") {
                            session.solveBridge(answer: answer)
                        }
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 58)
                        .background(Capsule().fill(IslandTheme.deepOcean))
                        .buttonStyle(.plain)
                    }
                }
                Text("这不是考试，是我们真的需要把桥修好。可以想一想：12 里面有几个 2？")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("再观察一下") { session.showBridgePuzzle = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct RealityIslandView: UIViewRepresentable {
    @ObservedObject var session: Island3DSession

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        context.coordinator.buildScene(in: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.session = session
    }

    @MainActor
    final class Coordinator {
        var session: Island3DSession
        private weak var view: ARView?
        private let world = AnchorEntity(world: .zero)
        private let character = Entity()
        private let camera = PerspectiveCamera()
        private var baitEntities: [ModelEntity] = []
        private var bridgeBarrier: ModelEntity?
        private var bridgeBeacon: ModelEntity?
        private var chestBeacon: ModelEntity?
        private var chestLid: ModelEntity?
        private var chestSparkles: [ModelEntity] = []
        private var updateSubscription: Cancellable?
        private var elapsed: Float = 0

        init(session: Island3DSession) {
            self.session = session
        }

        func buildScene(in view: ARView) {
            self.view = view
            view.environment.background = .color(UIColor(red: 0.48, green: 0.84, blue: 0.90, alpha: 1))
            view.renderOptions.insert(.disableCameraGrain)
            view.scene.addAnchor(world)

            addWorld()
            addCharacter()
            addCamera()
            addLighting()

            updateSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                Task { @MainActor in
                    self?.update(deltaTime: Float(event.deltaTime))
                }
            }
        }

        private func addWorld() {
            addBox(size: [34, 0.18, 34], position: [0, -0.72, 0], color: UIColor(red: 0.20, green: 0.67, blue: 0.76, alpha: 1))
            addBox(size: [18, 0.34, 15], position: [0, -0.43, 0], color: UIColor(red: 0.96, green: 0.79, blue: 0.47, alpha: 1), cornerRadius: 2.2)
            addBox(size: [15.8, 0.52, 12.8], position: [-0.3, -0.13, -0.2], color: UIColor(red: 0.39, green: 0.68, blue: 0.37, alpha: 1), cornerRadius: 1.8)

            for position in [SIMD3<Float>(-5.3, 0, -3.8), [4.2, 0, -3.4], [-4.5, 0, 3.0], [5.1, 0, 2.2]] {
                addPalm(at: position)
            }

            for position in [SIMD3<Float>(-2.7, 0.25, -1.8), [2.4, 0.25, 0.4], [-1.4, 0.25, 3.4]] {
                let bait = ModelEntity(mesh: .generateSphere(radius: 0.22), materials: [material(UIColor(red: 1, green: 0.74, blue: 0.26, alpha: 1), metallic: true)])
                bait.position = position
                bait.name = "bait"
                world.addChild(bait)
                baitEntities.append(bait)
            }

            for z in stride(from: Float(5.8), through: 9.0, by: 0.72) {
                addBox(size: [2.3, 0.16, 0.58], position: [2.6, -0.02, z], color: UIColor(red: 0.56, green: 0.34, blue: 0.18, alpha: 1), cornerRadius: 0.08)
            }
            addBox(size: [0.16, 0.55, 4.0], position: [1.55, -0.05, 7.4], color: UIColor(red: 0.39, green: 0.24, blue: 0.13, alpha: 1))
            addBox(size: [0.16, 0.55, 4.0], position: [3.65, -0.05, 7.4], color: UIColor(red: 0.39, green: 0.24, blue: 0.13, alpha: 1))

            let fishShadow = ModelEntity(mesh: .generateSphere(radius: 0.34), materials: [material(UIColor(red: 0.08, green: 0.32, blue: 0.38, alpha: 0.72))])
            fishShadow.scale = [1.7, 0.18, 0.72]
            fishShadow.position = [2.6, -0.53, 10.5]
            world.addChild(fishShadow)

            addBox(size: [2.8, 0.28, 2.4], position: [6.7, -0.18, -4.2], color: UIColor(red: 0.91, green: 0.72, blue: 0.43, alpha: 1), cornerRadius: 0.35)
            let barrier = addBox(size: [0.28, 1.3, 2.7], position: [5.25, 0.55, -4.2], color: UIColor(red: 0.70, green: 0.27, blue: 0.20, alpha: 1), cornerRadius: 0.08)
            bridgeBarrier = barrier

            let beacon = ModelEntity(
                mesh: .generateBox(size: [0.22, 3.2, 0.22], cornerRadius: 0.08),
                materials: [UnlitMaterial(color: UIColor(red: 1, green: 0.24, blue: 0.16, alpha: 0.78))]
            )
            beacon.position = [5.0, 2.0, -4.2]
            beacon.isEnabled = false
            world.addChild(beacon)
            bridgeBeacon = beacon

            let chest = addBox(size: [1.05, 0.72, 0.75], position: [7.0, 0.34, -4.2], color: UIColor(red: 0.92, green: 0.55, blue: 0.16, alpha: 1), cornerRadius: 0.12)
            let lid = makePart(size: [1.12, 0.12, 0.82], position: [0, 0.42, 0], color: UIColor(red: 1.0, green: 0.78, blue: 0.22, alpha: 1))
            chest.addChild(lid)
            chestLid = lid

            let goldBeacon = ModelEntity(
                mesh: .generateBox(size: [0.18, 3.6, 0.18], cornerRadius: 0.07),
                materials: [UnlitMaterial(color: UIColor(red: 1, green: 0.78, blue: 0.18, alpha: 0.82))]
            )
            goldBeacon.position = [7.0, 2.2, -4.2]
            goldBeacon.isEnabled = false
            world.addChild(goldBeacon)
            chestBeacon = goldBeacon

            for offset in [SIMD3<Float>(-0.7, 0.8, 0), [0.7, 1.1, 0.2], [0, 1.45, -0.35]] {
                let sparkle = ModelEntity(
                    mesh: .generateSphere(radius: 0.09),
                    materials: [UnlitMaterial(color: UIColor(red: 1, green: 0.88, blue: 0.28, alpha: 1))]
                )
                sparkle.position = SIMD3<Float>(7.0, 0.2, -4.2) + offset
                sparkle.isEnabled = false
                world.addChild(sparkle)
                chestSparkles.append(sparkle)
            }
        }

        private func addCharacter() {
            character.position = [0, 0.45, 2.2]
            world.addChild(character)

            let brown = UIColor(red: 0.62, green: 0.39, blue: 0.23, alpha: 1)
            let tan = UIColor(red: 0.78, green: 0.56, blue: 0.36, alpha: 1)
            let dark = UIColor(red: 0.12, green: 0.20, blue: 0.19, alpha: 1)

            let body = ModelEntity(mesh: .generateSphere(radius: 0.58), materials: [material(brown)])
            body.scale = [0.82, 1.0, 0.72]
            body.position = [0, 0.63, 0]
            character.addChild(body)

            let head = ModelEntity(mesh: .generateSphere(radius: 0.48), materials: [material(brown)])
            head.position = [0, 1.28, -0.08]
            character.addChild(head)
            for x in [-0.31 as Float, 0.31] {
                let ear = ModelEntity(mesh: .generateSphere(radius: 0.16), materials: [material(brown)])
                ear.position = [x, 1.62, -0.08]
                character.addChild(ear)
                let eye = ModelEntity(mesh: .generateSphere(radius: 0.055), materials: [material(dark)])
                eye.position = [x * 0.56, 1.39, -0.43]
                character.addChild(eye)
            }
            let muzzle = ModelEntity(mesh: .generateSphere(radius: 0.26), materials: [material(tan)])
            muzzle.scale = [1.15, 0.72, 0.62]
            muzzle.position = [0, 1.16, -0.43]
            character.addChild(muzzle)
            let nose = ModelEntity(mesh: .generateBox(size: 0.12, cornerRadius: 0.035), materials: [material(dark)])
            nose.position = [0, 1.23, -0.59]
            character.addChild(nose)
            for x in [-0.28 as Float, 0.28] {
                let foot = ModelEntity(mesh: .generateSphere(radius: 0.15), materials: [material(dark)])
                foot.scale = [1.1, 0.55, 1.3]
                foot.position = [x, 0.10, 0.02]
                character.addChild(foot)
            }
        }

        private func addCamera() {
            camera.camera.fieldOfViewInDegrees = 46
            world.addChild(camera)
            updateCamera()
        }

        private func addLighting() {
            let light = DirectionalLight()
            light.light.intensity = 2200
            light.light.color = .white
            light.shadow = DirectionalLightComponent.Shadow(maximumDistance: 35, depthBias: 2)
            light.orientation = simd_quatf(angle: -.pi / 3.2, axis: [1, 0.25, 0])
            world.addChild(light)
        }

        private func update(deltaTime: Float) {
            elapsed += deltaTime
            let input = session.movement
            if simd_length(input) > 0.06 {
                var direction = SIMD3<Float>(input.x, 0, input.y)
                if simd_length(direction) > 1 { direction = simd_normalize(direction) }
                let next = character.position + direction * min(deltaTime, 0.05) * 3.7
                character.position = resolvedPosition(from: character.position, toward: next)
                character.orientation = simd_quatf(angle: atan2(-direction.x, -direction.z), axis: [0, 1, 0])
                character.position.y = 0.45 + sin(elapsed * 13) * 0.035
                updateCamera()
            } else {
                character.position.y += (0.45 - character.position.y) * min(1, deltaTime * 8)
            }

            for bait in baitEntities where bait.parent != nil {
                bait.position.y = 0.27 + sin(elapsed * 3 + bait.position.x) * 0.09
                bait.orientation *= simd_quatf(angle: deltaTime * 1.8, axis: [0, 1, 0])
                if simd_distance(flat(character.position), flat(bait.position)) < 0.72 {
                    bait.removeFromParent()
                    session.collectBait()
                }
            }

            session.nearPier = simd_distance(flat(character.position), SIMD3<Float>(2.6, 0, 7.7)) < 2.15
            session.nearBridge = simd_distance(flat(character.position), SIMD3<Float>(5.1, 0, -4.2)) < 1.75
            session.nearChest = session.bridgeOpen
                && simd_distance(flat(character.position), SIMD3<Float>(7.0, 0, -4.2)) < 1.45

            bridgeBeacon?.isEnabled = session.caughtFish && !session.bridgeOpen
            if let beacon = bridgeBeacon, beacon.isEnabled {
                let pulse = 0.88 + sin(elapsed * 4.2) * 0.18
                beacon.scale = [pulse, 1, pulse]
                beacon.position.y = 2.0 + sin(elapsed * 2.2) * 0.18
            }

            chestBeacon?.isEnabled = session.bridgeOpen && !session.chestOpened
            if let beacon = chestBeacon, beacon.isEnabled {
                let pulse = 0.9 + sin(elapsed * 4.8) * 0.22
                beacon.scale = [pulse, 1, pulse]
                beacon.position.y = 2.2 + sin(elapsed * 2.6) * 0.2
            }

            if session.chestOpened, let lid = chestLid {
                lid.position.y += (0.74 - lid.position.y) * min(1, deltaTime * 4)
                lid.orientation = simd_slerp(
                    lid.orientation,
                    simd_quatf(angle: -0.72, axis: [1, 0, 0]),
                    min(1, deltaTime * 4)
                )
                for (index, sparkle) in chestSparkles.enumerated() {
                    sparkle.isEnabled = true
                    sparkle.position.y = 1.0 + sin(elapsed * 3.4 + Float(index) * 1.8) * 0.5
                    sparkle.scale = SIMD3<Float>(repeating: 0.8 + sin(elapsed * 5 + Float(index)) * 0.25)
                }
            }

            if session.bridgeOpen, let barrier = bridgeBarrier, barrier.parent != nil {
                barrier.removeFromParent()
                for z in [-5.0 as Float, -4.45, -3.9, -3.35] {
                    addBox(size: [0.62, 0.16, 2.4], position: [5.7 + (z + 5) * 0.72, -0.02, -4.2], color: UIColor(red: 0.59, green: 0.38, blue: 0.20, alpha: 1), cornerRadius: 0.06)
                }
            }
        }

        private func resolvedPosition(from current: SIMD3<Float>, toward proposed: SIMD3<Float>) -> SIMD3<Float> {
            var candidate = SIMD3<Float>(proposed.x, current.y, proposed.z)
            if isWalkable(candidate) { return candidate }

            candidate = SIMD3<Float>(proposed.x, current.y, current.z)
            if isWalkable(candidate) { return candidate }

            candidate = SIMD3<Float>(current.x, current.y, proposed.z)
            return isWalkable(candidate) ? candidate : current
        }

        private func isWalkable(_ position: SIMD3<Float>) -> Bool {
            let islandX = (position.x + 0.3) / 8.25
            let islandZ = (position.z + 0.2) / 6.65
            let onIsland = islandX * islandX + islandZ * islandZ <= 1

            let onPier = position.x >= 1.35 && position.x <= 3.85
                && position.z >= 4.9 && position.z <= 9.15

            let inBridgeLane = position.z >= -5.55 && position.z <= -2.85
            let onBridge = session.bridgeOpen && inBridgeLane
                && position.x >= 4.75 && position.x <= 8.15

            if !session.bridgeOpen && inBridgeLane && position.x > 5.0 {
                return false
            }
            return onIsland || onPier || onBridge
        }

        private func updateCamera() {
            let target = character.position + SIMD3<Float>(0, 0.7, 0)
            let cameraPosition = character.position + SIMD3<Float>(0, 8.3, 9.8)
            camera.look(at: target, from: cameraPosition, relativeTo: world)
        }

        private func addPalm(at position: SIMD3<Float>) {
            addBox(size: [0.38, 2.5, 0.38], position: position + [0, 1.22, 0], color: UIColor(red: 0.48, green: 0.29, blue: 0.15, alpha: 1), cornerRadius: 0.12)
            for offset in [SIMD3<Float>(0.45, 2.55, 0), [-0.45, 2.55, 0], [0, 2.55, 0.45], [0, 2.55, -0.45]] {
                let leaf = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [material(UIColor(red: 0.18, green: 0.55, blue: 0.25, alpha: 1))])
                leaf.scale = [1.35, 0.34, 0.72]
                leaf.position = position + offset
                world.addChild(leaf)
            }
        }

        @discardableResult
        private func addBox(size: SIMD3<Float>, position: SIMD3<Float>, color: UIColor, cornerRadius: Float = 0) -> ModelEntity {
            let entity = ModelEntity(mesh: .generateBox(size: size, cornerRadius: cornerRadius), materials: [material(color)])
            entity.position = position
            world.addChild(entity)
            return entity
        }

        private func makePart(size: SIMD3<Float>, position: SIMD3<Float>, color: UIColor) -> ModelEntity {
            let entity = ModelEntity(mesh: .generateBox(size: size, cornerRadius: 0.04), materials: [material(color)])
            entity.position = position
            return entity
        }

        private func material(_ color: UIColor, metallic: Bool = false) -> SimpleMaterial {
            SimpleMaterial(color: color, roughness: metallic ? 0.28 : 0.82, isMetallic: metallic)
        }

        private func flat(_ value: SIMD3<Float>) -> SIMD3<Float> {
            SIMD3(value.x, 0, value.z)
        }
    }
}
