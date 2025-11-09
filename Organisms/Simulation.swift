//
//  Simulation.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation
import simd

private actor ConcurrentStore<T> {
    var values: [T] = []
    var valueCount: Int { return values.count }
    init(values: [T]) { self.values = values }
    func valueAtIndex(_ index: Int) -> T { return values[index] }
    func allValues() -> [T] { return values }
    @discardableResult
    func replaceValue(atIndex index: Int, withValue value: T) -> Self { values[index] = value; return self }
    @discardableResult
    func addValues(_ values: [T]) -> Self { self.values += values; return self }
    @discardableResult
    func removeAll() -> Self { values = []; return self }
    @discardableResult
    func removeAll(where: (T) throws -> Bool) rethrows -> Self { try values.removeAll(where: `where`); return self }
}

public struct GenerationScore: Identifiable {
    public var id: Int { return generation }
    var generation: Int = 0
    var bestScore: Float = 0
    var avgScore: Float = 0
    var botsScore: Float = 0
}

public struct Simulation {
    
    public var onEvolve: ((Simulation) -> Void)?
    
    private let organismStore: ConcurrentStore<Organism>
    private var botStore: ConcurrentStore<Bot>
    private var foodStore: ConcurrentStore<Food> = ConcurrentStore(values: [])
    public var organisms: [Organism] {
        get async { return await organismStore.allValues() }
    }
    public var bots: [Bot] {
        get async { return await botStore.allValues() }
    }
    public var foods: [Food] {
        get async { return await foodStore.allValues() }
    }
    
    public var scale: Float
    
    public var maxOrganisms: Int
    public var maxBots: Int
    public var maxFood: Int
    
    private(set) var time: Float = 0
    private(set) var generation: Int = 0
    public var evolutionTime: Float = 60
    public var elitism: Int = 3
    
    public var mutationChance: Float = 0.6
    public var mutationRate: Float = 0.4

    public var food: Float = 4.0
    public var friction: Float = 0.7
    public var botDamage: Float = 0.9
    public var visibility: Float = 4.0
    
    public var foodCollisionDistance: Float = 0.15
    public var botCollisionDistance: Float = 0.1
    
    // Best and avg. scores for each gen
    private(set) var scores: [GenerationScore] = []
    private(set) var currentBestOrganism: Organism?
    
    private(set) var modelWeights: ModelWeights?
    private(set) var modelStructure: MLPNodeStructure?
    
    init(maxOrganisms: Int = 50, maxBots: Int = 3, maxFood: Int = 100, scale: Float = 2.0, modelWeights: ModelWeights? = nil, modelStructure: MLPNodeStructure? = nil) {
        self.maxOrganisms = maxOrganisms
        self.maxBots = maxBots
        self.maxFood = maxFood
        self.scale = scale
        self.modelStructure = modelStructure
        self.modelWeights = modelWeights
        self.organismStore = ConcurrentStore(values: EntityFactory.makeOrganisms(count: maxOrganisms, scale: scale, weights: modelWeights))
        self.botStore = ConcurrentStore(values: EntityFactory.makeBots(count: maxBots, scale: scale))
    }
    
    public mutating func tick(dt: Float = 1/30) async {
        
        time += dt
            
        if time >= evolutionTime {
            await evolve()
            generation += 1
            await resetBots()
            await resetSim()
        }
        
        if await foodStore.valueCount < maxFood {
            await addFoods(count: maxFood - foodStore.valueCount)
        }
         
        await self.updateBots(dt: dt)
        await self.updateOrganisms(dt: dt)
        
        currentBestOrganism = await self.organisms.sorted(by: { $0.energy > $1.energy }).first
    }
    
    private mutating func addFoods(count: Int) async {
        await foodStore.addValues(
            EntityFactory.makeFoods(count: count, scale: self.scale)
        )
    }
    
    private mutating func resetSim() async {
        await foodStore.removeAll()
        self.time = 0.0
        self.currentBestOrganism = nil
    }
}

