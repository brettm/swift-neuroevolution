//
//  Extensions.swift
//  Organisms
//
//  Created by Brett Meader on 24/01/2024.
//

import Foundation

extension Array where Element == Organism {
    func filterByRange(horizontal: ClosedRange<Double>, vertical: ClosedRange<Double>) -> [Organism] {
        return self.filter{ $0.isInRange(horizontal: horizontal, vertical: vertical) }
    }
}

extension Organism {
    func isInRange(horizontal: ClosedRange<Double>, vertical: ClosedRange<Double>) -> Bool {
        if
            self.position.0 > horizontal.lowerBound && self.position.0 < horizontal.upperBound,
            self.position.1 > vertical.lowerBound && self.position.1 < vertical.upperBound {
            return true
        }
        return false
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

