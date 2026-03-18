//
//  HomeViewModel.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var selectedChapterID: String

    let chapters: [AtlasChapter]

    init() {
        chapters = HomeViewModel.buildChapters()
        selectedChapterID = chapters.first?.id ?? "atlas_1"
    }

    var selectedChapter: AtlasChapter? {
        chapters.first(where: { $0.id == selectedChapterID })
    }

    func isNodeUnlocked(chapterID: String, nodeID: String, storage: AppStorageManager) -> Bool {
        let allNodes = chapters.flatMap { chapter in
            chapter.nodes.map { (chapter.id, $0.id) }
        }
        guard let index = allNodes.firstIndex(where: { $0.0 == chapterID && $0.1 == nodeID }) else {
            return false
        }
        if index == 0 { return true }
        let previous = allNodes[index - 1]
        return storage.isAtlasNodeCompleted(previous.1)
    }

    func completionRatio(chapter: AtlasChapter, storage: AppStorageManager) -> Double {
        guard !chapter.nodes.isEmpty else { return 0 }
        let completed = chapter.nodes.filter { storage.isAtlasNodeCompleted($0.id) }.count
        return Double(completed) / Double(chapter.nodes.count)
    }

    private static func buildChapters() -> [AtlasChapter] {
        [
            AtlasChapter(
                id: "atlas_1",
                title: "Fracture Gate",
                lore: "Recover the first signal shards across unstable glyph zones.",
                accentSymbol: "sparkles",
                nodes: [
                    AtlasNode(
                        id: "node_1_1",
                        title: "Green Pulse",
                        subtitle: "Intro signal alignment",
                        level: GameLevel(id: "atlas_1_node_1", index: 0, difficulty: .easy, activity: .pixelMatch, chapterID: "atlas_1", nodeID: "node_1_1", modifier: .chronoLock)
                    ),
                    AtlasNode(
                        id: "node_1_2",
                        title: "Echo Path",
                        subtitle: "Follow shifting traces",
                        level: GameLevel(id: "atlas_1_node_2", index: 1, difficulty: .easy, activity: .shapeSort, chapterID: "atlas_1", nodeID: "node_1_2", modifier: .echoShift)
                    ),
                    AtlasNode(
                        id: "node_1_3",
                        title: "Recall Core",
                        subtitle: "Stabilize sequence memory",
                        level: GameLevel(id: "atlas_1_node_3", index: 2, difficulty: .easy, activity: .patternRecall, chapterID: "atlas_1", nodeID: "node_1_3", modifier: .precisionSeal)
                    )
                ]
            ),
            AtlasChapter(
                id: "atlas_2",
                title: "Neon Vault",
                lore: "Signal density rises. Precision now matters more than speed.",
                accentSymbol: "bolt.fill",
                nodes: [
                    AtlasNode(
                        id: "node_2_1",
                        title: "Mirror Grid",
                        subtitle: "Dual-state pixel weave",
                        level: GameLevel(id: "atlas_2_node_1", index: 3, difficulty: .normal, activity: .pixelMatch, chapterID: "atlas_2", nodeID: "node_2_1", modifier: .echoShift)
                    ),
                    AtlasNode(
                        id: "node_2_2",
                        title: "Vector Trails",
                        subtitle: "Sharp path tracking",
                        level: GameLevel(id: "atlas_2_node_2", index: 4, difficulty: .normal, activity: .shapeSort, chapterID: "atlas_2", nodeID: "node_2_2", modifier: .precisionSeal)
                    ),
                    AtlasNode(
                        id: "node_2_3",
                        title: "Lumen Recall",
                        subtitle: "Compressed input window",
                        level: GameLevel(id: "atlas_2_node_3", index: 5, difficulty: .normal, activity: .patternRecall, chapterID: "atlas_2", nodeID: "node_2_3", modifier: .chronoLock)
                    )
                ]
            ),
            AtlasChapter(
                id: "atlas_3",
                title: "Obsidian Relay",
                lore: "Final relay. Every move distorts the field.",
                accentSymbol: "moon.stars.fill",
                nodes: [
                    AtlasNode(
                        id: "node_3_1",
                        title: "Core Cascade",
                        subtitle: "Dense pixel pressure",
                        level: GameLevel(id: "atlas_3_node_1", index: 6, difficulty: .hard, activity: .pixelMatch, chapterID: "atlas_3", nodeID: "node_3_1", modifier: .precisionSeal)
                    ),
                    AtlasNode(
                        id: "node_3_2",
                        title: "Void Route",
                        subtitle: "Fractured contour lanes",
                        level: GameLevel(id: "atlas_3_node_2", index: 7, difficulty: .hard, activity: .shapeSort, chapterID: "atlas_3", nodeID: "node_3_2", modifier: .chronoLock)
                    ),
                    AtlasNode(
                        id: "node_3_3",
                        title: "Final Echo",
                        subtitle: "Maximum sequence load",
                        level: GameLevel(id: "atlas_3_node_3", index: 8, difficulty: .hard, activity: .patternRecall, chapterID: "atlas_3", nodeID: "node_3_3", modifier: .echoShift)
                    )
                ]
            )
        ]
    }
}

