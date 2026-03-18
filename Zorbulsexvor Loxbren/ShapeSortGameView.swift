//
//  ShapeSortGameView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI
import Combine

// MARK: - ViewModel

final class ShapeSortViewModel: ObservableObject {
    private enum PathPattern: CaseIterable {
        case circle
        case polygon
        case wave
        case zigzag
        case spiral
    }

    struct PathPoint: Identifiable, Hashable {
        let id = UUID()
        let index: Int
        let position: CGPoint
    }

    @Published var points: [PathPoint] = []
    @Published var passedPointIndices: Set<Int> = []
    @Published var activeIndex: Int = 0
    @Published var mistakes: Int = 0
    @Published var isCompleted: Bool = false
    @Published var hasFailed: Bool = false
    @Published var elapsed: TimeInterval = 0
    @Published var moves: Int = 0

    private var timer: Timer?
    private let maxTime: TimeInterval
    private let allowedMistakes: Int
    private let levelIndex: Int
    private let difficulty: GameDifficulty
    private let adaptiveModifier: Int
    private let modifier: LevelModifier?

    init(level: GameLevel, canvasSize: CGSize, adaptiveModifier: Int, seed: UInt64) {
        _ = seed
        levelIndex = level.index
        difficulty = level.difficulty
        self.adaptiveModifier = adaptiveModifier
        self.modifier = level.modifier
        let computedTime: TimeInterval
        let computedMistakes: Int
        switch level.difficulty {
        case .easy:
            switch adaptiveModifier {
            case -1: computedTime = 70
            case 1: computedTime = 52
            default: computedTime = 60
            }
            switch adaptiveModifier {
            case -1: computedMistakes = 9
            case 1: computedMistakes = 7
            default: computedMistakes = 8
            }
        case .normal:
            switch adaptiveModifier {
            case -1: computedTime = 60
            case 1: computedTime = 42
            default: computedTime = 50
            }
            switch adaptiveModifier {
            case -1: computedMistakes = 7
            case 1: computedMistakes = 5
            default: computedMistakes = 6
            }
        case .hard:
            switch adaptiveModifier {
            case -1: computedTime = 50
            case 1: computedTime = 32
            default: computedTime = 40
            }
            switch adaptiveModifier {
            case -1: computedMistakes = 5
            case 1: computedMistakes = 3
            default: computedMistakes = 4
            }
        }
        let timeAfterModifier = modifier == .chronoLock ? max(20, computedTime - 6) : computedTime
        let mistakesAfterModifier = modifier == .precisionSeal ? max(1, computedMistakes - 1) : computedMistakes
        maxTime = timeAfterModifier
        allowedMistakes = mistakesAfterModifier
        generatePath(for: level, in: canvasSize)
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func generatePath(for level: GameLevel, in canvasSize: CGSize) {
        let size = min(canvasSize.width, canvasSize.height) * 0.78
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

        let baseCount: Int
        switch level.difficulty {
        case .easy: baseCount = 6
        case .normal: baseCount = 8
        case .hard: baseCount = 10
        }
        let count = min(baseCount + level.index / 2, 12)
        let pattern = patternForLevel(level)

        var result: [PathPoint] = []
        for index in 0..<count {
            let t = CGFloat(index) / CGFloat(max(count - 1, 1))
            let point = pointFor(pattern: pattern, t: t, center: center, size: size, index: index, total: count)
            result.append(PathPoint(index: index, position: point))
        }
        points = result
        passedPointIndices = []
        activeIndex = 0
    }

    private func patternForLevel(_ level: GameLevel) -> PathPattern {
        let difficultyOffset: Int
        switch level.difficulty {
        case .easy: difficultyOffset = 0
        case .normal: difficultyOffset = 1
        case .hard: difficultyOffset = 2
        }
        let raw = (level.index + difficultyOffset) % PathPattern.allCases.count
        return PathPattern.allCases[raw]
    }

    private func pointFor(pattern: PathPattern,
                          t: CGFloat,
                          center: CGPoint,
                          size: CGFloat,
                          index: Int,
                          total: Int) -> CGPoint {
        switch pattern {
        case .circle:
            let angle = (t * .pi * 2) - (.pi / 2)
            let radius = size * 0.38
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )

        case .polygon:
            // Repeating corners with interpolation to get a crisp angular contour.
            let corners = max(3, min(7, 3 + (levelIndex % 5)))
            let cornerIndex = (index * corners) / max(total, 1)
            let nextCorner = (cornerIndex + 1) % corners
            let localProgress = CGFloat((index * corners) % max(total, 1)) / CGFloat(max(total, 1))

            let a1 = (CGFloat(cornerIndex) / CGFloat(corners)) * .pi * 2 - (.pi / 2)
            let a2 = (CGFloat(nextCorner) / CGFloat(corners)) * .pi * 2 - (.pi / 2)
            let radius = size * 0.36
            let p1 = CGPoint(x: center.x + radius * cos(a1), y: center.y + radius * sin(a1))
            let p2 = CGPoint(x: center.x + radius * cos(a2), y: center.y + radius * sin(a2))
            return CGPoint(
                x: p1.x + (p2.x - p1.x) * localProgress,
                y: p1.y + (p2.y - p1.y) * localProgress
            )

        case .wave:
            let width = size * 0.72
            let height = size * 0.52
            let x = center.x - width / 2 + width * t
            let waves: CGFloat = difficulty == .hard ? 3.0 : 2.0
            let y = center.y + sin((t * .pi * 2 * waves) - .pi / 2) * (height * 0.28)
            return CGPoint(x: x, y: y)

        case .zigzag:
            let width = size * 0.72
            let x = center.x - width / 2 + width * t
            let segments: Int = difficulty == .easy ? 4 : 6
            let segment = Int(t * CGFloat(segments))
            let isUpper = segment.isMultiple(of: 2)
            let y = center.y + (isUpper ? -size * 0.22 : size * 0.22)
            return CGPoint(x: x, y: y)

        case .spiral:
            let turns: CGFloat = difficulty == .hard ? 2.6 : 2.0
            let angle = (t * .pi * 2 * turns) - (.pi / 2)
            let radius = (size * 0.08) + (size * 0.33 * t)
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsed += 0.2
            if elapsed >= maxTime {
                timer?.invalidate()
                if !isCompleted {
                    hasFailed = true
                }
            }
        }
    }

