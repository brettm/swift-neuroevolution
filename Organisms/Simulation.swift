//
//  Simulation.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

struct GenScore {
    var gen: Int = 0
    var bestScore: Float?
    var avgScore: Float = 0.0
    var botsScore: Float?
    var breedableCount: Int = 0
}

@Observable
class Simulation {
    var organisms: [Organism] = []
    var bots: [Bot] = []
    var foods: [Food] = []
    
    var padding = 0.75
    var horizontalScale = (-2.0...2.0)
    var verticalScale = (-2.0...2.0)
    var horizontalSpawnScale: ClosedRange<Double> {
        return ((horizontalScale.lowerBound + padding)...(horizontalScale.upperBound - padding))
    }
    var verticalSpawnScale: ClosedRange<Double> {
        return ((verticalScale.lowerBound + padding)...(verticalScale.upperBound - padding))
    }
    
    var maxOrganisms: Int
    var maxBots: Int
    var maxFood: Int
    
    var time: TimeInterval = 0
    var generation: Int = 0
    var evolutionTime: TimeInterval = 400
    var elitism: Int = 4
    
    var mutationChance: Float = 0.5
    var mutationRate: Float = 0.25

    var friction: Double = 0.75
    
    // Best and avg. scores for each gen
    var scores: [GenScore] = []
    var currentBestOrganism: Organism?
    
