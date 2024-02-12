//
//  DisplayLink.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation
import QuartzCore

@Observable
class Timer: NSObject {
    
    private var displaylink: CADisplayLink?
    private var update: ((TimeInterval) -> Void)?
    
    var speed: Double = 1.0
    
    func start(update: @escaping (TimeInterval) -> Void) {
        self.update = update
        displaylink = CADisplayLink(target: self, selector: #selector(frame))
        displaylink?.add(to: .current, forMode: .common)
    }
    
    func stop() {
        displaylink?.remove(from: .current, forMode: .default)
        update = nil
    }
    
    @objc func frame(displaylink: CADisplayLink) {
        let frameDuration = (displaylink.targetTimestamp - displaylink.timestamp) * speed
        update?(frameDuration)
    }
}
