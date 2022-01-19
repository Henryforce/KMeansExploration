//
//  ParallelSwiftConcurrencyKMeans.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 17/1/22.
//

import UIKit

final class ParallelSwiftConcurrencyKMeans: KMeans {
    
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
    
    func compute(kPointCollection: KPointCollection, clusterCount: Int) async throws {
        let start = Date().timeIntervalSince1970
        
        let threshold = threshold
        let elements = kPointCollection.points
        let dimensions = kPointCollection.dimensions
        let dataActor = ParallelSwiftConcurrencyKMeansData(
            elements: elements,
            dimensions: dimensions,
            clusterCount: clusterCount
        )
        
        let processorCount = ProcessInfo.processInfo.processorCount
        
        var didChange = false
        var iteration = 0
        while iteration < maxIteration {
            guard !didChange else { break }
            defer { iteration += 1 }
            
            await dataActor.reset()
            
            let centers = await dataActor.centers
            
            for processorId in 0..<processorCount {
                Task.detached(priority: .high) {
                    await Self.findLabels(
                        processorId: processorId,
                        elements: elements,
                        centers: centers,
                        dataActor: dataActor,
                        dimensions: dimensions,
                        clusterCount: clusterCount,
                        processorCount: processorCount
                    )
                }
            }
            // TODO: check if all results are true
            await dataActor.waitForLabelsToBeUpdated()
            
            let means = await dataActor.means
            let counters = await dataActor.counters
            
            for index in 0..<clusterCount {
                Task.detached(priority: .high) {
                    await Self.updateCenters(
                        oldCenter: centers[index],
                        mean: means[index],
                        dataActor: dataActor,
                        count: counters[index],
                        kID: index,
                        dimensions: dimensions,
                        threshold: threshold
                    )
                }
            }
            
            didChange = await dataActor.waitForCentersToBeUpdated()
        }
        
        _labels = await dataActor.labels
        
        let finish = Date().timeIntervalSince1970
        print("Finished at \(start.distance(to: finish))")
    }
    
    private static func findLabels(
        processorId: Int,
        elements: [KPoint],
        centers: [KPoint],
        dataActor: ParallelSwiftConcurrencyKMeansData,
        dimensions: Int,
        clusterCount: Int,
        processorCount: Int
    ) async -> Bool {
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
                await dataActor.addToMean(value: value, dimension: dimension, id: label)
            }

            await dataActor.updateCounter(at: label)
            await dataActor.updateLabel(value: label, at: elementID)
        }
        
        return true
    }
    
    private static func updateCenters(
        oldCenter: KPoint,
        mean: KPoint,
        dataActor: ParallelSwiftConcurrencyKMeansData,
        count: Int,
        kID: Int,
        dimensions: Int,
        threshold: Double
    ) async -> Bool {
        guard count > 0 else { return true }
        
        var didChange = false
        for dimension in 0..<dimensions {
            let oldValue = oldCenter.value(at: dimension)
            let updatedValue = mean.value(at: dimension) / Double(count)
            
            if abs(oldValue - updatedValue) > threshold {
                didChange = true
            }
            
            await dataActor.updateCenter(value: updatedValue, at: kID, dimension: dimension, didChange: didChange)
        }
        
        return didChange
    }
    
}
