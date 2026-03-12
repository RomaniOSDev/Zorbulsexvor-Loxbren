//
//  PixelMatchGameView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI
import Combine

final class PixelMatchViewModel: ObservableObject {
    struct Cell: Identifiable {
        let id = UUID()
        var currentIndex: Int
        let solutionIndex: Int
    }

    @Published var cells: [Cell] = []
    @Published var isCompleted: Bool = false
    @Published var hasFailed: Bool = false
    @Published var moves: Int = 0
    @Published var elapsed: TimeInterval = 0

    private var timer: Timer?
    private let maxTime: TimeInterval
    private let colorsCount: Int
    private let gridSize: Int
    private var random: SeededRandom

    init(level: GameLevel, adaptiveModifier: Int, seed: UInt64) {
        func adaptiveTime(base: TimeInterval, modifier: Int) -> TimeInterval {
            switch modifier {
            case -1: return base + 10
            case 1: return max(24, base - 8)
            default: return base
            }
        }

        random = SeededRandom(seed: seed)
        switch level.difficulty {
        case .easy:
            gridSize = 3
            colorsCount = 2
            maxTime = adaptiveTime(base: 60, modifier: adaptiveModifier)
        case .normal:
            gridSize = 4
            colorsCount = 3
            maxTime = adaptiveTime(base: 50, modifier: adaptiveModifier)
        case .hard:
            gridSize = 5
            colorsCount = 4
            maxTime = adaptiveTime(base: 40, modifier: adaptiveModifier)
        }
        generateGrid()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func generateGrid() {
        var result: [Cell] = []
        let total = gridSize * gridSize
        for _ in 0..<total {
            let solution = random.nextInt(upperBound: colorsCount)
            let start = random.nextInt(upperBound: colorsCount)
            result.append(Cell(currentIndex: start, solutionIndex: solution))
        }
        cells = result
        evaluateCompletion()
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

    func tapCell(_ cell: Cell) {
        guard !isCompleted, !hasFailed else { return }
        guard let index = cells.firstIndex(where: { $0.id == cell.id }) else { return }
        var copy = cells[index]
        copy.currentIndex = (copy.currentIndex + 1) % colorsCount
        cells[index] = copy
        moves += 1
        evaluateCompletion()
    }

    private func evaluateCompletion() {
        let allMatch = cells.allSatisfy { $0.currentIndex == $0.solutionIndex }
        if allMatch {
            isCompleted = true
            timer?.invalidate()
        }
    }

    func starsEarned() -> Int {
        guard isCompleted else { return 0 }
        let ratio = elapsed / maxTime
        if ratio <= 0.5, moves <= gridSize * gridSize * 2 {
            return 3
        } else if ratio <= 0.8 {
            return 2
        } else {
            return 1
        }
    }

    func progress() -> Double {
        guard !cells.isEmpty else { return 0 }
        let correct = cells.filter { $0.currentIndex == $0.solutionIndex }.count
        return Double(correct) / Double(cells.count)
    }
}

struct PixelMatchGameView: View {
    let level: GameLevel
    let adaptiveModifier: Int
    let goals: [LevelGoal]
    let seed: UInt64
    let onFinished: (GameResultSummary) -> Void

    @StateObject private var viewModel: PixelMatchViewModel

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
        _viewModel = StateObject(wrappedValue: PixelMatchViewModel(level: level, adaptiveModifier: adaptiveModifier, seed: seed))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                gridView
                infoRow
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(AppScreenBackground())
        .navigationTitle(level.activity.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isCompleted) { _, newValue in
            if newValue {
                finish(didWin: true)
            }
        }
        .onChange(of: viewModel.hasFailed) { _, newValue in
            if newValue {
                finish(didWin: false)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tap tiles to match the target pattern.")
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)

            ProgressView(value: min(viewModel.progress(), 1))
                .tint(.appAccent)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appSurface)
                )
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var gridView: some View {
        let gridSize = Int(Double(viewModel.cells.count).squareRoot().rounded(.up))
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: gridSize), spacing: 6) {
            ForEach(viewModel.cells) { cell in
                RoundedRectangle(cornerRadius: 8)
                    .fill(color(for: cell.currentIndex))
                    .frame(height: tileSize(for: gridSize))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appSurface, lineWidth: 1)
                    )
                    .onTapGesture {
                        viewModel.tapCell(cell)
                    }
            }
        }
        .padding(8)
        .appPanel(cornerRadius: 20)
    }

    private func tileSize(for gridSize: Int) -> CGFloat {
        switch gridSize {
        case 3: return 80
        case 4: return 60
        default: return 48
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
                Image(systemName: "cursorarrow.click")
                Text("\(viewModel.moves) moves")
            }
            .foregroundColor(.appTextSecondary)
            .font(.system(size: 13))
        }
    }

    private func color(for index: Int) -> Color {
        switch index {
        case 0: return .appSurface
        case 1: return .appPrimary
        case 2: return .appAccent
        default: return .appTextSecondary
        }
    }

    private func timeString(from time: TimeInterval) -> String {
        let seconds = Int(time.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func finish(didWin: Bool) {
        let stars = didWin ? viewModel.starsEarned() : 0
        let completedGoals = didWin ? goals.filter { $0.isCompleted(time: viewModel.elapsed, moves: viewModel.moves, mistakes: 0) } : []
        let summary = GameResultSummary(
            level: level,
            stars: stars,
            time: viewModel.elapsed,
            moves: viewModel.moves,
            mistakes: 0,
            didWin: didWin,
            adaptiveModifier: adaptiveModifier,
            goals: goals,
            completedGoals: completedGoals,
            newlyUnlockedAchievements: []
        )
        onFinished(summary)
    }
}

