//
//  Simulation.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

@Observable
class Simulation {
    var organisms: [ThinkingOrganism] = []
    var bots: [Organism] = []
    var foods: [Food] = []
    
    var horizontalScale = (-2.5...2.5)
    var verticalScale = (-2.5...2.5)
    var horizontalSpawnScale: ClosedRange<Double> {
        return (horizontalScale.lowerBound + 1.0...horizontalScale.upperBound - 1.0)
    }
    var verticalSpawnScale: ClosedRange<Double> {
        return (verticalScale.lowerBound + 1.0...verticalScale.upperBound - 1.0)
    }
    
    var time: TimeInterval = 0
    var generation: Int = 0
    var evolutionTime: TimeInterval = 400
    var elitism: Int = 4
    var maxOrganisms: Int
    var maxBots: Int
    var mutationChance: Float = 0.1
    var mutationRate: Float = 0.1
    var maxFood: Int = 20
    
    var currentBestOrganism: String?
    var currentBestScore: Float = 0.0
    // Best and avg. scores for each gen
    var scores: [(String, Float, Float)] = []
    
    init(maxOrganisms: Int = 40, maxBots: Int = 1) {
        self.maxOrganisms = maxOrganisms
        self.maxBots = maxBots
        self.organisms = (0..<maxOrganisms).map { idx in
            let model = OrganismModel(
                inputToHiddenWeights: (0..<9).map { _ in .random(in: -1.0...1.0) },
                inputToHiddenBias: (0..<9).map { _ in .random(in: -0.01...0.01) },
                hiddenToOutputWeights: (0..<6).map { _ in .random(in: -1.0...1.0) },
                hiddenToOutputBias: (0..<6).map { _ in .random(in: -0.01...0.01) }
            )
            var org = ThinkingOrganism(
                id: "thinking_organism_\(idx)",
                model: model ,
                position: (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale))
            )
            _ = org.model.createNetwork()
            return org
        }
        
        self.bots = (0..<maxBots).map {idx in
            Organism(id: "organism_\(idx)")
        }
    }
    
    public func tick(_ dt: TimeInterval = 1/30.0) {
        time += dt
        
        if time > evolutionTime {
            evolve()
            foods.removeAll()
            time = 0.0
            generation += 1
            self.currentBestScore = 0
            self.currentBestOrganism = nil
        }
        
        if foods.count < maxFood {
            addFood(atPosition: (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale)))
        }
        
        updateOrganisms(dt: dt)
        updateBots(dt: dt)
    }
    
    private func updateOrganisms(dt: TimeInterval) {
        
        for (idx, _) in organisms.enumerated() {
            var closest = Double(Int.max)
            for bot in bots {
                let distance = distance(p1: bot.position, p2: organisms[idx].position)
                if distance < closest {
                    organisms[idx].threat = bot
                    organisms[idx].threatDistance = tanh(distance)
                    closest = distance
                }
            }
        }
        
        for (idx, _) in organisms.enumerated() {
            var closest = Double(Int.max)
            for food in foods {
                let distance = distance(p1: food.position, p2: organisms[idx].position)
                if distance < closest {
                    organisms[idx].target = food
                    organisms[idx].targetDistance = distance
                    closest = distance
                }
            }
        }
        
        for (idx, _) in organisms.enumerated() {
            if organisms[idx].energy > self.currentBestScore {
                self.currentBestScore = organisms[idx].energy
                self.currentBestOrganism = organisms[idx].id
            }
            organisms[idx].think(dt: Double(dt))
            // Simulate friction
            organisms[idx].velocity = (
                organisms[idx].velocity.0 * pow(0.75, Double(dt)),
                organisms[idx].velocity.1 * pow(0.75, Double(dt))
            )
        }
        
        updateOrgPositions()
        
        for (idx, _) in organisms.enumerated() {
            if let target = organisms[idx].target {
                if distance(p1: target.position, p2: organisms[idx].position) < 0.075 {
                    if target is Food {
                        foods.removeAll(where: { $0 == target as! Food })
                        organisms[idx].energy += target.energy
                    }
                }
                organisms[idx].target = nil
                organisms[idx].targetDistance = 1
            }
            if let threat = organisms[idx].threat {
                if distance(p1: threat.position, p2: organisms[idx].position) < 0.075 {
                    if threat is Organism {
//                        organisms[idx].energy -= 1 //target.energy
                    }
                }
                organisms[idx].threat = nil
                organisms[idx].threatDistance = 1
            }
        }
    }
    
    public func updateBots(dt: TimeInterval) {
        
        for (bot_idx, _) in bots.enumerated() {
            var leastFit = Double(Int.max)
            for organism in organisms {
                let fitness = distance(p1: organism.position, p2: bots[bot_idx].position)
                if fitness < leastFit {
                    bots[bot_idx].target = organism
                    bots[bot_idx].targetDistance = fitness
                    leastFit = fitness
                }
            }
            bots[bot_idx].think(dt: dt)
            bots[bot_idx].velocity = (
                bots[bot_idx].velocity.0 * pow(0.75, Double(dt)),
                bots[bot_idx].velocity.1 * pow(0.75, Double(dt))
            )
        }
        
        updateBotPositions()
        
        for (bot_idx, _) in bots.enumerated() {
            if let target = bots[bot_idx].target {
                if distance(p1: target.position, p2: bots[bot_idx].position) < 0.075 {
                    if target is ThinkingOrganism {
                        bots[bot_idx].energy += 1.0
                    }
                }
                bots[bot_idx].target = nil
                bots[bot_idx].targetDistance = 1
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

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// Crossover and mutate the weights of the best performing organisms
extension Simulation {
    func evolve() {
        
        var newGen: [ThinkingOrganism] = []
        var oldGen = organisms.sorted(by: { $0.energy > $1.energy })
        
        scores.append((
            "Gen \(self.generation)",
            oldGen.first!.energy,
            oldGen.reduce(0, { $0 + $1.energy }) / Float(oldGen.count)
        ))
        
        for idx in (0..<maxOrganisms) {
            // Selection
            var candidates = (0..<elitism).shuffled()
            let pair = (oldGen[candidates.removeFirst()], oldGen[candidates.removeFirst()])
            
            // Cross-over
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
            
            let offspring = ThinkingOrganism(
                id: "thinking_organism_\(idx)_gen_\(generation)",
                model: OrganismModel(
                    inputToHiddenWeights: xInputToHiddenWeights,
                    inputToHiddenBias: xInputToHiddenBias,
                    hiddenToOutputWeights: xHiddenToOutputWeights,
                    hiddenToOutputBias: xHiddenToOutputBias
                ), 
                position: (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale))
            )
            newGen.append(offspring)
            
            oldGen[idx].model.destroyNetwork()
             _ = newGen[idx].model.createNetwork()
        }
        self.organisms = newGen
    }
    
    private func mutateRandom(weights: inout [Float], rate: Float) {
        guard weights.count > 0 else { return }
        let idx = Int.random(in: 0..<weights.count)
        weights[idx] = (weights[idx] * rate).clamped(to: (-1...1))
    }
}
