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

let positions = [
    (-1.25, 1.0), (0.0, 1.0), (1.25, 1.0),
    (-1.25, 0.0), (0.0, 0.0), (1.25, 0.0),
    (-1.25, -1.0), (0.0, -1.0), (1.25, -1.0)
]

//@Observable
struct Simulation {
    
//    @ObservationIgnored
    var organisms: [Organism] = []
//    @ObservationIgnored
    var bots: [Bot] = []
//    @ObservationIgnored
    var foods: [Food] = []
    
    var horizontalPadding = 0.2
    var verticalPadding = 0.2
    var horizontalScale = (-2.0...2.0)
    var verticalScale = (-2.0...2.0)
    var horizontalSpawnScale: ClosedRange<Double> {
        return ((horizontalScale.lowerBound + horizontalPadding)...(horizontalScale.upperBound - horizontalPadding))
    }
    var verticalSpawnScale: ClosedRange<Double> {
        return ((verticalScale.lowerBound + verticalPadding)...(verticalScale.upperBound - verticalPadding))
    }
    
    var maxOrganisms: Int
    var maxBots: Int
    var maxFood: Int
    
    var time: TimeInterval = 0
    var generation: Int = 0
    var evolutionTime: TimeInterval = 60
    var elitism: Int = 4
    
    var mutationChance: Float = 0.5
    var mutationRate: Float = 0.25

    var friction: Double = 0.5
    
    // Best and avg. scores for each gen
    var scores: [GenScore] = []
    var currentBestOrganism: Organism?
    
    init(maxOrganisms: Int = 50, maxBots: Int = 10, maxFood: Int = 50) {
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
    
    public mutating func tick(dt: Double = 1/30)  {
        
        time += dt
            
        if time >= evolutionTime {
            generation += 1
            evolve()
            resetSim()
        }
        
        let bots = updateBots(bots, dt: dt)
        
        if foods.count < maxFood {
            addFoods(count: maxFood - foods.count)
        }

        var updatedOrganisms = updateOrganisms(organisms, dt: dt)
        updatedOrganisms = updateOrgScore(updatedOrganisms)
        
        self.organisms = updatedOrganisms
        self.bots = bots
    }
    
    private mutating func addFoods(count: Int) {
        self.foods += (0..<count).map{ _ in
            Food(id: "\(UUID())", position: (.random(in: horizontalScale), .random(in: verticalScale)))
        }
    }
    
    private mutating func resetSim() {
        foods.removeAll()
        time = 0.0
        self.currentBestOrganism = nil
        self.resetBots()
    }
}

extension Simulation {
    private func updateOrganisms(_ organisms: [Organism], dt: Double) -> [Organism] {
        
        var updatedOrganisms = organisms
        
        for (idx, organism) in organisms.enumerated() {
            var organism = organism
            
            var visibleBots = bots.map {
                ($0, distance(p1: organism.position, p2: $0.position))
            }
//            .filter {
//                distance(p1: $0.0.position , p2: organism.position) < 0.3
//            }
            .sorted{ $0.1 < $1.1 }
            
            if !visibleBots.isEmpty {
                let bot = visibleBots.removeFirst()
                organism.threatId = bot.0.id
                organism.threatPosition = bot.0.position
            }
            
//            if !visibleBots.isEmpty {
//                let bot = visibleBots.removeFirst()
//                organism.threat2Id = bot.0.id
//                organism.threat2Position = bot.0.position
//            }
            
            // Update Food targets
            //
            var visibleFoods = foods.map {
                ($0, distance(p1: organism.position, p2: $0.position))
            }
//            .filter {
//                distance(p1: $0.0.position , p2: organism.threatPosition) > 0.2
//            }
            .sorted{ $0.1 < $1.1 }
            
            if (organism.targetId == nil || visibleFoods.first(where: {$0.0.id == organism.targetId}) == nil),
                !visibleFoods.isEmpty
            {
                let foodDistance = visibleFoods.removeFirst()
                organism.targetId = foodDistance.0.id
                organism.targetPosition = foodDistance.0.position
            }
            
            if (organism.target2Id == nil || visibleFoods.first(where: {$0.0.id == organism.target2Id}) == nil),
                !visibleFoods.isEmpty
            {
                let foodDistance = visibleFoods.removeFirst()
                organism.target2Id = foodDistance.0.id
                organism.target2Position = foodDistance.0.position
            }
            
            organism.think(dt: dt)
            
            organism.position = (
                organism.position.0 + organism.velocity.0,
                organism.position.1 + organism.velocity.1
            )
            
            organism.scaleVelocity(pow(friction, Double(dt)))
            
            updatedOrganisms[idx] = organism
        }
        
        return updatedOrganisms
    }
    
