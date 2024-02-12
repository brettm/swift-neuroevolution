//
//  DisplayLink.swift
//  Organisms
//
//  Created by Brett Meader on 15/01/2024.
//

import Foundation
import QuartzCore
import Combine

@Observable
class SimulationDisplayTimer: NSObject {
    
    private var displaylink: CADisplayLink?
    private var update: ((TimeInterval) -> Void)?
    
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
        let frameDuration = (displaylink.targetTimestamp - displaylink.timestamp)
        update?(frameDuration)
    }
}
