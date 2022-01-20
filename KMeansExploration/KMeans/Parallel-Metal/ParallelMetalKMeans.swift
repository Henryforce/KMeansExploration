//
//  ParallelMetalKMeans.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 15/1/22.
//

import Foundation
import Metal

/// - SeeAlso
/// https://eugenebokhan.io/introduction-to-metal-compute-part-three
/// https://kieber-emmons.medium.com/optimizing-parallel-reduction-in-metal-for-apple-m1-8e8677b49b01
final class ParallelMetalKMeans: KMeans {
    
    private let seed: Int
    private let maxIteration: Int
    private let threshold: Double
    private let device: MTLDevice
//    private let computePipelineState: MTLComputePipelineState
    private let findLabelPipelineState: MTLComputePipelineState
    private let updateCenterPipelineState: MTLComputePipelineState
    private let commandQueue: MTLCommandQueue
    
    private var _labels = [Int]()
    
    /// Label for each element passed on the last call to compute()
    var labels: [Int] { _labels }
    
    init(seed: Int = 1, maxIteration: Int = 50, threshold: Double = 0.00001) {
        self.seed = seed
        self.maxIteration = maxIteration
        self.threshold = threshold
        
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Metal device is not available.") }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else { fatalError("Failed creating Metal command queue.") }
        self.commandQueue = commandQueue
        
        guard let library = device.makeDefaultLibrary() else { fatalError("Failed creating Metal library.") }
//        guard let findLabelOldFunction = library.makeFunction(name: "findLabelOld") else { fatalError("Failed creating Metal FindLabelOld function.") }
        
        guard let findLabelFunction = library.makeFunction(name: "findLabel") else { fatalError("Failed creating Metal FindLabel function.") }
        guard let updateCenterFunction = library.makeFunction(name: "updateCenters") else { fatalError("Failed creating Metal UpdateCenter function.") }
        
        do {
//            computePipelineState = try device.makeComputePipelineState(function: findLabelOldFunction)
            findLabelPipelineState = try device.makeComputePipelineState(function: findLabelFunction)
            updateCenterPipelineState = try device.makeComputePipelineState(function: updateCenterFunction)
        } catch {
            fatalError("Failed preparing compute pipeline.")
        }
    }
    
