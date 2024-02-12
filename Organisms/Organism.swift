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
    
    var id: String
    var energy: Float = 1.0
    var position = (0.0, 0.0)
    private(set) var velocity = (0.0, 0.0)
    
    let maxSpeed = 0.1//+ .random(in: 0...0.001)
    let maxAcceleration = 0.01 //+ .random(in: 0...0.001)
    
    internal init(id: String, model: OrganismModel = OrganismModel(), position: (Double, Double) = (0.0, 0.0)) {
        self.id = id
        self.position = position
        self.model = model
    }
    
    internal var targetId: String?
    internal var targetPosition = (0.0, 0.0)
    
    internal var target2Id: String?
    internal var target2Position = (0.0, 0.0)
    
    internal var threatId: String?
    internal var threatPosition = (0.0, 0.0)
    
    internal var threat2Id: String?
    internal var threat2Position = (0.0, 0.0)
    
    internal var model: OrganismModel
    
    public var currentSpeed: Double {
        return magnitude(velocity)
    }
    
    mutating func scaleVelocity(_ scalar: Double) {
        self.velocity = (
            self.velocity.0 * scalar,
            self.velocity.1 * scalar
        )
    }
    
    mutating func think(dt: Double) {
        
        var input = [
            0.0, 0.0, -1.0,
            0.0, 0.0, -1.0,
            0.0, 0.0, -1.0
        ]
        
        if targetId != nil {
            let targetDirection = normalise(vector(p1: self.position, p2: targetPosition))
            let distance = distance(p1: self.position, p2: targetPosition)
            (input[0], input[1]) = targetDirection
            input[2] = distance / 10.0
        }
        
        if threatId != nil {
            let threatDirection = normalise(vector(p1: self.position, p2: threatPosition))
            let distance = distance(p1: self.position, p2: threatPosition)
            (input[3], input[4]) = threatDirection
            input[5] = distance / 10.0
        }
        
        if target2Id != nil {
            let targetDirection = normalise(vector(p1: self.position, p2: target2Position))
            let distance = distance(p1: self.position, p2: target2Position)
            (input[6], input[7]) = targetDirection
            input[8] = distance / 10.0
        }
        
//        if threat2Id != nil {
//            let threatDirection = normalise(vector(p1: self.position, p2: threat2Position))
//            let distance = distance(p1: self.position, p2: threat2Position)
//            (input[6], input[7]) = threatDirection
//            input[8] = distance / 10.0
//        }
//        print(input)
        let velocity = model.predict( input.map{ Float($0) } )
//        print(velocity)
        let (ax, ay) = (Double(velocity[0]), Double(velocity[1]))
        self.velocity = (
            (self.velocity.0 + ax * self.maxAcceleration).clamped(to: -maxSpeed...maxSpeed),
            (self.velocity.1 + ay * self.maxAcceleration).clamped(to: -maxSpeed...maxSpeed)
        )
    }
}


