//
//  Math.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation

func distance(p1: (Double, Double), p2: (Double, Double)) -> Double {
    let vector = vector(p1: p1, p2: p2)
    return sqrt(pow(vector.0, 2) + pow(vector.1, 2))
}

func vector(p1: (Double, Double), p2: (Double, Double)) -> (Double, Double) {
    return (p2.0 - p1.0, p2.1 - p1.1)
}

func magnitude(_ v: (Double, Double)) -> Double {
    return sqrt(pow(v.0, 2) + pow(v.1, 2))
}

func normalise(_ v: (Double, Double)) -> (Double, Double) {
    let mag = magnitude(v)
    return (v.0 / mag, v.1 / mag)
}
