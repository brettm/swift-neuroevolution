//
//  Extensions.swift
//  Organisms
//
//  Created by Brett Meader on 24/01/2024.
//

import Foundation

extension Array where Element == Vector2d {
    func filterByDistance(_ radius: Float, relativeTo relativePosition: Vector2d = Vector2d()) -> [Element] {
        return self.filter { $0.isInRange(radius: radius, relativeTo: relativePosition) }
    }
}

extension Array where Element: Entity {
    func filterByDistance(_ radius: Float, relativeTo relativePosition: Vector2d = Vector2d()) -> [Element]  {
        return self.filter { $0.position.isInRange(radius: radius, relativeTo: relativePosition) }
    }
}

extension Vector2d {
    func isInRange(radius: Float, relativeTo relativePosition: Vector2d = Vector2d()) -> Bool {
        return self.distance(from: relativePosition) <= radius
    }
}

extension Entity {
    func isInRange(radius: Float, relativeTo position: Vector2d = Vector2d()) -> Bool {
        return self.position.isInRange(radius: radius, relativeTo: position)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