extension Simulation {
    private func updateOrganism(_ organism: inout Organism, dt: Float) async {
        
        var visibleBots = await bots
            .map { ($0, length($0.position - organism.position)) }
            .filter{ $0.1 < visibility }
            .sorted{ $0.1 > $1.1 }
        
        if !visibleBots.isEmpty {
            let bot = visibleBots.removeLast()
            organism.threatId = bot.0.id
            organism.threatPosition = bot.0.position
        }
        
        // Update Food targets
        //
        let foods = await foods
        var visibleFoods = foods
            .map { ($0, length($0.position - organism.position)) }
            .filter{ $0.1 < visibility }
            .sorted{ $0.1 > $1.1 }
    
//        // Debug logging
//            if Int.random(in: 0...200) == 0 && !visibleFoods.isEmpty {
//                let closest = visibleFoods.last!
//                let farthest = visibleFoods.first!
//                print("Org \(organism.id): \(visibleFoods.count) foods visible, closest=\(closest.1), farthest=\(farthest.1), targeting=\(closest.1)")
//            }
        
        if !visibleFoods.isEmpty {
            let foodDistance = visibleFoods.removeLast()
            organism.targetId = foodDistance.0.id
            organism.targetPosition = foodDistance.0.position
        } 
        else {
            organism.targetId = nil
        }

        organism.think(dt: dt)
        organism.velocity *= pow(friction, dt)
        organism.position = organism.position + organism.velocity
    }
    
    private func updateOrganisms(dt: Float) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for index in 0..<maxOrganisms {
                taskGroup.addTask{
                    var organism = await organismStore.valueAtIndex(index)
                    await updateOrganism(&organism, dt: dt)
                    await updateFitness(&organism, dt: dt)
                    await organismStore.replaceValue(atIndex: index, withValue: organism)
                }
            }
        }
    }
    
    private func updateFitness(_ organism: inout Organism, dt: Float) async {
        // Base energy drain
        organism.energy -= 0.001 * dt
        // Energy drain over time
        let normalisedDistance = length(organism.position) / scale
        let centrePenalty = (normalisedDistance * normalisedDistance) * 0.005 * dt
        organism.energy -= centrePenalty
        
        let targetDistance = length(organism.targetPosition - organism.position)
        if let id = organism.targetId, targetDistance < foodCollisionDistance {
            organism.energy += food
            await foodStore.removeAll(where: { $0.id == id } )
            organism.targetId = nil
        }
        
        if organism.threatId != nil,
            length(organism.threatPosition - organism.position) < botCollisionDistance {
            organism.energy *= pow(botDamage, dt)
            organism.threatId = nil
        }
    }
}

extension Simulation {
    
    private mutating func resetBots() async {
        await botStore.removeAll().addValues(EntityFactory.makeBots(count: maxBots, scale: scale))
    }
    
    private func updateBotTarget(_ bot: inout Bot, targets: [Organism]) {
        bot.target = nil
        bot.targetDistance = -1
        var closest = Float.greatestFiniteMagnitude
        for organism in targets {
            let distance = length(organism.position - bot.position)
            if distance < closest {
                bot.target = organism
                bot.targetDistance = distance
                closest = distance
            }
        }
    }
    
    private func updateBots(dt: Float) async {
        
        await withTaskGroup(of: Void.self) { taskGroup in
            for (idx, bot) in await bots.enumerated() {
                Task {
                    var bot = bot
                    let visibleOrganisms: [Organism] = await organisms.filterByDistance(3.0, relativeTo: bot.position)
                    updateBotTarget(&bot, targets: visibleOrganisms)
                    bot.think(dt: dt)
                    bot.velocity *= pow(friction, dt)
                    bot.position = bot.position + bot.velocity
                    
                    if let target = bot.target {
                        if length(target.position - bot.position) < botCollisionDistance {
                            if target is Organism {
                                bot.energy += dt
                            }
                        }
                    }
                    await botStore.replaceValue(atIndex: idx, withValue: bot)
                }
            }
        }
    }
}

