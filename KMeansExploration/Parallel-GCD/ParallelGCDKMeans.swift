//
//  ParallelGCDKMeans.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 18/1/22.
//

import UIKit

final class ParallelGCDKMeans {
    
    private let seed: Int
    private let maxIteration: Int
    private let threshold: Double
    
    private var _labels = [Int]()
    
    /// Label for each element passed on the last call to compute()
    var labels: [Int] { _labels }
    
    init(seed: Int = 1, maxIteration: Int = 50, threshold: Double = 0.00001) {
        self.seed = seed
        self.maxIteration = maxIteration
        self.threshold = threshold
        
    }
    
    func compute(kPointCollection: KPointCollection, clusterCount: Int) throws {
        let start = Date().timeIntervalSince1970
        
        let threshold = threshold
        let elements = kPointCollection.points
        let dimensions = kPointCollection.dimensions
        let dataIO = ParallelGCDKMeansData(
            elements: elements,
            dimensions: dimensions,
            clusterCount: clusterCount
        )
        
        let processorCount = ProcessInfo.processInfo.processorCount
        
        var didChange = false
        var iteration = 0
        while iteration < maxIteration {
            guard !didChange else { break }
//            defer { iteration += 1 }
            
            dataIO.reset()
            let centers = dataIO.centers
            
            let labelGroup = DispatchGroup()
            let findLabelQueueLabel = "FindLabel"
            let findLabelQueue = DispatchQueue.global(qos: .default)
            
            for processorId in 0..<processorCount {
                findLabelQueue.async(group: labelGroup) {
                    Self.findLabels(
                        processorId: processorId,
                        elements: elements,
                        centers: centers,
                        dataIO: dataIO,
                        dimensions: dimensions,
                        clusterCount: clusterCount,
                        processorCount: processorCount
                    )
                }
            }
            labelGroup.wait()
            
            let means = dataIO.means
            let counters = dataIO.counters
            
            let centerGroup = DispatchGroup()
            let updateCenterQueueLabel = "UpdateCenter"
//            let updateCenterQueue = DispatchQueue(label: updateCenterQueueLabel, qos: .default, attributes: .concurrent)
            let updateCenterQueue = DispatchQueue.global(qos: .default)
            
            for index in 0..<clusterCount {
                updateCenterQueue.async(group: centerGroup) {
                    Self.updateCenters(
                        oldCenter: centers[index],
                        mean: means[index],
                        dataIO: dataIO,
                        count: counters[index],
                        clusterID: index,
                        dimensions: dimensions,
                        threshold: threshold
                    )
                }
            }
            
            centerGroup.wait()
            didChange = dataIO.didChange
            
            iteration += 1
        }
        
        _labels = dataIO.labels
        
        let finish = Date().timeIntervalSince1970
        print("Finished at \(start.distance(to: finish)), iterations: \(iteration)")
    }
    
    private static func findLabels(
        processorId: Int,
        elements: [KPoint],
        centers: [KPoint],
        dataIO: ParallelGCDKMeansData,
        dimensions: Int,
        clusterCount: Int,
        processorCount: Int
    ) {
        let maxCount = elements.count
        let groupSize = (maxCount + processorCount - 1) / processorCount
        let offset = processorId * groupSize
        let adjustGroupSize = (offset + groupSize) < maxCount
            ? groupSize
            : maxCount - offset
        let range = offset..<(adjustGroupSize + offset)
        
        for elementID in range {
            let element = elements[elementID]
            var label = 0
            var minDistance = Double.greatestFiniteMagnitude
            
            for clusterId in 0..<clusterCount {
                var distance = 0.0
                for dimension in 0..<dimensions {
                    let diff = element.value(at: dimension) - centers[clusterId].value(at: dimension)
                    distance += diff * diff
                }

                if distance < minDistance {
                    minDistance = distance
                    label = clusterId
                }
            }

            // TODO: make less calls to the actor
            for dimension in 0..<dimensions {
                let value = element.value(at: dimension)
//                await dataActor.addToMean(value: value, dimension: dimension, id: label)
                dataIO.addToMean(value: value, dimension: dimension, id: label)
            }

//            await dataActor.updateCounter(at: label)
//            await dataActor.updateLabel(value: label, at: elementID)
            dataIO.updateCounter(at: label)
            dataIO.updateLabel(value: label, at: elementID)
        }
    }
    
    private static func updateCenters(
        oldCenter: KPoint,
        mean: KPoint,
        dataIO: ParallelGCDKMeansData,
        count: Int,
        clusterID: Int,
        dimensions: Int,
        threshold: Double
    ) {
        guard count > 0 else { return }
        
        for dimension in 0..<dimensions {
            var didChange = false
            let oldValue = oldCenter.value(at: dimension)
            let updatedValue = mean.value(at: dimension) / Double(count)
            
            if abs(oldValue - updatedValue) > threshold {
                didChange = true
            }
            
//            await dataActor.updateCenter(value: updatedValue, at: kID, dimension: dimension, didChange: didChange)
            dataIO.updateCenter(value: updatedValue, at: clusterID, dimension: dimension, didChange: didChange)
        }
    }
    
}
