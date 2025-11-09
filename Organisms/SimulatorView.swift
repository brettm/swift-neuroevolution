//
//  ContentView.swift
//  Organisms
//
//  Created by Brett Meader on 14/01/2024.
//

import SwiftUI

let modelStructure = MLPNodeStructure(inputNodesCount: 8, hiddenNodesCount: 16, outputNodesCount: 4)

@Observable
class SimulatorViewModel {
    
    var sim: Simulation = Simulation(modelStructure: modelStructure)

    @MainActor
    var organisms: [Organism] = []

    @MainActor
    var bots: [Bot] = []

    @MainActor
    var foods: [Food] = []

    func tick(dt: Float) async {
        await sim.tick(dt: dt)
        let organisms = await sim.organisms
        let bots = await sim.bots
        let foods = await sim.foods
        await MainActor.run {
            self.organisms = organisms
            self.bots = bots
            self.foods = foods
        }
    }
}

struct OrganismSimulator: View {
    var viewModel = SimulatorViewModel()
    var body: some View {
        ZStack {
            GroupBox {
                ChartContainer()
            }
            .padding()
            HUD()
                .padding()
        }
        .task {
            while(true) {
                await viewModel.tick(dt: 0.1)
            }
        }
        .padding()
        .background(.black)
        .foregroundStyle(.white)
        .environment(viewModel)
        .frame(minWidth: 375)
    }
}

//#Preview {
//    ContentView()
//}