    init(maxOrganisms: Int = 50, maxBots: Int = 4, maxFood: Int = 50) {
        self.maxOrganisms = maxOrganisms
        self.maxBots = maxBots
        self.maxFood = maxFood

        self.organisms = (0..<maxOrganisms).map { idx in
            let model = OrganismModel()
            var org = Organism(
                id: "thinking_organism_\(idx)",
                model: model ,
                position: (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale))
            )
            _ = org.model.createNetwork()
            return org
        }
        self.bots = (0..<maxBots).map {idx in
            Bot(
                id: "organism_\(idx)",
                position: (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale))
            )
        }
    }
    
    public func tick(_ dt: TimeInterval = 1/30.0) {
        time += dt
        
        if time > evolutionTime {
            evolve()
            resetSim()
            generation += 1
        }
        
        updateOrgPositions()
        updateOrgFriction(dt)
        updateOrgScore()
        
        if foods.count < maxFood {
            addFood(atPosition: (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale)))
        }
        
        updateBots(dt: dt)
        updateOrganisms(dt: dt)
    }
    
    private func resetSim() {
        foods.removeAll()
        time = 0.0
        self.currentBestOrganism = nil
        self.resetBots()
    }
    
    private func updateOrganisms(dt: TimeInterval) {
        
        updateOrgGoals()
        
        var bestScore = -Float.greatestFiniteMagnitude
        for (idx, _) in organisms.enumerated() {
            if organisms[idx].energy > bestScore {
                bestScore = organisms[idx].energy
                self.currentBestOrganism = organisms[idx]
            }
            organisms[idx].think(dt: Double(dt))
        }
    }
    
    private func updateOrgFriction(_ dt: TimeInterval) {
        for (idx, _) in organisms.enumerated() {
            // Simulate friction
            organisms[idx].velocity = (
                organisms[idx].velocity.0 * pow(friction, Double(dt)),
                organisms[idx].velocity.1 * pow(friction, Double(dt))
            )
        }
    }
    
    private func updateOrgGoals() {
        for (idx, _) in organisms.enumerated() {
            var closest = Double(Int.max)
            for bot in bots {
                let distance = distance(p1: bot.position, p2: organisms[idx].position)
                if distance < closest {
                    organisms[idx].threatPosition = bot.position
                    organisms[idx].threatDistance = tanh(distance)
                    closest = distance
                }
            }
        }
        
        for (idx, _) in organisms.enumerated() {
            let visibleFoods = foods.map {
                ($0, tanh(distance(p1: $0.position, p2: organisms[idx].position)))
            }.sorted{ $0.1 < $1.1 }
            organisms[idx].targets = visibleFoods
        }
    }
    
    public func updateOrgScore() {
        for (idx, organism) in organisms.enumerated() {
            for target in organism.targets {
                if let food = target.0 as? Food,
                   target.1 > 0,
                   target.1 < 0.07 {
                    
                    foods.removeAll(where: { $0 == food})
                    organisms[idx].energy += 1
                }
            }
            
            organisms[idx].targets = []
            
            if organisms[idx].threatDistance > 0,
                organisms[idx].threatDistance < 0.07 {
                organisms[idx].energy -= 1
            }
            organisms[idx].threatPosition = (0, 0)
            organisms[idx].threatDistance = -1
            
            
//            if !organisms[idx].isInRange(horizontal: horizontalSpawnScale, vertical: verticalSpawnScale) {
//                organisms[idx].energy -= Float(0.001 * distance(p1: organisms[idx].position, p2: (0, 0) ))
//            }
//
//            if organisms[idx].energy < 0 { organisms[idx].energy = 0 }
        }
    }
    
    public func resetBots() {
        for (idx, _) in bots.enumerated() {
            bots[idx].position = (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale))
            bots[idx].velocity = (0.0, 0.0)
            bots[idx].energy = 0.0
        }
    }
    
    public func updateBots(dt: TimeInterval) {
        
        let visible = organisms.filterByRange(horizontal: horizontalSpawnScale, 
                                              vertical: verticalSpawnScale)

        for (bot_idx, _) in bots.enumerated() {
            var leastFit = Double(Int.max)
            for organism in visible {
                guard organism.energy > 0 else { continue }
                let fitness = distance(p1: organism.position, p2: bots[bot_idx].position)
                if fitness < leastFit {
                    bots[bot_idx].target = organism
                    bots[bot_idx].targetDistance = fitness
                    leastFit = fitness
                }
            }
            bots[bot_idx].think(dt: dt)
            
            bots[bot_idx].velocity = (
                bots[bot_idx].velocity.0 * pow(friction, Double(dt)),
                bots[bot_idx].velocity.1 * pow(friction, Double(dt))
            )
        }
        
        updateBotPositions()
        
        for (bot_idx, _) in bots.enumerated() {
            if let target = bots[bot_idx].target {
                if distance(p1: target.position, p2: bots[bot_idx].position) < 0.07 {
                    if target is Organism {
                        bots[bot_idx].energy += 1
                    }
                }
                bots[bot_idx].target = nil
                bots[bot_idx].targetDistance = -1
            }
        }
    }
    
    public func addFood(atPosition position: (Double, Double)) {
        foods.append(Food(id: "\(time)", position: position))
    }
    
    private func updateOrgPositions() {
        for (idx, _) in organisms.enumerated() {
            organisms[idx].position = (
                organisms[idx].position.0 + organisms[idx].velocity.0,
                organisms[idx].position.1 + organisms[idx].velocity.1
            )
        }
    }
    
    private func updateBotPositions() {
        for (idx, _) in bots.enumerated() {
            bots[idx].position = (
                bots[idx].position.0 + bots[idx].velocity.0,
                bots[idx].position.1 + bots[idx].velocity.1
            )
        }
    }
}