    func compute(kPointCollection: KPointCollection, clusterCount: Int) async throws {
        let start = Date().timeIntervalSince1970
//        print("Started at \()")
        
        let maxCount = kPointCollection.count
//        let maxClusters = 2
        let maxDimensions = kPointCollection.dimensions
        
//        var data = ContiguousArray<Float>(repeating: 0.0, count: maxCount * maxDimensions)
//        for index in 0..<maxCount {
//            let value = Float(index)
//            for dimension in 0..<maxDimensions {
//                data[index * maxDimensions + dimension] = value
//            }
//        }
        let data = kPointCollection.contiguousFloatArray
        let centersData = randomCenters(from: kPointCollection, clusterCount: clusterCount)
            .contiguousFloatArray
        
//        var centersData = ContiguousArray<Float>(repeating: 0.0, count: maxClusters * maxDimensions)
//        centersData[0] = 0
//        centersData[1] = 0
//        centersData[2] = 2
//        centersData[3] = 2
        
        let labels = ContiguousArray<UInt32>(repeating: 0, count: kPointCollection.count)
        
        guard let inputBuffer = data.makeBuffer(for: device) else { return }
        guard let labelBuffer = labels.makeBuffer(for: device) else { return }
        guard let centersBuffer = centersData.makeBuffer(for: device) else { return }
        guard let clustersCountBuffer = UInt32(clusterCount).makeBuffer(for: device) else { return }
        guard let dataCountBuffer = UInt32(maxCount).makeBuffer(for: device) else { return }
        guard let dimensionsBuffer = UInt32(maxDimensions).makeBuffer(for: device) else { return }
        guard let maxValueBuffer = Float.greatestFiniteMagnitude.makeBuffer(for: device) else { return }
        guard let thresholdBuffer = Float(0.01).makeBuffer(for: device) else { return }
        
        var iteration = 0
        while iteration < 50 {
            guard let didChangeBuffer = UInt32.zero.makeBuffer(for: device) else { return }
            
            try runFindLabel(
                inputBuffer: inputBuffer,
                labelBuffer: labelBuffer,
                centersBuffer: centersBuffer,
                clustersCountBuffer: clustersCountBuffer,
                dataCountBuffer: dataCountBuffer,
                dimensionsBuffer: dimensionsBuffer,
                maxValueBuffer: maxValueBuffer,
                maxCount: maxCount
            )
            
            try runUpdateCenter(
                inputBuffer: inputBuffer,
                labelBuffer: labelBuffer,
                centersBuffer: centersBuffer,
                clustersCountBuffer: clustersCountBuffer,
                dataCountBuffer: dataCountBuffer,
                dimensionsBuffer: dimensionsBuffer,
                thresholdBuffer: thresholdBuffer,
                didChangeBuffer: didChangeBuffer,
                maxDimensions: maxDimensions
            )
            
            iteration += 1
            
            let didChangePointer = didChangeBuffer.contents().assumingMemoryBound(to: UInt32.self)
            let didChangeBufferPointer = UnsafeBufferPointer<UInt32>(
                start: didChangePointer,
                count: 1
            )
            let didChangeResult = ContiguousArray<UInt32>(didChangeBufferPointer)
            
            if let didChange = didChangeResult.first,
                didChange == .zero {
                break
            }
        }
        
//        let centersPointer = centersBuffer.contents().assumingMemoryBound(to: Float.self)
//        let centersBufferPointer = UnsafeBufferPointer<Float>(
//            start: centersPointer,
//            count: clusterCount * maxDimensions
//        )
//        let centersResult = ContiguousArray<Float>(centersBufferPointer)
//        print(centersResult)
        
        let labelPointer = labelBuffer.contents().assumingMemoryBound(to: UInt32.self)
        let labelBufferPointer = UnsafeBufferPointer<UInt32>(start: labelPointer, count: maxCount)
        let labelResult = ContiguousArray<UInt32>(labelBufferPointer)
//        print(labelResult)
        
        print(iteration)
        
        _labels = labelResult.map { Int($0) }
        
        let finish = Date().timeIntervalSince1970
        print("Finished at \(finish.distance(to: start))")
    }
    
