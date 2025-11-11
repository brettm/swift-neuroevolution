// Species.swift
import Foundation

// TODO: Implement Speciation

public struct Species: Identifiable {
    public let id = UUID()
    public var representative: Organism?
    public var members: [Organism] = []
    public var averageFitness: Float = 0.0
    public var staleness: Int = 0
}

public class SpeciationManager {
    private var species: [Species] = []
    private let compatibilityThreshold: Float = 0.3  // Balanced for complex environment

    public func speciate(population: [Organism]) {
        species.removeAll()
        
        for organism in population {
            var foundSpecies = false
            
            for i in 0..<species.count {
                if let representative = species[i].representative {
                    let distance = calculateCompatibility(organism, representative)
                    if distance < compatibilityThreshold {
                        species[i].members.append(organism)
                        foundSpecies = true
                        break
                    }
                }
            }
            
            if !foundSpecies {
                var newSpecies = Species()
                newSpecies.representative = organism
                newSpecies.members.append(organism)
                species.append(newSpecies)
                if species.count <= 5 { // Limit debug spam
                    print("New species #\(species.count) - likely different strategy")
                }
            }
        }
        
        species = species.filter { !$0.members.isEmpty }
        
        // Update representatives and calculate fitness
        for i in 0..<species.count {
            if let randomMember = species[i].members.randomElement() {
                species[i].representative = randomMember
            }
        }
        calculateAdjustedFitness()
        
        // Log interesting species info
        if species.count > 1 {
            print("\(species.count) species formed! Potential specialised strategies:")
            for (i, species) in species.enumerated() {
                let best = species.members.max(by: { $0.energy < $1.energy })?.energy ?? 0
                print("  Species \(i): \(species.members.count) members, best: \(best)")
            }
        }
    }
    
    private func calculateCompatibility(_ org1: Organism, _ org2: Organism) -> Float {
        let weights1 = org1.model.weights
        let weights2 = org2.model.weights
        
        var totalDiff: Float = 0.0
        var weightCount: Int = 0
        
        // Compare input-to-hidden weights
        for i in 0..<min(weights1.inputToHiddenWeights.count, weights2.inputToHiddenWeights.count) {
            totalDiff += abs(weights1.inputToHiddenWeights[i] - weights2.inputToHiddenWeights[i])
            weightCount += 1
        }
        
        // Compare hidden-to-output weights
        for i in 0..<min(weights1.hiddenToOutputWeights.count, weights2.hiddenToOutputWeights.count) {
            totalDiff += abs(weights1.hiddenToOutputWeights[i] - weights2.hiddenToOutputWeights[i])
            weightCount += 1
        }
        
        let compatibility = weightCount > 0 ? totalDiff / Float(weightCount) : 1.0
        return compatibility
    }
    
    private func calculateAdjustedFitness() {
        for i in 0..<species.count {
            let speciesSize = species[i].members.count
            var totalFitness: Float = 0.0
            
            for member in species[i].members {
                totalFitness += member.energy
            }
            
            species[i].averageFitness = totalFitness / Float(max(1, speciesSize))
        }
    }
    
    public func getSpeciesInfo() -> [Species] {
        return species
    }
    
    // Add method to clear species between runs if needed
    public func clear() {
        species.removeAll()
    }
}
