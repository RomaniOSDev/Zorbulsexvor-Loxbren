//
//  PatternRecallGameView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI
import Combine

final class PatternRecallViewModel: ObservableObject {
    enum Phase: Equatable {
        case showing
        case input
        case finished(success: Bool)
    }

    @Published var sequence: [Int] = []
    @Published var highlightedIndex: Int? = nil
    @Published var userInput: [Int] = []
    @Published var phase: Phase = .showing
    @Published var elapsed: TimeInterval = 0
    @Published var moves: Int = 0
    @Published var mistakes: Int = 0

    private let gridSize: Int
    private let colorsCount: Int
    private let maxTime: TimeInterval
    private var timer: Timer?
    private let adaptiveModifier: Int
    private let modifier: LevelModifier?
    private var random: SeededRandom

    init(level: GameLevel, adaptiveModifier: Int, seed: UInt64) {
        self.adaptiveModifier = adaptiveModifier
        self.modifier = level.modifier
        self.random = SeededRandom(seed: seed)
        switch level.difficulty {
        case .easy:
            gridSize = 3
            colorsCount = 3
            switch adaptiveModifier {
            case -1: maxTime = 70
            case 1: maxTime = 52
            default: maxTime = 60
            }
        case .normal:
            gridSize = 3
            colorsCount = 4
            switch adaptiveModifier {
            case -1: maxTime = 60
            case 1: maxTime = 42
            default: maxTime = 50
            }
        case .hard:
            gridSize = 4
            colorsCount = 4
            switch adaptiveModifier {
            case -1: maxTime = 50
            case 1: maxTime = 32
            default: maxTime = 40
            }
        }
        generateSequence(for: level)
        playSequence()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func generateSequence(for level: GameLevel) {
        let baseLength: Int
        switch level.difficulty {
        case .easy: baseLength = 4
        case .normal: baseLength = 6
        case .hard: baseLength = 8
        }
        let adaptiveDelta = adaptiveModifier == -1 ? -1 : (adaptiveModifier == 1 ? 1 : 0)
        let modifierDelta = modifier == .echoShift ? 1 : 0
        let finalLength = max(3, baseLength + adaptiveDelta + modifierDelta)
        var seq: [Int] = []
        for _ in 0..<finalLength {
            seq.append(random.nextInt(upperBound: gridSize * gridSize))
        }
        sequence = seq
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            elapsed += 0.2
            if elapsed >= maxTime {
                timer?.invalidate()
                if case .finished = phase {
                    return
                }
                phase = .finished(success: false)
            }
        }
    }

    private func playSequence() {
        phase = .showing
        highlightedIndex = nil
        userInput = []
        let stepDuration: TimeInterval = modifier == .chronoLock ? 0.45 : 0.6

        for (i, index) in sequence.enumerated() {
            let onTime = TimeInterval(i) * stepDuration
            let offTime = onTime + stepDuration * 0.6
            DispatchQueue.main.asyncAfter(deadline: .now() + onTime) { [weak self] in
                self?.highlightedIndex = index
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + offTime) { [weak self] in
                self?.highlightedIndex = nil
                if i == (self?.sequence.count ?? 0) - 1 {
                    self?.phase = .input
                }
            }
        }
    }

    func tapTile(at index: Int) {
        guard case .input = phase else { return }
        guard userInput.count < sequence.count else { return }
        userInput.append(index)
        moves += 1
        validate()
    }

    private func validate() {
        let currentIndex = userInput.count - 1
        guard currentIndex >= 0 else { return }
        if userInput[currentIndex] != sequence[currentIndex] {
            mistakes += 1
            if modifier == .precisionSeal {
                mistakes += 1
            }
            phase = .finished(success: false)
            timer?.invalidate()
            return
        }
        if userInput.count == sequence.count {
            phase = .finished(success: true)
            timer?.invalidate()
        }
    }

    func starsEarned() -> Int {
        guard case .finished(let success) = phase, success else { return 0 }
        let ratio = elapsed / maxTime
        if ratio <= 0.5, moves == sequence.count {
            return 3
        } else if ratio <= 0.8 {
            return 2
        } else {
            return 1
        }
    }

    func color(for index: Int) -> Color {
        if highlightedIndex == index {
            return .appAccent
        }
        if userInput.contains(index) {
            return .appPrimary
        }
        return .appSurface
    }

    var gridDimension: Int { gridSize }
}

struct PatternRecallGameView: View {
    let level: GameLevel
    let adaptiveModifier: Int
    let goals: [LevelGoal]
    let seed: UInt64
    let onFinished: (GameResultSummary) -> Void

    @StateObject private var viewModel: PatternRecallViewModel

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
        _viewModel = StateObject(wrappedValue: PatternRecallViewModel(level: level, adaptiveModifier: adaptiveModifier, seed: seed))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                grid
                infoRow
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(AppScreenBackground())
        .navigationTitle(level.activity.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.phase) { _, newValue in
            if case .finished(let success) = newValue {
                finish(didWin: success)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watch the glowing tiles, then repeat the full sequence in order.")
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)

            Text(phaseText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appAccent)
        }
    }

    private var grid: some View {
        let dim = viewModel.gridDimension
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: dim), spacing: 8) {
            ForEach(0..<(dim * dim), id: \.self) { index in
                Button {
                    viewModel.tapTile(at: index)
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.color(for: index))
                        .frame(height: tileHeight(for: dim))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                        )
                        .scaleEffect(viewModel.highlightedIndex == index ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.highlightedIndex)
                }
                .buttonStyle(.plain)
                .disabled(!isInputActive)
            }
        }
        .padding(10)
        .appPanel(cornerRadius: 20)
    }

    private func tileHeight(for dim: Int) -> CGFloat {
        switch dim {
        case 3: return 80
        default: return 60
        }
    }

    private var infoRow: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(timeString(from: viewModel.elapsed))
            }
            .foregroundColor(.appTextSecondary)
            .font(.system(size: 13))

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "square.grid.3x3")
                Text("\(viewModel.sequence.count) steps")
            }
            .foregroundColor(.appTextSecondary)
            .font(.system(size: 13))
        }
    }

    private var phaseText: String {
        switch viewModel.phase {
        case .showing:
            return "Watch the pattern..."
        case .input:
            return "Now tap tiles in the same order."
        case .finished(let success):
            return success ? "Sequence complete!" : "Sequence broken."
        }
    }

    private var isInputActive: Bool {
        if case .input = viewModel.phase { return true }
        return false
    }

    private func timeString(from time: TimeInterval) -> String {
        let seconds = Int(time.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func finish(didWin: Bool) {
        let stars = didWin ? viewModel.starsEarned() : 0
        let completedGoals = didWin ? goals.filter { $0.isCompleted(time: viewModel.elapsed, moves: viewModel.moves, mistakes: viewModel.mistakes) } : []
        let summary = GameResultSummary(
            level: level,
            stars: stars,
            time: viewModel.elapsed,
            moves: viewModel.moves,
            mistakes: viewModel.mistakes,
            didWin: didWin,
            adaptiveModifier: adaptiveModifier,
            goals: goals,
            completedGoals: completedGoals,
            newlyUnlockedAchievements: []
        )
        onFinished(summary)
    }
}

