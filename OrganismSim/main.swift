//
//  main.swift
//  OrganismSim
//
//  Created by Brett Meader on 27/02/2024.
//

import Foundation

var bestOrg: Organism?
var bestWeights: ModelWeights?
var bestScore: Float = 0
var nodes = 32
var structure = MLPNodeStructure(inputNodesCount: 8, hiddenNodesCount: nodes, outputNodesCount: 4)
var active = true
var sim = Simulation(maxOrganisms: 50, maxBots: 2, maxFood: 100, modelStructure: structure)
sim.onEvolve = { sim in
    print(sim.scores.last!)
//    if sim.generation >= 200 { active = false }
    if sim.scores.last!.bestScore > bestScore {
        bestScore = sim.scores.last!.bestScore
        bestWeights = bestOrg?.model.weights
        print("****** NEW BEST SCORE *******\n", bestScore, "\n")
    }
}
while(active){
    await sim.tick(dt: 0.1)
    bestOrg = sim.currentBestOrganism
}

print(bestWeights!)
print(bestScore)
print("=== End Simulation ===")


