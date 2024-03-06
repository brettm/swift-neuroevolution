//
//  Math.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

public struct Vector2d: Equatable {
    var x: Float = 0
    var y: Float = 0
    
    static func random(scale: Float) -> Vector2d {
        return Self(x: .random(in: -scale...scale), y: Float.random(in: -scale...scale))
    }
    
    func distance(from vector: Vector2d) -> Float {
        let directionVector = self.vector(from: vector)
        return sqrt(pow(directionVector.x, 2) + pow(directionVector.y, 2))
    }
    
    func vector(from p2: Vector2d) -> Vector2d {
        let p1 = self
        return Vector2d(x: p2.x - p1.x, y: p2.y - p1.y)
    }
    
    func magnitude() -> Float {
        return sqrt(pow(x, 2) + pow(y, 2))
    }
    
    func normalise() -> Vector2d {
        let m = magnitude()
        return Vector2d(x: x/m, y: y/m)
    }
    
    static func +(left: Vector2d, right: Vector2d) -> Vector2d {
        return Vector2d(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func -(left: Vector2d, right: Vector2d) -> Vector2d {
        return Vector2d(x: left.x - right.x, y: left.y - right.y)
    }
    
    static func *(left: Vector2d, right: Float) -> Vector2d {
        return Vector2d(x: left.x * right, y: left.y * right)
    }
    
    static func *=(left: inout Vector2d, right: Float) {
        left.x *= right; left.y *= right
    }
    
    static func /(left: Vector2d, right: Float) -> Vector2d {
        return Vector2d(x: left.x / right, y: left.y / right)
    }
}
