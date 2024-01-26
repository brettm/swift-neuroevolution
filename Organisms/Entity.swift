//
//  Entity.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

protocol Entity: Identifiable, Equatable {
    var id: String { get set }
    var energy: Float { get set }
    var position: (Double, Double) { get set }
}


struct Food: Entity {
    static func == (lhs: Food, rhs: Food) -> Bool {
        lhs.id == rhs.id
    }
    var id: String
    var energy: Float = 1.0
    var position = (0.0, 0.0)
}

struct Origin: Entity {
    static func == (lhs: Origin, rhs: Origin) -> Bool {
        lhs.id == rhs.id
    }
    var id: String = "origin"
    var energy: Float = 0.0
    var position = (0.0, 0.0)
}

