//
//  Extensions.swift
//  Organisms
//
//  Created by Brett Meader on 24/01/2024.
//

import Foundation

extension SIMD3 where Scalar == Float {
    static func random(scale: Float) -> SIMD3 {
        return Self(x: .random(in: -scale...scale), y: .random(in: -scale...scale), z: .random(in: -scale...scale))
    }
    func distance(from vector: SIMD3) -> Float {
        let directionVector = vector - self
        return directionVector.magnitude()
    }
    func vector(from p2: SIMD3) -> SIMD3 {
        let p1 = self
        return SIMD3(x: p2.x - p1.x, y: p2.y - p1.y, z: p2.z - p1.z)
    }
    func magnitude() -> Float {
        return sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2))
    }
    func normalise() -> SIMD3 {
        let m = magnitude()
        return SIMD3(x: x/m, y: y/m, z: z/m)
    }
}

extension Array where Element == SIMD3<Float> {
    func filterByDistance(_ radius: Float, relativeTo relativePosition: SIMD3<Float> = .init()) -> [Element] {
        return self.filter { $0.isInRange(radius: radius, relativeTo: relativePosition) }
    }
}

extension Array where Element: Entity {
    func filterByDistance(_ radius: Float, relativeTo relativePosition: SIMD3<Float> = .init()) -> [Element]  {
        return self.filter { $0.position.isInRange(radius: radius, relativeTo: relativePosition) }
    }
}

extension SIMD3<Float> {
    func isInRange(radius: Float, relativeTo relativePosition: SIMD3<Float> = .init()) -> Bool {
        return self.distance(from: relativePosition) <= radius
    }
}

extension Entity {
    func isInRange(radius: Float, relativeTo position: SIMD3<Float> = .init()) -> Bool {
        return self.position.isInRange(radius: radius, relativeTo: position)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