    func handleTap(on point: PathPoint) {
        guard !isCompleted, !hasFailed else { return }
        guard !passedPointIndices.contains(point.index) else { return }
        moves += 1

        if point.index != activeIndex {
            mistakes += 1
            if mistakes > allowedMistakes {
                hasFailed = true
                timer?.invalidate()
                return
            }
        }

        passedPointIndices.insert(point.index)
        advance()
    }

    private func advance() {
        if passedPointIndices.count >= points.count {
            isCompleted = true
            timer?.invalidate()
            return
        }

        while passedPointIndices.contains(activeIndex), activeIndex + 1 < points.count {
            activeIndex += 1
        }
    }

    func starsEarned() -> Int {
        guard isCompleted else { return 0 }
        let timeRatio = elapsed / maxTime

        if timeRatio <= 0.5, mistakes == 0 {
            return 3
        } else if timeRatio <= 0.8, mistakes <= allowedMistakes {
            return 2
        } else {
            return 1
        }
    }
}

// MARK: - View

struct ShapeSortGameView: View {
    let level: GameLevel
    let adaptiveModifier: Int
    let goals: [LevelGoal]
    let seed: UInt64
    let onFinished: (GameResultSummary) -> Void

    @State private var canvasSize: CGSize = .zero
    @State private var flashedPointIndex: Int?
    @StateObject private var viewModelHolder = Holder()

    final class Holder: ObservableObject {
        @Published var vm: ShapeSortViewModel?
    }

