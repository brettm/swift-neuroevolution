//
//  ContentView.swift
//  Organisms
//
//  Created by Brett Meader on 14/01/2024.
//

import SwiftUI
import Charts

struct ContentView: View {
    @State var sim = Simulation()
    @State var timer = DisplayLink()
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Chart {
                    ForEach(sim.organisms) { organism in
                        PointMark(x: .value("", organism.position.0), y: .value("", organism.position.1))
                            .symbol {
                                VStack {
                                    Image(systemName: "triangle")
                                        .rotationEffect(
                                            Angle(radians: atan2(organism.velocity.0, organism.velocity.1))
                                        )
                                }
                                .foregroundStyle(organism.id == sim.currentBestOrganism ? .green : .blue)
                            }
                    }
                    ForEach(sim.bots) { bot in
                        PointMark(x: .value("", bot.position.0), y: .value("", bot.position.1))
                            .symbol {
                                VStack {
                                    Image(systemName: "xmark.circle")
                                        .rotationEffect(
                                            Angle(radians: atan2(bot.velocity.0, bot.velocity.1))
                                        )
                                }
                                .foregroundStyle(.red)
                            }
                    }
                    ForEach(sim.foods) { food in
                        PointMark(x: .value("", food.position.0), y: .value("", food.position.1))
                            .foregroundStyle(.green)
                    }
                }
                .chartXScale(domain: sim.horizontalScale)
                .chartYScale(domain: sim.verticalScale)
//                .onTapGesture { location in
//                    let index = getIndex(atLocation: location, gridSize: (4, 4), frameSize: proxy.size)
//                    sim.addFood(atPosition: (index.0 - 2, -1 * (index.1 - 2)))
//                }
                .task {
                    timer.stop()
                    timer.start { dt in
                        sim.tick(dt)
                    }
                }
            }
            VStack {
                Text("Current generation: \(sim.generation)")
                Text(String(format: "Elapsed: %07.2f", sim.time))
                Spacer()
                if let best = sim.currentBestOrganism {
                    HStack(alignment: .bottom) {
                        VStack {
                            Slider(value: $timer.speed, in: 1...50, label: {
                                Image(systemName: "gauge.with.dots.needle.bottom.100percent")
                            }) {
                                Image(systemName: "arrowtriangle.up")
                            } maximumValueLabel: {
                                Image(systemName: "arrowtriangle.down")
                            }
                            Spacer()
                            List {
                                ForEach(Array(sim.scores.enumerated().reversed()), id:\.offset) { idx, score in
                                    HStack(alignment: .bottom){
                                        Text("\(score.0)")
                                        Text(String(format: "%.0f", score.1))
                                        Text(String(format: "Avg. %.2f", score.2))
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .frame(maxHeight: 120.0)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .foregroundStyle(.green)
                        Spacer()
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "triangle")
                                Text("\(best)")
                                Text(String(format: "Score: %.0f", sim.currentBestScore))
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .foregroundStyle(.green)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func getIndex(atLocation location: CGPoint, gridSize: (Double, Double), frameSize: CGSize) -> (Double, Double) {
        let ratio = (location.x / frameSize.width, location.y / frameSize.height)
        return (ratio.0 * gridSize.0, ratio.1 * gridSize.1)
    }
}

#Preview {
    ContentView()
}