    func runFindLabel(
        inputBuffer: MTLBuffer,
        labelBuffer: MTLBuffer,
        centersBuffer: MTLBuffer,
        clustersCountBuffer: MTLBuffer,
        dataCountBuffer: MTLBuffer,
        dimensionsBuffer: MTLBuffer,
        maxValueBuffer: MTLBuffer,
        maxCount: Int
    ) throws {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        else { throw KMeansError.gpuError }
        
        commandEncoder.setComputePipelineState(findLabelPipelineState)
        commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(labelBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(centersBuffer, offset: 0, index: 2)
        commandEncoder.setBuffer(clustersCountBuffer, offset: 0, index: 3)
        commandEncoder.setBuffer(dataCountBuffer, offset: 0, index: 4)
        commandEncoder.setBuffer(dimensionsBuffer, offset: 0, index: 5)
        commandEncoder.setBuffer(maxValueBuffer, offset: 0, index: 6)
        
        let gridSize = MTLSize(width: maxCount, height: 1, depth: 1)
        let threadGroupWidth = findLabelPipelineState.threadExecutionWidth // 32
//        let threadGroupHeight = computePipelineState.maxTotalThreadsPerThreadgroup / threadGroupWidth // 32
        
        let threadGroupSize = MTLSize(width: threadGroupWidth, height: 1, depth: 1)
        let threadGroupCount = MTLSize(
            width: (gridSize.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: 1,
            depth: 1
        )
        commandEncoder.dispatchThreadgroups(
            threadGroupCount,
            threadsPerThreadgroup: threadGroupSize
        )
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
                
    func runUpdateCenter(
        inputBuffer: MTLBuffer,
        labelBuffer: MTLBuffer,
        centersBuffer: MTLBuffer,
        clustersCountBuffer: MTLBuffer,
        dataCountBuffer: MTLBuffer,
        dimensionsBuffer: MTLBuffer,
        thresholdBuffer: MTLBuffer,
        didChangeBuffer: MTLBuffer,
        maxDimensions: Int
    ) throws {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        else { throw KMeansError.gpuError }

        let threadGroupWidth = updateCenterPipelineState.threadExecutionWidth // 32
        
        commandEncoder.setComputePipelineState(updateCenterPipelineState)
        commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(labelBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(centersBuffer, offset: 0, index: 2)
        commandEncoder.setBuffer(clustersCountBuffer, offset: 0, index: 3)
        commandEncoder.setBuffer(dataCountBuffer, offset: 0, index: 4)
        commandEncoder.setBuffer(dimensionsBuffer, offset: 0, index: 5)
        commandEncoder.setBuffer(thresholdBuffer, offset: 0, index: 6)
        commandEncoder.setBuffer(didChangeBuffer, offset: 0, index: 7)
        
        let threadGroupSize = MTLSize(width: threadGroupWidth, height: 1, depth: 1)
        let threadGroupCount = MTLSize(width: maxDimensions, height: 1, depth: 1)
        
        commandEncoder.dispatchThreadgroups(
            threadGroupCount,
            threadsPerThreadgroup: threadGroupSize
        )
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    // TODO: make use of the seed parameter
    private func randomCenters(
        from kPointCollection: KPointCollection,
        clusterCount: Int
    ) -> [KPoint] {
        return Array(repeating: 0, count: clusterCount) // set 0 as the base index
            .map { Int.random(in: $0..<kPointCollection.count) } // Select a random index
            .map { kPointCollection.point(at: $0) } // Use the random index to select an element
    }
}

extension ParallelMetalKMeans {
//    func process(data: ContiguousArray<Float>) -> ContiguousArray<Float> {
////        let dataBuffer = data.withUnsafeBytes { (bufferPointer) -> MTLBuffer? in
////            guard let baseAddress = bufferPointer.baseAddress else { return nil }
////            return device.makeBuffer(
////                bytes: baseAddress,
////                length: bufferPointer.count,
////                options: .storageModeShared
////            )
////        }
////        guard let inputBuffer = dataBuffer else { return [] }
//        guard let inputBuffer = data.makeBuffer(for: device) else { return [] }
//
//        guard let outputBuffer = device.makeBuffer(
//            length: inputBuffer.length,
//            options: .storageModeShared
//        ) else { return [] }
//
//        guard let counterBuffer = UInt.zero.makeBuffer(for: device) else { return [] }
//        guard let lengthBuffer = Int(data.count).makeBuffer(for: device) else { return [] }
//
//        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return [] }
//        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return [] }
//
//        commandEncoder.setComputePipelineState(computePipelineState)
//        commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
//        commandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
//        commandEncoder.setBuffer(counterBuffer, offset: 0, index: 2)
//        commandEncoder.setBuffer(lengthBuffer, offset: 0, index: 3)
//
////        let threadsPerThreadgroup = MTLSize(width: 10, height: 1, depth: 1)
////        let threadgroupsPerGrid = MTLSize(
////            width: data.count / threadsPerThreadgroup.width,
////            height: threadsPerThreadgroup.height,
////            depth: threadsPerThreadgroup.depth
////        )
////        commandEncoder.dispatchThreadgroups(
////            threadgroupsPerGrid,
////            threadsPerThreadgroup: threadsPerThreadgroup
////        )
//
//        let gridSize = MTLSize(width: 10, height: 1, depth: 1)
//        let threadGroupWidth = computePipelineState.threadExecutionWidth // 32
////        let threadGroupHeight = computePipelineState.maxTotalThreadsPerThreadgroup / threadGroupWidth // 32
//
//        let threadGroupSize = MTLSize(width: threadGroupWidth,
////                                      height: threadGroupHeight,
//                                      height: 1,
//                                      depth: 1)
//        let threadGroupCount = MTLSize(
//            width: (gridSize.width + threadGroupSize.width - 1) / threadGroupSize.width,
////            height: (gridSize.height + threadGroupSize.height - 1) / threadGroupSize.height,
//            height: 1,
//            depth: 1
//        )
//        commandEncoder.dispatchThreadgroups(
//            threadGroupCount,
//            threadsPerThreadgroup: threadGroupSize
//        )
//
//        commandEncoder.endEncoding()
//        commandBuffer.commit()
//        commandBuffer.waitUntilCompleted()
//
//        let outputPointer = outputBuffer
//            .contents()
//            .assumingMemoryBound(to: Float.self)
//        let outputDataBufferPointer = UnsafeBufferPointer<Float>(
//            start: outputPointer,
//            count: data.count
//        )
//
//        let resultBuffer = lengthBuffer
//            .contents()
//            .assumingMemoryBound(to: Int.self)
//        let resultBufferPointer = UnsafeBufferPointer<Int>(
//            start: resultBuffer,
//            count: 1
//        )
//        let resultFinal = ContiguousArray<Int>(resultBufferPointer)
//
//        return ContiguousArray<Float>(outputDataBufferPointer)
//    }
    
    func findLabel() {
        let maxCount = 32
        let maxClusters = 2
        let maxDimensions = 2
        
        var data = ContiguousArray<Float>(repeating: 0.0, count: maxCount * maxDimensions)
        for index in 0..<maxCount {
            let value = Float(index)
            for dimension in 0..<maxDimensions {
                data[index * maxDimensions + dimension] = value
            }
        }
        var centersData = ContiguousArray<Float>(repeating: 0.0, count: maxClusters * maxDimensions)
        centersData[0] = 1
        centersData[1] = 1
        centersData[2] = 15
        centersData[3] = 15
        let labels = ContiguousArray<UInt32>(repeating: 0, count: maxCount)
        
        guard let inputBuffer = data.makeBuffer(for: device) else { return }
        guard let labelBuffer = labels.makeBuffer(for: device) else { return }
        guard let centersBuffer = centersData.makeBuffer(for: device) else { return }
        guard let clustersCountBuffer = UInt32(maxClusters).makeBuffer(for: device) else { return }
        guard let dataCountBuffer = UInt32(maxCount).makeBuffer(for: device) else { return }
        guard let dimensionsBuffer = UInt32(maxDimensions).makeBuffer(for: device) else { return }
        guard let maxValueBuffer = Float.greatestFiniteMagnitude.makeBuffer(for: device) else { return }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        commandEncoder.setComputePipelineState(findLabelPipelineState)
        commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(labelBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(centersBuffer, offset: 0, index: 2)
        commandEncoder.setBuffer(clustersCountBuffer, offset: 0, index: 3)
        commandEncoder.setBuffer(dataCountBuffer, offset: 0, index: 4)
        commandEncoder.setBuffer(dimensionsBuffer, offset: 0, index: 5)
        commandEncoder.setBuffer(maxValueBuffer, offset: 0, index: 6)
        
        let gridSize = MTLSize(width: maxCount, height: 1, depth: 1)
        let threadGroupWidth = findLabelPipelineState.threadExecutionWidth // 32
//        let threadGroupHeight = computePipelineState.maxTotalThreadsPerThreadgroup / threadGroupWidth // 32
        
        let threadGroupSize = MTLSize(width: threadGroupWidth,
//                                      height: threadGroupHeight,
                                      height: 1,
                                      depth: 1)
        let threadGroupCount = MTLSize(
            width: (gridSize.width + threadGroupSize.width - 1) / threadGroupSize.width,
//            height: (gridSize.height + threadGroupSize.height - 1) / threadGroupSize.height,
            height: 1,
            depth: 1
        )
        commandEncoder.dispatchThreadgroups(
            threadGroupCount,
            threadsPerThreadgroup: threadGroupSize
        )
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let labelPointer = labelBuffer.contents().assumingMemoryBound(to: UInt32.self)
        let labelBufferPointer = UnsafeBufferPointer<UInt32>(start: labelPointer, count: maxCount)
        let labelResult = ContiguousArray<UInt32>(labelBufferPointer)
        print(labelResult)
        
//        let resultBuffer = dataCountBuffer.contents().assumingMemoryBound(to: Int.self)
//        let resultBufferPointer = UnsafeBufferPointer<Int>(start: resultBuffer, count: 1)
//        let resultFinal = ContiguousArray<Int>(resultBufferPointer)
        
        print("Finished")
    }
    
    func updateCenters() {
        let maxCount = 90
        let maxClusters = 3
        let maxDimensions = 2
        
        var data = ContiguousArray<Float>(repeating: 0.0, count: maxCount * maxDimensions)
        for index in 0..<maxCount {
            let value = Float(index)
            for dimension in 0..<maxDimensions {
                data[index * maxDimensions + dimension] = value
            }
        }
        var centersData = ContiguousArray<Float>(repeating: 0.0, count: maxClusters * maxDimensions)
        centersData[0] = 0
        centersData[1] = 0
        centersData[2] = 2
        centersData[3] = 2
        centersData[4] = 0
        centersData[5] = 0
        var labels = ContiguousArray<UInt32>(repeating: 0, count: maxCount)
        for index in 0..<maxCount {
            labels[index] = index < maxCount/2 ? 0 : 1
        }
        
        guard let inputBuffer = data.makeBuffer(for: device) else { return }
        guard let labelBuffer = labels.makeBuffer(for: device) else { return }
        guard let centersBuffer = centersData.makeBuffer(for: device) else { return }
        guard let clustersCountBuffer = UInt32(maxClusters).makeBuffer(for: device) else { return }
        guard let dataCountBuffer = UInt32(maxCount).makeBuffer(for: device) else { return }
        guard let dimensionsBuffer = UInt32(maxDimensions).makeBuffer(for: device) else { return }
        guard let thresholdBuffer = Float(0.0001).makeBuffer(for: device) else { return }
        guard let didChangeBuffer = UInt32.zero.makeBuffer(for: device) else { return }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        commandEncoder.setComputePipelineState(updateCenterPipelineState)
        commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(labelBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(centersBuffer, offset: 0, index: 2)
        commandEncoder.setBuffer(clustersCountBuffer, offset: 0, index: 3)
        commandEncoder.setBuffer(dataCountBuffer, offset: 0, index: 4)
        commandEncoder.setBuffer(dimensionsBuffer, offset: 0, index: 5)
        commandEncoder.setBuffer(thresholdBuffer, offset: 0, index: 6)
        commandEncoder.setBuffer(didChangeBuffer, offset: 0, index: 7)
        
        let threadGroupWidth = findLabelPipelineState.threadExecutionWidth // 32
        let threadGroupSize = MTLSize(width: threadGroupWidth, height: 1, depth: 1)
        let threadGroupCount = MTLSize(width: maxDimensions, height: 1, depth: 1)
        
        commandEncoder.dispatchThreadgroups(
            threadGroupCount,
            threadsPerThreadgroup: threadGroupSize
        )
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let centersPointer = centersBuffer.contents().assumingMemoryBound(to: Float.self)
        let centersBufferPointer = UnsafeBufferPointer<Float>(
            start: centersPointer,
            count: maxClusters * maxDimensions
        )
        let centersResult = ContiguousArray<Float>(centersBufferPointer)
        print(centersResult)
        
        let didChangePointer = didChangeBuffer.contents().assumingMemoryBound(to: UInt32.self)
        let didChangeBufferPointer = UnsafeBufferPointer<UInt32>(
            start: didChangePointer,
            count: 1
        )
        let didChangeResult = ContiguousArray<UInt32>(didChangeBufferPointer)
        print(didChangeResult)
        
        print("Finished")
    }
}
