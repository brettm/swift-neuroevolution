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
    public var position: Vector2d = Vector2d()
    public var velocity: Vector2d = Vector2d()
    
    let maxSpeed: Float = 10
    let maxAcceleration: Float = 2
    
    internal init(id: String, model: OrganismModel = OrganismModel(), position: Vector2d = Vector2d()) {
        self.id = id
        self.position = position
        self.model = model
    }
    
    internal var targetId: String?
    internal var targetPosition: Vector2d = Vector2d()
    
    internal var target2Id: String?
    internal var target2Position: Vector2d = Vector2d()
    
    internal var threatId: String?
    internal var threatPosition: Vector2d = Vector2d()
    
    internal var model: OrganismModel
    
    public var currentSpeed: Float {
        return velocity.magnitude()
    }
    
    mutating func think(dt: Float) {
        
        var input: [Float] = [
            0.0, 0.0, -1.0,
            0.0, 0.0, -1.0,
            0.0, 0.0, -1.0
        ]
        
        if threatId != nil {
            let threatDirection = self.position.vector(from: threatPosition).normalise()
            let distance = self.position.distance(from: threatPosition)
            (input[0], input[1]) = (threatDirection.x, threatDirection.y)
            input[2] = distance / 10.0
        }
        
        if targetId != nil {
            let targetDirection = self.position.vector(from: targetPosition).normalise()
            let distance = self.position.distance(from: targetPosition)
            (input[3], input[4]) = (targetDirection.x, targetDirection.y)
            input[5] = distance / 10.0
        }
        
        if target2Id != nil {
            let targetDirection = self.position.vector(from: target2Position).normalise()
            let distance = self.position.distance(from: target2Position)
            (input[6], input[7]) = (targetDirection.x, targetDirection.y)
            input[8] = distance / 10.0
        }
        
        let velocity = model.predict( input )
        let (ax, ay) = (velocity[0], velocity[1])
        self.velocity = Vector2d(
            x: (self.velocity.x + ax * dt * dt * 0.5 * self.maxAcceleration).clamped(to: -maxSpeed...maxSpeed),
            y: (self.velocity.y + ay * dt * dt * 0.5 * self.maxAcceleration).clamped(to: -maxSpeed...maxSpeed)
        )
    }
}


