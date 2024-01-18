//
//  Organism.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

struct Organism: Entity, Identifiable {
    var energy: Float = 1.0
    
    static func == (lhs: Organism, rhs: Organism) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String = "organism"
    var target: (any Entity)?
    var targetDistance: Double = 0.0
    
    var position = (0.0, 0.0)
    var velocity = (Double.random(in: -0.1...0.1), Double.random(in: -0.1...0.1))
    var maxSpeed = 0.01
    var maxAcceleration = 0.01
    
    init(id: String) {
        self.id = id
    }
    
    var currentSpeed: Double {
        return magnitude(velocity)
    }
    
    mutating func think(dt: Double) {
        
        if let target = self.target {
            // calculate a normalized direction vector pointing from the organism's position (p1) to the target's position. Normalizing ensures that the vector only indicates the direction without changing the organism's maximum speed.
            let direction = normalise(vector(p1: self.position, p2: target.position))
            // scale the normalized direction vector by the organism's maximum speed to get the desired velocity. This step is necessary to ensure that the organism moves at a speed proportional to its maximum capability.
            let dvx = direction.0 * self.maxSpeed
            let dvy = direction.1 * self.maxSpeed
            // calculate the difference between the desired velocity and the current velocity. Calculating the difference between the desired velocity and the current velocity is crucial to determine the adjustments needed to steer the organism towards the target. These differences represent the change in velocity required for alignment.
            let deltaX = dvx - self.velocity.0
            let deltaY = dvy - self.velocity.1
            // compute the Euclidean distance between the current velocity and the desired velocity using the Pythagorean theorem. This distance is used in the subsequent steps to compute the acceleration components.
            let diff = sqrt(pow(deltaX, 2) + pow(deltaY, 2))
            // compute the acceleration components along x and y directions, considering the distance (diff) and the organism's maximum acceleration. The division by diff ensures that the acceleration scales with the distance between the current and desired velocities, allowing for smoother adjustments.
            let ax = self.maxAcceleration * deltaX / diff
            let ay = self.maxAcceleration * deltaY / diff
            // update the organism's velocity using a simplified form of the kinematic equation
            // Updating the organism's velocity using a kinematic equation is necessary to modify its position in the simulation over time.
            self.velocity = (
                min(maxSpeed, self.velocity.0 + ax * dt),
                min(maxSpeed, self.velocity.1 + ay * dt)
            )
        }
    }
}

struct ThinkingOrganism: Entity {
    static func == (lhs: ThinkingOrganism, rhs: ThinkingOrganism) -> Bool {
        return lhs.id == rhs.id
    }
    
    internal init(id: String, model: OrganismModel = OrganismModel(), position: (Double, Double) = (0.0, 0.0)) {
        self.id = id
        self.position = position
        self.model = model
    }
    
    var id: String
    var energy: Float = 0.0
    
    var target: (any Entity)?
    var targetDistance: Double = 1.0
    
    var threat: (any Entity)?
    var threatDistance: Double = 1.0
//    var fearLevel: Double = 1.0
    
    var position = (0.0, 0.0)
    var velocity = (0.0, 0.0)
    
    let maxSpeed = 0.1
    let maxAcceleration = 0.025
    
    var model: OrganismModel
    
    var currentSpeed: Double {
        return magnitude(velocity)
    }
    
    mutating func think(dt: Double) {
        
        if let target = self.target {
            // calculate a normalized direction vector pointing from the organism's position (p1) to the target's position. Normalizing ensures that the vector only indicates the direction without changing the organism's maximum speed.
            let targetDirection = normalise(vector(p1: self.position, p2: target.position))
            let threatDirection = normalise(vector(p1: self.position, p2: threat?.position == nil ? (10.0, 10.0) : threat!.position))
            let input = [
                Float(targetDirection.0), Float(targetDirection.1), Float(targetDistance),
//                Float(threatDirection.0), Float(threatDirection.1), Float(threatDistance)
            ]
            let velocity = model.predict(input)
//            print(input)
            let (ax, ay) = (Double(velocity[0]), Double(velocity[1]))
            self.velocity = (
                self.velocity.0 + ax * dt * self.maxAcceleration,
                self.velocity.1 + ay * dt * self.maxAcceleration
            )
        }
    }
}


