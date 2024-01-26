//
//  Organism.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

struct Organism: Entity {
    static func == (lhs: Organism, rhs: Organism) -> Bool {
        return lhs.id == rhs.id
    }
    
    internal init(id: String, model: OrganismModel = OrganismModel(), position: (Double, Double) = (0.0, 0.0)) {
        self.id = id
        self.position = position
        self.model = model
    }
    
    var id: String
    var energy: Float = 1.0
    
    var maxTargets = 1
    var targets: [((any Entity), Double)] = []
   
    var threatPosition = (0.0, 0.0)
    var threatDistance: Double = -1.0
    
    var position = (0.0, 0.0)
    var velocity = (0.0, 0.0)
    
    let maxSpeed = 0.0125 + .random(in: 0...0.0125)
    let maxAcceleration = 0.0025 + .random(in: 0...0.0025)
    
    var model: OrganismModel
    
    var currentSpeed: Double {
        return magnitude(velocity)
    }
    
    mutating func think(dt: Double) {
        
//        if let target = self.target {
//            // calculate a normalized direction vector pointing from the organism's position (p1) to the target's position. Normalizing ensures that the vector only indicates the direction without changing the organism's maximum speed.
//            let targetDirection = normalise(vector(p1: self.position, p2: target.position))
//            let threatDirection = normalise(vector(p1: self.position, p2: threatPosition))
//            // Input layer of the MLP that takes the normalised direction vector and distance to the closest target and threat
//            let input = [
//                Float(targetDirection.0), Float(targetDirection.1), Float(targetDistance),
//                Float(threatDirection.0), Float(threatDirection.1), Float(threatDistance)
//            ]
//            // Output of the neural net will be a veclocity vector used to steer the entitity towards its target
//            let velocity = model.predict(input)
//            let (ax, ay) = (Double(velocity[0]), Double(velocity[1]))
//            self.velocity = (
//                (self.velocity.0 + ax * dt * self.maxAcceleration).clamped(to: -maxSpeed...maxSpeed),
//                (self.velocity.1 + ay * dt * self.maxAcceleration).clamped(to: -maxSpeed...maxSpeed)
//            )
//        }
        
     
        // calculate a normalized direction vector pointing from the organism's position (p1) to the target's position. Normalizing ensures that the vector only indicates the direction without changing the organism's maximum speed.
//            let targetDirection = normalise(vector(p1: self.position, p2: target.position))
        let threatDirection = normalise(vector(p1: self.position, p2: threatPosition))
        // Input layer of the MLP that takes the normalised direction vector and distance to the closest target and threat
        var input = [
            Float(threatDirection.0), Float(threatDirection.1), Float(threatDistance)
        ]
        
        // Pad the number of targets if under the max input value
        if targets.count < maxTargets {
            for _ in (targets.count..<maxTargets) {
                targets.append((Origin(), -1))
            }
        }
        
        targets.shuffle()
        
        for idx in (0..<maxTargets) {
            let target = targets[idx]
            let targetDirection = normalise(vector(p1: self.position, p2: target.0.position))
            input += [Float(targetDirection.0), Float(targetDirection.1), Float(target.1)]
        }
    
        // Output of the neural net will be a veclocity vector used to steer the entitity towards its target
        let velocity = model.predict(input)
        let (ax, ay) = (Double(velocity[0]), Double(velocity[1]))
        self.velocity = (
            (self.velocity.0 + ax * dt * self.maxAcceleration).clamped(to: -maxSpeed...maxSpeed),
            (self.velocity.1 + ay * dt * self.maxAcceleration).clamped(to: -maxSpeed...maxSpeed)
        )
    }
}


