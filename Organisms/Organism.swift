//
//  Organism.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation


public struct Organism: Entity {
    
    public var id: String
    public var energy: Float = 1.0
    public var position = SIMD3<Float>()
    public var velocity = SIMD3<Float>.random(in: -0.01...0.01)
    
    let maxSpeed: Float = 5 + .random(in: 0...1)
    let maxAcceleration: Float = 1 + .random(in: 0...0.5)
    
    internal init(id: String, model: OrganismModel = OrganismModel(), position: SIMD3<Float> = .init()) {
        self.id = id
        self.position = position
        self.model = model
    }
    
    internal var targetId: String?
    internal var targetPosition: SIMD3<Float> = .init()
    
    internal var target2Id: String?
    internal var target2Position: SIMD3<Float> = .init()
    
    internal var threatId: String?
    internal var threatPosition: SIMD3<Float> = .init()
    
    internal var model: OrganismModel
    
    public var currentSpeed: Float {
        return velocity.magnitude()
    }
    
    mutating func think(dt: Float) {
        
        var input: [Float] = [
            0.0, 0.0, 0.0, -1.0,
            0.0, 0.0, 0.0, -1.0,
//            0.0, 0.0, 0.0, -1.0
        ]
        
        if targetId != nil {
            let targetDirection = self.position.vector(from: targetPosition).normalise()
            let distance = self.position.distance(from: targetPosition)
            (input[0], input[1], input[2]) = (targetDirection.x, targetDirection.y, targetDirection.z)
            input[3] = distance/10.0
        }
        
        if threatId != nil {
            let threatDirection = self.position.vector(from: threatPosition).normalise()
            let distance = self.position.distance(from: threatPosition)
            (input[4], input[5], input[6]) = (threatDirection.x, threatDirection.y, threatDirection.z)
            input[7] = distance / 10.0
        }
        
//        if target2Id != nil {
//            let targetDirection = self.position.vector(from: target2Position).normalise()
//            let distance = self.position.distance(from: target2Position)
//            (input[8], input[9], input[10]) = (targetDirection.x, targetDirection.y, targetDirection.z)
//            input[11] = distance / 10.0
//        }
        
        let direction = model.predict( Array(input[0...7]) )
        let (ax, ay, az, speed) = (direction[0], direction[1], direction[2], direction[3])
        self.velocity = SIMD3(
            x: (self.velocity.x + ax * dt * dt * 0.5 * speed).clamped(to: -maxSpeed...maxSpeed),
            y: (self.velocity.y + ay * dt * dt * 0.5 * speed).clamped(to: -maxSpeed...maxSpeed),
            z: (self.velocity.z + az * dt * dt * 0.5 * speed).clamped(to: -maxSpeed...maxSpeed)
        )
    }
}


