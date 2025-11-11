//
//  HUDView.swift
//  Organisms
//
//  Created by Brett Meader on 27/02/2024.
//

import SwiftUI

private extension GenerationScore {
    static var generationTitle: String { return "GEN" }
    static var bestScoreTitle: String { return "Best" }
    static var averageScoreTitle: String { return "AVG" }
    static var botScoreTitle: String { return "Bots" }
}

private struct Scores: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }
    #else
    private let isCompact = false
    #endif
    @State private var sortOrder = [KeyPathComparator<GenerationScore>(\.generation, order: .reverse)]
    let scores: [GenerationScore]
    var body: some View {
        Table(scores, sortOrder: $sortOrder) {
            TableColumn(GenerationScore.generationTitle, value: \.generation) { score in
                if isCompact { Text("Best: \(score.bestScore)\nAvg: \(score.avgScore)") }
                else { Text(score.generation.description) }
            }
            TableColumn(GenerationScore.averageScoreTitle, value: \.avgScore.description)
            TableColumn(GenerationScore.bestScoreTitle, value: \.bestScore.description)
            TableColumn(GenerationScore.botScoreTitle, value: \.botsScore.description)
        }
    }
}

struct HUD: View {
    @Environment(SimulatorViewModel.self) var viewModel: SimulatorViewModel
    var body: some View {
        VStack {
            Text("Current generation: \(viewModel.sim.generation)")
            Text(String(format: "Elapsed: %07.2f", viewModel.sim.time))
            Spacer()
            if let best = viewModel.sim.currentBestOrganism {
                HStack(alignment: .bottom) {
                    VStack {
                        Spacer()
                        Scores(scores: viewModel.sim.scores.reversed())
                            .scrollContentBackground(.hidden)
                            .frame(maxHeight: 120.0)
                    }
                    .frame(minWidth: 200, maxWidth: .infinity)
                    .foregroundStyle(.green)
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "triangle.fill")
                            Text("\(best.id)").lineLimit(1).truncationMode(.head)
                            Text(String(format: "%.2f", best.energy)).lineLimit(1)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .foregroundStyle(.green)
                }
                .padding()
            }
        }
    }
}
