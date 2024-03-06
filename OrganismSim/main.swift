//
//  main.swift
//  OrganismSim
//
//  Created by Brett Meader on 27/02/2024.
//

import Foundation

var active = true
var sim = Simulation(maxOrganisms: 50, maxBots: 5, maxFood: 50)
sim.onEvolve = { sim in
    print(sim.scores.last!)
    if sim.generation >= 100 { active = false }
}

while(active){ await sim.tick(dt: 1/10) }

print("=== End Simulation ===")

