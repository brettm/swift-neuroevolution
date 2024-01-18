//
//  LivingEntityModel.swift
//  Organisms
//
//  Created by Brett Meader on 16/01/2024.
//

import Foundation
import Accelerate

private struct MLPNode {
    static let inputNodesCount = 3
    static let hiddenNodesCount = 3
    static let outputNodesCount = 2
}

private struct MLPWeight {
    static let inputToHiddenWeightsCount = MLPNode.inputNodesCount * MLPNode.hiddenNodesCount
    static let inputToHiddenBiasCount = MLPWeight.inputToHiddenWeightsCount
    static let hiddenToOutputWeightsCount = MLPNode.hiddenNodesCount * MLPNode.outputNodesCount
    static let hiddenToOutputBiasCount = MLPWeight.hiddenToOutputWeightsCount
}

struct OrganismModel {
    
    private var hiddenLayer: BNNSFilter?
    private var outputLayer: BNNSFilter?
    
    var inputToHiddenWeights: [Float] = []
    var inputToHiddenBias: [Float] = []
    var hiddenToOutputWeights: [Float] = []
    var hiddenToOutputBias: [Float] = []
    
    internal init(
        inputToHiddenWeights: [Float] = ( 0..<MLPWeight.inputToHiddenWeightsCount ).map { _ in .random(in: -1.0...1.0) },
        inputToHiddenBias: [Float] = ( 0..<MLPWeight.inputToHiddenBiasCount ).map { _ in 0 },
        hiddenToOutputWeights: [Float] = ( 0..<MLPWeight.hiddenToOutputWeightsCount ).map { _ in .random(in: -1.0...1.0) },
        hiddenToOutputBias: [Float] = ( 0..<MLPWeight.hiddenToOutputBiasCount ).map { _ in 0 }) {
            self.inputToHiddenWeights = inputToHiddenWeights
            self.inputToHiddenBias = inputToHiddenBias
            self.hiddenToOutputWeights = hiddenToOutputWeights
            self.hiddenToOutputBias = hiddenToOutputBias
        }
        
    func predict(_ input: [Float]) -> [Float] {
        precondition(hiddenLayer != nil)
        precondition(outputLayer != nil)
        
        // These arrays hold the inputs and outputs to and from the layers.
        var hidden: [Float] = ( 0..<MLPNode.hiddenNodesCount ).map { _ in 0 }
        var output: [Float] = ( 0..<MLPNode.outputNodesCount ).map { _ in 0 }
        
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
    mutating func createNetwork() -> Bool {
        let activation = BNNSActivation(function: BNNSActivationFunction.tanh, alpha: 0, beta: 0)
        
        _ = inputToHiddenWeights.withUnsafeBufferPointer { inputToHiddenWeightsBP in
            inputToHiddenBias.withUnsafeBufferPointer { inputToHiddenBiasDataBP in
                hiddenToOutputWeights.withUnsafeBufferPointer { hiddenToOutputWeightsBP in
                    hiddenToOutputBias.withUnsafeBufferPointer { hiddenToOutputBiasBP in
                        
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
                            in_size: MLPNode.inputNodesCount, out_size: MLPNode.hiddenNodesCount, weights: inputToHiddenWeightsData,
                            bias: inputToHiddenBiasData, activation: activation)
                        
                        var hiddenToOutputParams = BNNSFullyConnectedLayerParameters(
                            in_size: MLPNode.hiddenNodesCount, out_size: MLPNode.outputNodesCount, weights: hiddenToOutputWeightsData,
                            bias: hiddenToOutputBiasData, activation: activation)
                        
                        var inputDesc = BNNSVectorDescriptor(
                            size: MLPNode.inputNodesCount, data_type: BNNSDataType.float, data_scale: 0, data_bias: 0)
                        
                        var hiddenDesc = BNNSVectorDescriptor(
                            size: MLPNode.inputNodesCount, data_type: BNNSDataType.float, data_scale: 0, data_bias: 0)
                        
                        hiddenLayer = BNNSFilterCreateFullyConnectedLayer(&inputDesc, &hiddenDesc, &inputToHiddenParams, nil)
                        if hiddenLayer == nil {
                            print("BNNSFilterCreateFullyConnectedLayer failed for hidden layer")
                            return false
                        }
                        
                        var outputDesc = BNNSVectorDescriptor(
                            size: MLPNode.outputNodesCount, data_type: BNNSDataType.float, data_scale: 0, data_bias: 0)
                        
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
