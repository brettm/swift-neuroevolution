//
//  Bot.swift
//  Organisms
//
//  Created by Brett Meader on 24/01/2024.
//

import Foundation

public struct Bot: Entity, Identifiable {
        
    public var id: String = "organism"
    public var energy: Float = 1.0
    
    var target: (any Entity)?
    var targetDistance: Float = 0.0
    
    public var position: Vector2d = Vector2d()
    public var velocity: Vector2d = Vector2d()

    var maxSpeed: Float = 2 + .random(in: 0...0.1)
    var maxAcceleration: Float = 0.25 + .random(in: 0...0.05)
    
    init(id: String, position: Vector2d = Vector2d()) {
        self.id = id
        self.position = position
    }
    
    var currentSpeed: Float {
        return velocity.magnitude()
    }
    
    mutating func think(dt: Float) {
        
        if let target = self.target {
            //  Normalizing ensures that the vector only indicates the direction without changing the organism's maximum speed.
            let direction = self.position.vector(from: target.position).normalise()
            //  Scale the normalized direction vector by the organism's maximum speed to get the desired velocity. This step is necessary to ensure that the organism moves at a speed proportional to its maximum capability.
            let dv = direction * self.maxSpeed
            //  Calculating the difference between the desired velocity and the current velocity is crucial to determine the adjustments needed to steer the organism towards the target. These differences represent the change in velocity required for alignment.
            let delta = dv - self.velocity
            //  Compute the Euclidean distance between the current velocity and the desired velocity using the Pythagorean theorem. This distance is used in the subsequent steps to compute the acceleration components.
            let diff = delta.magnitude()
            //  Compute the acceleration components along x and y directions, considering the distance (diff) and the organism's maximum acceleration. The division by diff ensures that the acceleration scales with the distance between the current and desired velocities, allowing for smoother adjustments.
            let acceleration =  delta / diff * self.maxAcceleration
            //  Updating the organism's velocity using a kinematic equation is necessary to modify its position in the simulation over time.
            self.velocity = Vector2d(
                x: (self.velocity.x + acceleration.x * dt * dt * 0.5).clamped(to: -maxSpeed...maxSpeed),
                y: (self.velocity.y + acceleration.y * dt * dt * 0.5).clamped(to: -maxSpeed...maxSpeed)
            )
        }
    }
}
