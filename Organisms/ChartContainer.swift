//
//  GameView.swift
//  Organisms
//
//  Created by Brett Meader on 27/02/2024.
//

import SwiftUI
import Charts

struct ChartContainer: View {
    @Environment(SimulatorViewModel.self) var viewModel: SimulatorViewModel
    let hPadding: Float = 0.5
    let vPadding: Float = 1
    var body: some View {
        GeometryReader { proxy in
            Chart {
                ForEach(viewModel.foods) { food in
                    PointMark(x: .value("", food.position.x), y: .value("", food.position.y))
                        .symbol {
                            VStack {
                                Image(systemName: "circle.fill")
                                    .scaleEffect(CGSizeMake(Double((food.position.z + 2.5) * 0.15),Double((food.position.z + 2.5) * 0.15)))
                            }
                            .foregroundStyle(.green)
                        }
                }
                ForEach(viewModel.organisms) { organism in
                    PointMark(x: .value("", organism.position.x), y: .value("", organism.position.y))
                        .symbol {
                            VStack {
                                Image(systemName: "triangle.fill")
                                    .rotationEffect( Angle(radians: Double(organism.rotation)) )
                                    .scaleEffect(CGSizeMake(Double((organism.position.z + 2.5) * 0.25),Double((organism.position.z + 2.5) * 0.25)))
                            }
                            .foregroundStyle(organism == viewModel.sim.currentBestOrganism ? .green : .blue)
                        }
                }
                ForEach(viewModel.bots) { bot in
                    PointMark(x: .value("", bot.position.x), y: .value("", bot.position.y))
                        .symbol {
                            VStack {
                                Image(systemName: "poweroutlet.type.h.fill")
                                    .rotationEffect( Angle(radians: Double(bot.rotation)) )
                                    .scaleEffect(CGSizeMake(Double((bot.position.z + 2.5) * 0.4),Double((bot.position.z + 2.5) * 0.4)))
                            }
                            .foregroundStyle(.red)
                        }
                }
            }
            .chartXScale(domain: -viewModel.sim.scale-hPadding...viewModel.sim.scale+hPadding)
            .chartYScale(domain: -viewModel.sim.scale-vPadding...viewModel.sim.scale+(vPadding*0.5))
        }
    }
}
