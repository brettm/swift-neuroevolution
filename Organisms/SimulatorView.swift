//
//  ContentView.swift
//  Organisms
//
//  Created by Brett Meader on 14/01/2024.
//

import SwiftUI

@MainActor
@Observable
class SimulatorViewModel {
    
    var sim: Simulation = Simulation()
    var organisms: [Organism] = []
    var bots: [Bot] = []
    var foods: [Food] = []
    
    nonisolated func tick(dt: Float) async {
        var sim = await sim
        await sim.tick(dt: dt)
        let organisms = await sim.organisms
        let bots = await sim.bots
        let foods = await sim.foods
        await MainActor.run { [sim] in
            self.sim = sim
            self.organisms = organisms
            self.bots = bots
            self.foods = foods
        }
    }
}

@MainActor
enum Globals {
    static let simViewModel = SimulatorViewModel()
}

struct OrganismSimulator: View {
    let viewModel = Globals.simViewModel
    var body: some View {
        ZStack {
            GroupBox {
                ChartContainer()
//                    .padding()
            }
//            .padding()
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
