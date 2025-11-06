//
//  Entity.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

public protocol Entity: Identifiable, Hashable {
    var id: String { get set }
    var energy: Float { get set }
    var position: SIMD3<Float> { get set }
    var velocity: SIMD3<Float> { get set }
    func inVisibleRange<T: Entity>(of entity: T) -> Bool
}

public extension Entity {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    var rotation: Float { atan2(velocity.x, velocity.y) }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    func inVisibleRange<T: Entity>(of entity: T) -> Bool {
        return false
    }
}

import simd

public struct Food: Entity {
    public func inVisibleRange<T>(of entity: T) -> Bool where T : Entity {
        let x = entity.position
        let dir = entity.velocity.normalise()
        let (h, r) = (Float(2.0), Float(2.0))
        let eDir = self.position - x
        // project p onto dir to find the point's distance along the axis
        let cDistance = dot(eDir, dir)
        if cDistance < 0 || cDistance > h { return false }
        // calculate the cone radius at that point along the axis
        let cRadius = (cDistance / h) * r
        let oDistance = length(eDir - cDistance * dir)
        return oDistance < cRadius
    }
    
    public var id: String
    public var energy: Float = 1.0
    public var position = SIMD3<Float>()
    public var velocity = SIMD3<Float>()
}

enum EntityFactory {
    static func makeOrganisms(count: Int, scale: Float = 1, weights: ModelWeights? = nil) -> [Organism] {
        return (0..<count).map { idx in
            let model = weights == nil ? OrganismModel() : OrganismModel(initialWeights: weights)
            var org = Organism(id: "thinking_organism_\(idx)", model: model, position: SIMD3.random(scale: scale))
            return org
        }
    }
    static func makeBots(count: Int, scale: Float = 1) -> [Bot] {
        return (0..<count).map {idx in
            Bot(id: "organism_\(idx)", position: SIMD3.random(scale: scale))
        }
    }
    static func makeFoods(count: Int, scale: Float = 1) -> [Food] {
        return (0..<count).map{ _ in
            Food(id: "\(UUID())", position: SIMD3.random(scale: scale))
        }
    }
}
