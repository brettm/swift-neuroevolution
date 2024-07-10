//
//  LivingEntityModel.swift
//  Organisms
//
//  Created by Brett Meader on 16/01/2024.
//

import Foundation
import Accelerate

public struct MLPNodeShape {
    static let inputNodesCount = 8
    static let hiddenNodesCount = 8
    static let outputNodesCount = 4
}

private struct MLPWeight {
    static let inputToHiddenWeightsCount = MLPNodeShape.inputNodesCount * MLPNodeShape.hiddenNodesCount
    static let inputToHiddenBiasCount = MLPWeight.inputToHiddenWeightsCount
    static let hiddenToOutputWeightsCount = MLPNodeShape.hiddenNodesCount * MLPNodeShape.outputNodesCount
    static let hiddenToOutputBiasCount = MLPWeight.hiddenToOutputWeightsCount
}

public struct ModelWeights: Equatable {
    var inputToHiddenWeights: [Float] = []
    var inputToHiddenBias: [Float] = []
    var hiddenToOutputWeights: [Float] = []
    var hiddenToOutputBias: [Float] = []
}

public struct OrganismModel: Equatable {
    
    private var hiddenLayer: BNNSFilter?
    private var outputLayer: BNNSFilter?
    
    internal var weights: ModelWeights
    
    init(weights: ModelWeights) {
        self.weights = weights
    }
    
    internal init(
        inputToHiddenWeights: [Float] = ( 0..<MLPWeight.inputToHiddenWeightsCount ).map { _ in .random(in: -1.0...1.0) },
        inputToHiddenBias: [Float] = ( 0..<MLPWeight.inputToHiddenBiasCount ).map { _ in .random(in: -1.0...1.0) },
        hiddenToOutputWeights: [Float] = ( 0..<MLPWeight.hiddenToOutputWeightsCount ).map { _ in .random(in: -1.0...1.0) },
        hiddenToOutputBias: [Float] = ( 0..<MLPWeight.hiddenToOutputBiasCount ).map { _ in .random(in: -0.1...0.1) }) {
            self.weights = ModelWeights(
                inputToHiddenWeights: inputToHiddenWeights,
                inputToHiddenBias: inputToHiddenBias,
                hiddenToOutputWeights: hiddenToOutputWeights,
                hiddenToOutputBias: hiddenToOutputBias
            )
        }
        
    func predict(_ input: [Float]) -> [Float] {
        precondition(hiddenLayer != nil)
        precondition(outputLayer != nil)
        
        // These arrays hold the inputs and outputs to and from the layers.
        var hidden: [Float] = ( 0..<MLPNodeShape.hiddenNodesCount ).map { _ in 0 }
        var output: [Float] = ( 0..<MLPNodeShape.outputNodesCount ).map { _ in 0 }
        
        var status = BNNSFilterApply(hiddenLayer, input, &hidden)
        if status != 0 {
            print("BNNSFilterApply failed on hidden layer")
        }
        status = BNNSFilterApply(outputLayer, hidden, &output)
        if status != 0 {
            print("BNNSFilterApply failed on output layer")
        }
        return output
    }
    
    mutating func destroyNetwork() {
        BNNSFilterDestroy(hiddenLayer)
        hiddenLayer = nil
        BNNSFilterDestroy(outputLayer)
        outputLayer = nil
    }
    
    // TODO: Update to latest BNNS framework
    @discardableResult
    mutating func createNetwork() -> Bool {
        
        let hiddenActivation = BNNSActivation(function: BNNSActivationFunction.identity, alpha: 0, beta: 0)
        let outActivation = BNNSActivation(function: BNNSActivationFunction.tanh, alpha: 0, beta: 0)
        
        _ = weights.inputToHiddenWeights.withUnsafeBufferPointer { inputToHiddenWeightsBP in
            weights.inputToHiddenBias.withUnsafeBufferPointer { inputToHiddenBiasDataBP in
                weights.hiddenToOutputWeights.withUnsafeBufferPointer { hiddenToOutputWeightsBP in
                    weights.hiddenToOutputBias.withUnsafeBufferPointer { hiddenToOutputBiasBP in
                        
                        let inputToHiddenWeightsData = BNNSLayerData(
                            data: inputToHiddenWeightsBP.baseAddress!, data_type: BNNSDataType.float,
                            data_scale: 0, data_bias: 0, data_table: nil)
                        
                        let inputToHiddenBiasData = BNNSLayerData(
                            data: inputToHiddenBiasDataBP.baseAddress!, data_type: BNNSDataType.float,
                            data_scale: 0, data_bias: 0, data_table: nil)
                        
                        let hiddenToOutputWeightsData = BNNSLayerData(
                            data:hiddenToOutputWeightsBP.baseAddress!, data_type: BNNSDataType.float,
                            data_scale: 0, data_bias: 0, data_table: nil)
                        
                        let hiddenToOutputBiasData = BNNSLayerData(
                            data: hiddenToOutputBiasBP.baseAddress!, data_type: BNNSDataType.float,
                            data_scale: 0, data_bias: 0, data_table: nil)
                        
                        var inputToHiddenParams = BNNSFullyConnectedLayerParameters(
                            in_size: MLPNodeShape.inputNodesCount, out_size: MLPNodeShape.hiddenNodesCount, weights: inputToHiddenWeightsData,
                            bias: inputToHiddenBiasData, activation: hiddenActivation)
                        
                        var hiddenToOutputParams = BNNSFullyConnectedLayerParameters(
                            in_size: MLPNodeShape.hiddenNodesCount, out_size: MLPNodeShape.outputNodesCount, weights: hiddenToOutputWeightsData,
                            bias: hiddenToOutputBiasData, activation: outActivation)
                        
                        var inputDesc = BNNSVectorDescriptor(
                            size: MLPNodeShape.inputNodesCount, data_type: BNNSDataType.float, data_scale: 0, data_bias: 0)
                        
                        var hiddenDesc = BNNSVectorDescriptor(
                            size: MLPNodeShape.hiddenNodesCount, data_type: BNNSDataType.float, data_scale: 0, data_bias: 0)
                        
                        hiddenLayer = BNNSFilterCreateFullyConnectedLayer(&inputDesc, &hiddenDesc, &inputToHiddenParams, nil)
                        if hiddenLayer == nil {
                            print("BNNSFilterCreateFullyConnectedLayer failed for hidden layer")
                            return false
                        }
                        
                        var outputDesc = BNNSVectorDescriptor(
                            size: MLPNodeShape.outputNodesCount, data_type: BNNSDataType.float, data_scale: 0, data_bias: 0)
                        
                        outputLayer = BNNSFilterCreateFullyConnectedLayer(&hiddenDesc, &outputDesc, &hiddenToOutputParams, nil)
                        if outputLayer == nil {
                            print("BNNSFilterCreateFullyConnectedLayer failed for output layer")
                            return false
                        }
                        
                        return true
                    }
                }
            }
        }
        return true
    }
}
