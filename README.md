# NEUROEV-SIM: Swift Neuroevolution Simulation

A real-time neuroevolution simulation built in SwiftUI and Swift Charts. Watch organisms evolve neural networks to survive in a dynamic environment with food sources and predator bots.

<img width="791" height="745" alt="Screenshot 2025-11-11 at 10 03 47" src="https://github.com/user-attachments/assets/07641390-c796-4fb2-bd5b-c09a76e9f41d" />

## Features

- **Real-time Neuroevolution**: Organisms evolve multilayer perceptrons (MLP) through natural selection
- **3D Physics Simulation**: Smooth movement with configurable friction and collision dynamics
- **Visualisation**: Real-time rendering of organisms, food, and bots with energy-based colouring
- **Configurable Evolution**: Tunable parameters for mutation, selection, and environmental factors
- **TODO: Speciation Support**: Framework for maintaining behavioral diversity (experimental)

## Core Architecture

### Neural Network
```swift
MLP Structure: 8 → 32 → 4
- Inputs: Food direction/distance + Threat direction/distance (8 total)
- Hidden: 32 neurons with tanh activation
- Outputs: 3D acceleration vector + throttle control
```

### Evolution Algorithm
- **Tournament Selection**: Top-performing organisms breed
- **Crossover**: Weight blending between parents
- **Mutation**: Configurable rate and intensity
- **Elitism**: Best performers survive between generations

## Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxOrganisms` | 50 | Population size |
| `mutationRate` | 0.6 | Weight mutation intensity |
| `friction` | 0.6 | Movement physics (lower = more momentum) |
| `visibility` | 4.5 | How far organisms can see |
| `evolutionTime` | 60s | Time between generations |

## Project Structure

```
Organisms/
├── Simulation.swift          # Core simulation engine
├── Organism.swift            # Organism entity with neural network
├── OrganismModel.swift       # MLP implementation using Accelerate
├── Bot.swift                 # Predator entities
├── Species.swift             # TODO: Speciation management
└── EntityFactory.swift       # Entity creation utilities
```

## Getting Started

1. **Clone the repository**
2. **Open in Xcode** (requires iOS 14+ / macOS 11+)
3. **Run the simulation - OrganismSim (fast simulation), Organism (visual simualtion with Swift Charts)** - no dependencies required
4. **Adjust parameters** in `Simulation.init()` for different behaviors

## Key Discoveries

Through experimentation, we found:

- **Low friction (0.5-0.6)** enables efficient "coasting" strategies
- **Moderate mutation rates** work best for complex environments
- **32 hidden nodes** provide optimal capacity for threat/food trade-offs
- **Proper input normalisation** is crucial for learning
- **Single-species convergence** often indicates a globally optimal strategy

## Performance

- **Hardware Accelerated**: Uses Apple's Accelerate framework for neural network computations
- **Concurrent Updates**: Async/await for parallel organism updates
- **Memory Efficient**: Value types and careful resource management

## Customisation

### Adding New Behaviors
```swift
// Extend Organism inputs for new sensory data
mutating func think(dt: Float) {
    var inputs: [Float] = []
    // Add custom sensor data here
    let outputs = model.predict(inputs)
    // Implement new behaviors based on outputs
}
```

### Environmental Modifications
```swift
// Modify Simulation.init() for different setups
init(
    maxOrganisms: Int = 50,
    maxBots: Int = 3,
    maxFood: Int = 100,
    scale: Float = 2.0
) {
    // Customize environment parameters
}
```

## Research Applications

This simulation is ideal for studying:
- Neuroevolution algorithms
- Emergent behaviors in multi-agent systems
- Evolutionary robotics principles
- Adaptive decision-making in dynamic environments

## License

MIT License - feel free to use for research and educational purposes.

---

**Built with Swift · No Dependencies · Real-time Evolution**