// Crossover and mutate the weights of the best performing organisms
extension Simulation {
    func evolve() {
        
        var newGen: [Organism] = []
        var oldGen = organisms.sorted(by: { $0.energy > $1.energy })
        let breedable = oldGen.filter{ $0.energy > 1 }
        let elitism = min(self.elitism, breedable.count)
        
        scores.append(
            GenScore(
                gen: self.generation,
                bestScore: oldGen.first?.energy,
                avgScore: oldGen.reduce(0, { $0 + $1.energy }) / Float(oldGen.count),
                botsScore: bots.reduce(0.0, { $0 + $1.energy }) / Float(bots.count),
                breedableCount: breedable.count
            )
        )
        
        // Elite can cross generations
        newGen.append(contentsOf: oldGen.prefix(elitism))
        // destroy non-breeders
        for (idx, _) in oldGen.suffix(from: elitism).enumerated() {
            oldGen[elitism+idx].model.destroyNetwork()
        }
        // generate offspring
        for idx in (0..<maxOrganisms - newGen.count) {
            var offspring: Organism
            if elitism > 0 {
                var candidates = (0..<elitism).shuffled()
                let lhs = oldGen[candidates.removeFirst()]
                let rhs = candidates.count > 0 ? oldGen[candidates.removeFirst()] : lhs
                let pair = (lhs, rhs)
                
                // Cross-over weight
                let weight = Float.random(in: 0.0...1.0)
                
                var xInputToHiddenWeights: [Float] = zip(
                    pair.0.model.inputToHiddenWeights.map{ $0 * weight },
                    pair.1.model.inputToHiddenWeights.map{ $0 * (1 - weight) }
                ).map(+)
                
                var xInputToHiddenBias: [Float] = zip(
                    pair.0.model.inputToHiddenBias.map{ $0 * weight },
                    pair.1.model.inputToHiddenBias.map{ $0 * (1 - weight)}
                ).map(+)
                
                var xHiddenToOutputWeights: [Float] = zip(
                    pair.0.model.hiddenToOutputWeights.map{ $0 * weight },
                    pair.1.model.hiddenToOutputWeights.map{ $0 * (1 - weight) }
                ).map(+)
                
                var xHiddenToOutputBias: [Float] = zip(
                    pair.0.model.hiddenToOutputBias.map{ $0 * weight },
                    pair.1.model.hiddenToOutputBias.map{ $0 * (1 - weight) }
                ).map(+)
                
                // Mutation
                let chance = Float.random(in: 0...1)
                if chance < mutationChance {
                    let mutationRate = Float.random(in: 1-mutationRate...1+mutationRate)
                    let rand = Int.random(in: 0..<4)
                    switch rand {
                    case 0: mutateRandom(weights: &xInputToHiddenWeights, rate: mutationRate)
                    case 1: mutateRandom(weights: &xInputToHiddenBias, rate: mutationRate)
                    case 2: mutateRandom(weights: &xHiddenToOutputWeights, rate: mutationRate)
                    case 3: mutateRandom(weights: &xHiddenToOutputBias, rate: mutationRate)
                    default: break
                    }
                }

                if Bool.random() {
                    let rand = Int.random(in: 0..<4)
                    switch rand {
                    case 0: flipRandom(weights: &xInputToHiddenWeights)
                    case 1: flipRandom(weights: &xInputToHiddenBias)
                    case 2: flipRandom(weights: &xHiddenToOutputWeights)
                    case 3: flipRandom(weights: &xHiddenToOutputBias)
                    default: break
                    }
                }
                
                offspring = Organism(
                    id: "thinking_organism_\(idx)_gen_\(generation)",
                    model: OrganismModel(
                        inputToHiddenWeights: xInputToHiddenWeights,
                        inputToHiddenBias: xInputToHiddenBias,
                        hiddenToOutputWeights: xHiddenToOutputWeights,
                        hiddenToOutputBias: xHiddenToOutputBias
                    ),
                    position: (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale))
                )
            }
            else {
                offspring = Organism(
                    id: "thinking_organism_\(idx)_gen_\(generation)",
                    model: OrganismModel(),
                    position: (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale))
                )
            }
            offspring.model.createNetwork()
            newGen.append(offspring)
        }

        // reset any organisms from older generations
        for (idx, _) in newGen.enumerated() {
            newGen[idx].energy = 1
            newGen[idx].targets = []
            newGen[idx].threatPosition = (0, 0)
            newGen[idx].threatDistance = -1
            newGen[idx].velocity = (0, 0)
        }
        
        self.organisms = newGen
    }
    
    private func mutateRandom(weights: inout [Float], rate: Float) {
        guard weights.count > 0 else { return }
        let idx = Int.random(in: 0..<weights.count)
        weights[idx] = (weights[idx] * rate).clamped(to: (-1...1))
    }
    
    private func flipRandom(weights: inout [Float]) {
        guard weights.count > 0 else { return }
        let idx = Int.random(in: 0..<weights.count)
        weights[idx] = -weights[idx]
    }
}
