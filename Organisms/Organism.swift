//
//  Organism.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation
import simd

let kDefaultEnergy: Float = 1.0

public struct Organism: Entity {
    
    public var id: String
    public var energy: Float = kDefaultEnergy
    public var position = SIMD3<Float>()
    public var velocity = SIMD3<Float>()
    public var visibility: Float
    
    let maxSpeed: Float = 1.0
    let maxAcceleration: Float = 0.1
    
    internal init(id: String, model: OrganismModel = OrganismModel(), position: SIMD3<Float> = .init(), visibility: Float) {
        self.id = id
        self.position = position
        self.model = model
        self.visibility = visibility
    }
    
    internal var targetId: String?
    internal var targetPosition: SIMD3<Float> = .init()
    
    internal var target2Id: String?
    internal var target2Position: SIMD3<Float> = .init()
    
    internal var threatId: String?
    internal var threatPosition: SIMD3<Float> = .init()
    
    internal var model: OrganismModel
    
    public var currentSpeed: Float {
        return length(velocity)
    }
    
    mutating func reset() {
        targetId = nil
        target2Id = nil
        threatId = nil
        energy = kDefaultEnergy
        // Reset position and velocity for new generation
        position = SIMD3<Float>()
        velocity = SIMD3<Float>()
    }
    
    mutating func think(dt: Float) {
        
        var input: [Float] = []
        
        if targetId != nil {
            let toTarget = targetPosition - self.position
            let distance = length(toTarget)
            let direction = toTarget / distance
            let normalisedDistance = min(distance / visibility, 1.0)
            input.append(contentsOf: [direction.x, direction.y, direction.z, normalisedDistance])
        } else {
            input.append(contentsOf: [0,0,0,-1])
        }
        
        if threatId != nil {
            let toThreat = threatPosition - self.position
            let distance = length(toThreat)
            let direction = toThreat / distance
            let normalisedDistance = min(distance / visibility, 1.0)
            input.append(contentsOf: [direction.x, direction.y, direction.z, normalisedDistance])
        } else {
            input.append(contentsOf: [0,0,0,-1])
        }
        
        let output = model.predict( Array(input[0...7]) )
        let acceleration = SIMD3<Float>(output[0], output[1], output[2])
        let throttle = (output[3] + 1) * 0.5 // Convert from [-1,1] to [0,1] for max speed/acceleration calculations
        self.velocity += acceleration * dt * maxAcceleration * throttle
        self.velocity = clamp(velocity, min: -maxSpeed, max: maxSpeed)
    }
        
}


