//
//  Simulation.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

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
    public var elitism: Int = 5
    
    public var mutationChance: Float = 0.5
    public var mutationRate: Float = 0.25

    public var food: Float = 2.0
    public var friction: Float = 0.4
    public var botDamage: Float = 0.925
    public var collisionDistance: Float = 0.08
    
    // Best and avg. scores for each gen
    private(set) var scores: [GenerationScore] = []
    private(set) var currentBestOrganism: Organism?
    
    init(maxOrganisms: Int = 50, maxBots: Int = 5, maxFood: Int = 100, scale: Float = 2.0, organismWeights: ModelWeights? = nil) {
        self.maxOrganisms = maxOrganisms
        self.maxBots = maxBots
        self.maxFood = maxFood
        self.scale = scale
        self.organismStore = ConcurrentStore(values: EntityFactory.makeOrganisms(count: maxOrganisms, scale: scale, weights: organismWeights))
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
            .map { ($0, organism.position.distance(from: $0.position)) }
            .filter{ $0.1 < 2 }
            .sorted{ $0.1 < $1.1 }
        
        if !visibleBots.isEmpty {
            let bot = visibleBots.removeFirst()
            organism.threatId = bot.0.id
            organism.threatPosition = bot.0.position
        }
        
        // Update Food targets
        //
        let foods = await foods

        var visibleFoods = foods
//            .filter{ $0.inVisibleRange(of: organism) }
            .map { ($0, organism.position.distance(from: $0.position)) }
            .filter{ $0.1 < 1 }
            .sorted{ $0.1 < $1.1 }
    
        if !visibleFoods.isEmpty {
            let foodDistance = visibleFoods.removeFirst()
            organism.targetId = foodDistance.0.id
            organism.targetPosition = foodDistance.0.position
        }
//        if 
////            (organism.target2Id == nil || visibleFoods.first(where: {$0.0.id == organism.target2Id}) == nil),
//            !visibleFoods.isEmpty {
//            let foodDistance = visibleFoods.removeFirst()
//            organism.target2Id = foodDistance.0.id
//            organism.target2Position = foodDistance.0.position
//        }

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
        var targetDistance = organism.position.distance(from: organism.targetPosition)
        if let id = organism.targetId, targetDistance < collisionDistance {
            organism.energy += food
            await foodStore.removeAll(where: { $0.id == id } )
            organism.targetId = nil
        }
        
        targetDistance = organism.position.distance(from: organism.target2Position)
        if let id = organism.target2Id, targetDistance < collisionDistance {
            organism.energy += food
            await foodStore.removeAll(where: { $0.id == id })
            organism.target2Id = nil
        }
        
        if organism.threatId != nil,
           organism.position.distance(from: organism.threatPosition) < collisionDistance {
            organism.energy *= pow(botDamage, dt)
        }
        organism.threatId = nil
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
            let distance = bot.position.distance(from: organism.position)
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
                        if bot.position.distance(from: target.position) < collisionDistance {
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
    private mutating func evolve() async {
        
        var newGen: [Organism] = []
        var oldGen = await organisms.sorted(by: { $0.energy > $1.energy })
        let elitism = min(self.elitism, maxOrganisms)
//        let elitism = min(min(self.elitism, oldGen.filter {$0.energy > 0.03}.count), maxOrganisms)

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
        
        for (idx, _) in oldGen.suffix(from: 0).enumerated() {
            oldGen[idx].model.destroyNetwork()
        }

        // generate offspring
        for idx in (0..<maxOrganisms - newGen.count) {
            var offspring: Organism
            if elitism > 1 && abs(bestScore - avgScore) > .ulpOfOne {
                var candidates = (0..<elitism).shuffled()
                let lhs = oldGen[candidates.removeFirst()]
                let rhs = oldGen[candidates.removeFirst()]
                
                let pair = rhs.energy > lhs.energy ? (rhs, lhs) : (lhs, rhs)
              
                // Cross-over weight
                let weight = Float.random(in: 0.75...1.0)
                
                var xInputToHiddenWeights: [Float] = zip(
                    pair.0.model.weights.inputToHiddenWeights.map{ $0 * weight },
                    pair.1.model.weights.inputToHiddenWeights.map{ $0 * (1 - weight) }
                ).map(+)
                
                var xInputToHiddenBias: [Float] = zip(
                    pair.0.model.weights.inputToHiddenBias.map{ $0 * weight },
                    pair.1.model.weights.inputToHiddenBias.map{ $0 * (1 - weight)}
                ).map(+)
                
                var xHiddenToOutputWeights: [Float] = zip(
                    pair.0.model.weights.hiddenToOutputWeights.map{ $0 * weight },
                    pair.1.model.weights.hiddenToOutputWeights.map{ $0 * (1 - weight) }
                ).map(+)
                
                var xHiddenToOutputBias: [Float] = zip(
                    pair.0.model.weights.hiddenToOutputBias.map{ $0 * weight },
                    pair.1.model.weights.hiddenToOutputBias.map{ $0 * (1 - weight) }
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
                    position: .init()
                )
            }
            else {
                offspring = Organism(
                    id: "thinking_organism_\(idx)_gen_\(generation)",
                    model: OrganismModel(),
                    position: .init()
                )
            }
            offspring.model.createNetwork()
            newGen.append(offspring)
        }
        
        await self.organismStore.removeAll().addValues(newGen)
        onEvolve?(self)
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
