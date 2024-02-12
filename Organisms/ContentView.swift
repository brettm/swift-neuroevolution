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
//    @State var simTimer = SimulationDisplayTimer()
    @State var simSpeed = 1.0
    var body: some View {
        ZStack {
            SimulationChart(sim: sim)
            HUD(sim: sim, speed: $simSpeed)
        }
        .task {
//            simTimer.stop()
//            simTimer.start { dt in
//                await MainActor.run {
//                    sim.tick(dt: dt)
//                }
//            }
            while(true) {
                await MainActor.run {
                    sim.tick(dt: 1/12)
                }
            }
        }
        .background(.black)
        .foregroundStyle(.white)
    }
}

struct SimulationChart: View {
    var sim: Simulation
    var body: some View {
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
//                                Text("(\(organism.velocity.0), \(organism.velocity.1))")
//                                Text(organism.id)
                                Text("\(organism.currentSpeed)")
                            }
//                            .foregroundStyle(organism == sim.currentBestOrganism ? .green : .blue)
                            .foregroundStyle(organism.energy > 0 ?
                                             (organism == sim.currentBestOrganism ? .green : .blue)
                                             : .black
                                             
                            )
                        }
                }
                ForEach(sim.bots) { bot in
                    PointMark(x: .value("", bot.position.0), y: .value("", bot.position.1))
                        .symbol {
                            VStack {
//                                Image(systemName: "arrowshape.up.circle")
                                Text("🫦")
                                    .rotationEffect(
                                        Angle(radians: atan2(bot.velocity.0, bot.velocity.1))
                                    )
                                    .scaleEffect(x: 1.0 + CGFloat(bot.energy) / 25.0, y: 1.0 + CGFloat(bot.energy) / 25.0, anchor: .center)
//                                Text("\(bot.currentSpeed)")
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
        }
    }
    
//    private func getIndex(atLocation location: CGPoint, gridSize: (Double, Double), frameSize: CGSize) -> (Double, Double) {
//        let ratio = (location.x / frameSize.width, location.y / frameSize.height)
//        return (ratio.0 * gridSize.0, ratio.1 * gridSize.1)
//    }
}

struct HUD: View {
    var sim: Simulation
    var speed: Binding<Double>
    
    var body: some View {
        VStack {
            Text("Current generation: \(sim.generation)")
            Text(String(format: "Elapsed: %07.2f", sim.time))
            Spacer()
            if let best = sim.currentBestOrganism {
                HStack(alignment: .bottom) {
                    VStack {
                        Slider(value: speed, in: 1...20, label: {
                            Text("🧭")
                        }) {
                            Image(systemName: "arrowtriangle.up")
                        } maximumValueLabel: {
                            Image(systemName: "arrowtriangle.down")
                        }
                        Spacer()
                        List {
                            ForEach(Array(sim.scores.enumerated().reversed()), id:\.offset) { idx, score in
                                HStack(alignment: .bottom){
                                    Text("Gen \(score.gen)")
                                    Text(String(format: "Best %.0f", score.bestScore ?? 0.0))
                                    Text(String(format: "Avg. %.2f", score.avgScore))
                                    Text(String(format: "Bots. %.2f", score.botsScore ?? 0.0)).foregroundStyle(.red)
                                    Text("+\(score.breedableCount)").foregroundStyle(.blue)
                                }
                            }
                            .listRowBackground(Color.clear)
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
                            Text("\(best.id)")
                            Text(String(format: "Score: %.2f", best.energy))
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

#Preview {
    ContentView()
}
