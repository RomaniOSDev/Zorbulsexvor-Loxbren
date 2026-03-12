//
//  GameModels.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation

enum GameDifficulty: String, CaseIterable, Identifiable, Hashable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

enum GameActivityKind: String, CaseIterable, Identifiable, Hashable {
    case pixelMatch
    case shapeSort
    case patternRecall

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pixelMatch: return "Pixel Match"
        case .shapeSort: return "Shape Sort"
        case .patternRecall: return "Pattern Recall"
        }
    }

    var description: String {
        switch self {
        case .pixelMatch:
            return "Tap tiles to build the correct pixel pattern."
        case .shapeSort:
            return "Follow the contour path by tapping points."
        case .patternRecall:
            return "Watch the glowing tiles, then repeat the full sequence."
        }
    }
}

struct GameLevel: Identifiable, Hashable {
    let id: String
    let index: Int
    let difficulty: GameDifficulty
    let activity: GameActivityKind
    let isDailyChallenge: Bool

    init(id: String, index: Int, difficulty: GameDifficulty, activity: GameActivityKind, isDailyChallenge: Bool = false) {
        self.id = id
        self.index = index
        self.difficulty = difficulty
        self.activity = activity
        self.isDailyChallenge = isDailyChallenge
    }
}

enum LevelGoalKind: Hashable {
    case finishUnder(seconds: Int)
    case maxMoves(Int)
    case noMistakes
}

struct LevelGoal: Hashable, Identifiable {
    let id: String
    let kind: LevelGoalKind

    var title: String {
        switch kind {
        case .finishUnder(let seconds):
            return "Finish under \(seconds)s"
        case .maxMoves(let moves):
            return "Max \(moves) moves"
        case .noMistakes:
            return "No mistakes"
        }
    }

    func isCompleted(time: TimeInterval, moves: Int, mistakes: Int) -> Bool {
        switch kind {
        case .finishUnder(let seconds):
            return Int(time.rounded()) <= seconds
        case .maxMoves(let limit):
            return moves <= limit
        case .noMistakes:
            return mistakes == 0
        }
    }
}

struct DailyChallengeDescriptor {
    let seed: UInt64
    let level: GameLevel
    let displayDate: String
}

struct GameResultSummary: Hashable {
    let level: GameLevel
    let stars: Int
    let time: TimeInterval
    let moves: Int
    let mistakes: Int
    let didWin: Bool
    let adaptiveModifier: Int
    let goals: [LevelGoal]
    let completedGoals: [LevelGoal]
    let newlyUnlockedAchievements: [AppStorageManager.Achievement]
}