// Crossover and mutate the weights of the best performing organisms
extension Simulation {
    private func crossover(parent1: Organism, parent2: Organism) -> ModelWeights {
        let weight = Float.random(in: 0.4...0.6)
        return ModelWeights(
            inputToHiddenWeights: zip(parent1.model.weights.inputToHiddenWeights, parent2.model.weights.inputToHiddenWeights).map {
                $0.0 * weight + (1 - weight) * $0.1
            },
            inputToHiddenBias: zip(parent1.model.weights.inputToHiddenBias, parent2.model.weights.inputToHiddenBias).map {
                $0.0 * weight + (1 - weight) * $0.1
            },
            hiddenToOutputWeights: zip(parent1.model.weights.hiddenToOutputWeights, parent2.model.weights.hiddenToOutputWeights).map {
                $0.0 * weight + (1 - weight) * $0.1
            },
            hiddenToOutputBias: zip(parent1.model.weights.hiddenToOutputBias, parent2.model.weights.hiddenToOutputBias).map {
                $0.0 * weight + (1 - weight) * $0.1
            })
    }
    
    func selectParent(parentPool: [Organism]) -> Organism {
        // Tournament selection works with negative values
        let tournamentSize = min(5, parentPool.count)
        let tournament = (0..<tournamentSize).map { _ in parentPool.randomElement()! }
        return tournament.max(by: { $0.energy < $1.energy })!
    }
    
    private mutating func evolve() async {
        let oldGen = await organisms.sorted(by: { $0.energy > $1.energy })
        let bestScore = oldGen.first?.energy ?? 0
        let avgScore = oldGen.reduce(0, { $0 + $1.energy }) / Float(oldGen.count)
        
        scores.append(
            GenerationScore(
                generation: self.generation,
                bestScore: bestScore,
                avgScore: avgScore,
                botsScore: await bots.reduce(0.0, { $0 + $1.energy }) / Float(botStore.valueCount)
            )
        )
        
        var newGen: [Organism] = []
        let elitism = min(self.elitism, maxOrganisms)
        for i in 0..<elitism {
            var elite = oldGen[i]
            elite.resetTargets()
            elite.energy = 1.0
            newGen.append(elite)
        }
        
        let parentPool = Array(oldGen.prefix(max(2, oldGen.count / 2)))
        
        // generate offspring
        for idx in newGen.count..<maxOrganisms {
            var offspring: Organism
            if parentPool.count >= 2 {
                var availableParents = parentPool
                let parent1 = selectParent(parentPool: availableParents)
                if let index = availableParents.firstIndex(where: { $0.id == parent1.id }) {
                    availableParents.remove(at: index)
                }
                let parent2 = selectParent(parentPool: availableParents)
                
                let weights = crossover(parent1: parent1, parent2: parent2)
             
                offspring = Organism(
                    id: "thinking_organism_\(idx)_gen_\(generation)",
                    model: OrganismModel( initialWeights: weights ),
                    position: SIMD3<Float>.random(scale: scale),
                    visibility: visibility
                )
                
                if Float.random(in: 0...1) < mutationChance {
                    mutate(weights: &offspring.model.weights)
                }
            }
            else {
                offspring = Organism(
                    id: "thinking_organism_\(idx)_gen_\(generation)",
                    model: OrganismModel(),
                    position: SIMD3<Float>.random(scale: scale),
                    visibility: visibility
                )
            }
            newGen.append(offspring)
        }
        
        await self.organismStore.removeAll().addValues(newGen)
        onEvolve?(self)
    }
    
    private func mutate(weights: inout ModelWeights) {
        let chance = Float.random(in: 0...1)
        if chance < mutationChance {
            let rate = Float.random(in: 1 - mutationRate...1 + mutationRate)
            let rand = Int.random(in: 0..<4)
            switch rand {
            case 0: mutateRandom(weights: &weights.inputToHiddenWeights, rate: rate)
            case 1: mutateRandom(weights: &weights.inputToHiddenBias, rate: rate)
            case 2: mutateRandom(weights: &weights.hiddenToOutputWeights, rate: rate)
            case 3: mutateRandom(weights: &weights.hiddenToOutputBias, rate: rate)
            default: break
            }
        }

        if Float.random(in: 0...1) < 0.2 {
            let rand = Int.random(in: 0..<4)
            switch rand {
            case 0: flipRandom(weights: &weights.inputToHiddenWeights)
            case 1: flipRandom(weights: &weights.inputToHiddenBias)
            case 2: flipRandom(weights: &weights.hiddenToOutputWeights)
            case 3: flipRandom(weights: &weights.hiddenToOutputBias)
            default: break
            }
        }
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
