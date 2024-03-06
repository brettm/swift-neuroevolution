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
    var position: Vector2d { get set }
    var velocity: Vector2d { get set }
}

public extension Entity {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    var rotation: Float { atan2(velocity.x, velocity.y) }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

public struct Food: Entity {
    public var id: String
    public var energy: Float = 1.0
    public var position: Vector2d = Vector2d()
    public var velocity: Vector2d = Vector2d()
}

enum EntityFactory {
    static func makeOrganisms(count: Int, scale: Float = 1) -> [Organism] {
        return (0..<count).map { idx in
            let model = OrganismModel()
            var org = Organism(id: "thinking_organism_\(idx)", model: model ,position: Vector2d.random(scale: scale))
            _ = org.model.createNetwork()
            return org
        }
    }
    static func makeBots(count: Int, scale: Float = 1) -> [Bot] {
        return (0..<count).map {idx in
            Bot(id: "organism_\(idx)", position: Vector2d.random(scale: scale))
        }
    }
    static func makeFoods(count: Int, scale: Float = 1) -> [Food] {
        return (0..<count).map{ _ in
            Food(id: "\(UUID())", position: Vector2d.random(scale: scale))
        }
    }
}