    private mutating func updateOrgScore(_ organisms: [Organism]) -> [Organism] {
        var updatedOrganisms = organisms
        var bestScore = -Float.greatestFiniteMagnitude
        for (idx, organism) in organisms.enumerated() {
            var organism = organism
            var targetDistance = distance(p1: organism.position, p2: organism.targetPosition)
            if let id = organism.targetId, targetDistance < 0.07 {
                organism.energy += 1
                if organism.energy > 1 {
                    foods.removeAll(where: { $0.id == id})
                    organism.targetId = nil
                }
            }
            
            
            targetDistance = distance(p1: organism.position, p2: organism.target2Position)
            if let id = organism.target2Id, targetDistance < 0.07 {
                organism.energy += 1
                if organism.energy > 1 {
                    foods.removeAll(where: { $0.id == id})
                    organism.target2Id = nil
                }
            }
            
            var threatDistance = distance(p1: organism.position, p2: organism.threatPosition)
            if
                let id = organism.threatId,
                organism.isInRange(horizontal: self.horizontalScale, vertical: verticalScale),
                let bot = bots.first(where:{ $0.id == id }),
                threatDistance < 0.07
            {
                organism.energy -= 3
            }
            organism.threatId = nil
            
//            threatDistance = distance(p1: organism.position, p2: organism.threat2Position)
//            if
//                let id = organism.threat2Id,
//                organism.isInRange(horizontal: self.horizontalScale, vertical: verticalScale),
//                let bot = bots.first(where:{ $0.id == id }),
//                threatDistance < 0.07
//            {
//                organism.energy -= 3
//            }
//            organism.threat2Id = nil
            
            if !organism.isInRange(horizontal: horizontalScale, vertical: verticalScale) {
                organism.energy -= Float(0.005 * distance(p1: organism.position, p2: (0, 0) ))
            }
            
            if organism.energy > bestScore {
                bestScore = organism.energy
                self.currentBestOrganism = organism
            }
            
            updatedOrganisms[idx] = organism
//
//            if organisms[idx].energy < 0 { organisms[idx].energy = 0 }
//            organisms[idx].energy -= Float(0.001)
        }
        
        return updatedOrganisms
    }
}

extension Simulation {
    
    private mutating func resetBots() {
        for (idx, _) in bots.enumerated() {
            bots[idx].position = (.random(in: horizontalSpawnScale), .random(in: verticalSpawnScale))
            bots[idx].velocity = (0.0, 0.0)
            bots[idx].energy = 1.0
        }
    }
    
    private func updateBots(_ bots: [Bot], dt: TimeInterval) -> [Bot] {
        
        let visible = organisms.filterByRange(horizontal: horizontalSpawnScale,
                                              vertical: verticalSpawnScale)

        var updatedBots = bots
        for (bot_idx, bot) in bots.enumerated() {
            var bot = bot
            var leastFit = Double(Int.max)
            for organism in visible {
                guard organism.energy > 0 else { continue }
                let fitness = distance(p1: organism.position, p2: bot.position)
                if fitness < leastFit {
                    bot.target = organism
                    bot.targetDistance = fitness
                    leastFit = fitness
                }
            }
            
            bot.think(dt: dt)
            
            bot.velocity = (
                bot.velocity.0 * pow(friction, Double(dt)),
                bot.velocity.1 * pow(friction, Double(dt))
            )
            
            bot.position = (
                bot.position.0 + bot.velocity.0,
                bot.position.1 + bot.velocity.1
            )
            
            if let target = bot.target {
                if distance(p1: target.position, p2: bot.position) < 0.07 {
                    if target is Organism {
                        bot.energy += 1
                    }
                }
                bot.target = nil
                bot.targetDistance = -1
            }
            
            updatedBots[bot_idx] = bot
        }
        return updatedBots
    }
}

// Crossover and mutate the weights of the best performing organisms
extension Simulation {
    mutating func evolve() {
        
        var newGen: [Organism] = []
        var oldGen = organisms.sorted(by: { $0.energy > $1.energy })
        let elitism = min(self.elitism, maxOrganisms)
        
        scores.append(
            GenScore(
                gen: self.generation,
                bestScore: oldGen.first?.energy,
                avgScore: oldGen.reduce(0, { $0 + $1.energy }) / Float(oldGen.count),
                botsScore: bots.reduce(0.0, { $0 + $1.energy }) / Float(bots.count),
                breedableCount: 0
            )
        )
        
        for (idx, _) in oldGen.suffix(from: 0).enumerated() {
            oldGen[idx].model.destroyNetwork()
        }
        // generate offspring
        for idx in (0..<maxOrganisms - newGen.count) {
            var offspring: Organism
            if elitism > 1 {
                var candidates = (0..<elitism).shuffled()
                let lhs = oldGen[candidates.removeFirst()]
                let rhs = oldGen[candidates.removeFirst()]
                
                let pair = rhs.energy > lhs.energy ? (rhs, lhs) : (lhs, rhs)
              
                // Cross-over weight
                let weight = Float.random(in: 0.75...1.0)
                
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
            newGen[idx].targetId = nil
            newGen[idx].targetPosition = (0, 0)
            newGen[idx].target2Id = nil
            newGen[idx].target2Position = (0, 0)
            newGen[idx].threatId = nil
            newGen[idx].threatPosition = (0, 0)
            newGen[idx].scaleVelocity(0.0)
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
