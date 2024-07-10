//
//  main.swift
//  OrganismSim
//
//  Created by Brett Meader on 27/02/2024.
//

import Foundation

var active = true
var sim = Simulation(maxOrganisms: 50, maxBots: 5, maxFood: 100)
var bestScore: Float = 0
var bestOrg: Organism?
var bestWeights: ModelWeights?
sim.onEvolve = { sim in
    print(sim.scores.last!)
    if sim.generation >= 200 { active = false }
    if sim.scores.last!.bestScore * sim.scores.last!.avgScore > bestScore {
        bestScore = sim.scores.last!.bestScore * sim.scores.last!.avgScore
        bestWeights = bestOrg?.model.weights
        print(bestScore)
    }
}
while(active){
    await sim.tick(dt: 0.1)
    bestOrg = sim.currentBestOrganism
}

print(bestWeights!)
print("=== End Simulation ===")