    init(level: GameLevel,
         adaptiveModifier: Int,
         goals: [LevelGoal],
         seed: UInt64,
         onFinished: @escaping (GameResultSummary) -> Void) {
        self.level = level
        self.adaptiveModifier = adaptiveModifier
        self.goals = goals
        self.seed = seed
        self.onFinished = onFinished
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Follow the glowing path by tapping points in order.")
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    Color.clear
                    gameCanvas(size: size)
                }
                .onAppear {
                    canvasSize = size
                    if viewModelHolder.vm == nil {
                        viewModelHolder.vm = ShapeSortViewModel(level: level, canvasSize: size, adaptiveModifier: adaptiveModifier, seed: seed)
                    }
                }
            }
            .frame(height: 260)
            .appPanel(cornerRadius: 20)

            if let vm = viewModelHolder.vm {
                infoRow(vm: vm)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppScreenBackground())
        .navigationTitle(level.activity.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModelHolder.vm?.isCompleted ?? false) { _, newValue in
            if newValue {
                finish(didWin: true)
            }
        }
        .onChange(of: viewModelHolder.vm?.hasFailed ?? false) { _, newValue in
            if newValue {
                finish(didWin: false)
            }
        }
    }

    @ViewBuilder
    private func gameCanvas(size: CGSize) -> some View {
        if let vm = viewModelHolder.vm {
            ZStack {
                pathShape(points: vm.points)
                    .stroke(Color.appSurface, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [10, 8]))
                    .allowsHitTesting(false)

                ForEach(vm.points) { point in
                    PathPointView(
                        point: point,
                        isActive: point.index == vm.activeIndex && !vm.passedPointIndices.contains(point.index),
                        isPassed: vm.passedPointIndices.contains(point.index),
                        isFlashed: flashedPointIndex == point.index
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        handleCanvasTap(at: value.location, vm: vm)
                    }
            )
        }
    }

    private func handleCanvasTap(at location: CGPoint, vm: ShapeSortViewModel) {
        guard !vm.points.isEmpty else { return }

        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let dx = a.x - b.x
            let dy = a.y - b.y
            return sqrt(dx * dx + dy * dy)
        }

        guard let nearest = vm.points.min(by: { distance(location, $0.position) < distance(location, $1.position) }) else {
            return
        }

        // Hit radius intentionally generous for reliable taps.
        if distance(location, nearest.position) <= 34 {
            flashedPointIndex = nearest.index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                if flashedPointIndex == nearest.index {
                    flashedPointIndex = nil
                }
            }
            vm.handleTap(on: nearest)
        }
    }

    private func pathShape(points: [ShapeSortViewModel.PathPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first.position)
        for point in points.dropFirst() {
            path.addLine(to: point.position)
        }
        return path
    }

    private func infoRow(vm: ShapeSortViewModel) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(timeString(from: vm.elapsed))
            }
            .foregroundColor(.appTextSecondary)
            .font(.system(size: 13))

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "scribble.variable")
                Text("\(vm.moves) taps")
            }
            .foregroundColor(.appTextSecondary)
            .font(.system(size: 13))

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "xmark.circle")
                Text("\(vm.mistakes)")
            }
            .foregroundColor(.appTextSecondary)
            .font(.system(size: 13))
        }
    }

    private func timeString(from time: TimeInterval) -> String {
        let seconds = Int(time.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func finish(didWin: Bool) {
        guard let vm = viewModelHolder.vm else { return }
        let stars = didWin ? vm.starsEarned() : 0
        let completedGoals = didWin ? goals.filter { $0.isCompleted(time: vm.elapsed, moves: vm.moves, mistakes: vm.mistakes) } : []
        let summary = GameResultSummary(
            level: level,
            stars: stars,
            time: vm.elapsed,
            moves: vm.moves,
            mistakes: vm.mistakes,
            didWin: didWin,
            adaptiveModifier: adaptiveModifier,
            goals: goals,
            completedGoals: completedGoals,
            newlyUnlockedAchievements: []
        )
        onFinished(summary)
    }
}

// MARK: - Point View

private struct PathPointView: View {
    let point: ShapeSortViewModel.PathPoint
    let isActive: Bool
    let isPassed: Bool
    let isFlashed: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 26, height: 26)
            Circle()
                .strokeBorder(borderColor, lineWidth: 2)
                .frame(width: 30, height: 30)
        }
        .allowsHitTesting(false)
        .shadow(color: shadowColor,
                radius: isActive || isFlashed ? 10 : 0,
                x: 0,
                y: 0)
        .scaleEffect(isActive ? 1.1 : (isFlashed ? 0.95 : 1.0))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isActive)
        .animation(.easeInOut(duration: 0.2), value: isFlashed)
        .position(point.position)
    }

    private var backgroundColor: Color {
        if isPassed {
            return .appPrimary
        } else if isActive {
            return .appAccent
        } else if isFlashed {
            return .appSurface.opacity(0.7)
        } else {
            return .appSurface
        }
    }

    private var borderColor: Color {
        if isPassed || isActive {
            return .appAccent
        } else {
            return .appTextSecondary.opacity(0.5)
        }
    }

    private var shadowColor: Color {
        if isActive {
            return .appAccent.opacity(0.8)
        } else if isFlashed {
            return .appPrimary.opacity(0.7)
        } else {
            return .clear
        }
    }
}

