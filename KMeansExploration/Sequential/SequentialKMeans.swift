//
//  SequentialKMeans.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import Foundation

struct SequentialKMeans {
    
    private let seed: Int
    private let maxIteration: Int
    private let threshold: Double
    
    private var elements = [KPoint]()
    private var dimensions: Int = .zero
    private var clusterCount: Int = .zero
    private var _centers = [KPoint]()
    private var _labels = [Int]()
    private var means = [KPoint]()
    private var counters = [Int]()
    
    /// Center for each k cluster calculated on the last call to compute()
    var centers: [KPoint] { _centers }
    
    /// Label for each element passed on the last call to compute()
    var labels: [Int] { _labels }
    
    init(seed: Int = 1, maxIteration: Int = 50, threshold: Double = 0.00001) {
        self.seed = seed
        self.maxIteration = maxIteration
        self.threshold = threshold
    }
    
    /// Given **n** elements with **d** dimensions and **k** clusters, this function will
    /// calculate a center for each cluster and label each of the provided elements.
    /// The results will be available through this object's `centers` and `labels` properties.
    /// This function will iterate a maximum of **i** times or until the centers don't change
    /// given a specified threshold.
    ///
    /// - Complexity
    /// O(d\*i\*k\*n)
    mutating func compute(kPointCollection: KPointCollection, clusterCount: Int) throws {
        try setup(kPointCollection: kPointCollection, clusterCount: clusterCount)
        
        var iteration = 0
        while iteration < maxIteration {
            // label all the points
            for (index, element) in elements.enumerated() {
                findClosestClusterCenter(for: element, at: index)
            }
            
            // update centers and check for changes if they pass the threshold
            var didChange = false
            for clusterID in 0..<clusterCount {
                let changed = updateCenter(at: clusterID)
                didChange = didChange || changed
            }
            
            iteration += 1
            
            if !didChange { break }
            
            resetCountersAndMeans()
        }
    }
    
    private mutating func findClosestClusterCenter(for element: KPoint, at index: Int) {
        var closestClusterID = 0
        var minDistance = Double.greatestFiniteMagnitude
        
        // For each cluster calculate the euclidean distance to its center.
        // And then, save the cluster id (label) for the center with the minimal
        // distance to this element
        for clusterID in 0..<clusterCount {
            var distance = Double.zero
            
            for dimension in 0..<dimensions {
                let center = _centers[clusterID]
                let diff = element.value(at: dimension) - center.value(at: dimension)
                distance += diff * diff
            }

            if distance < minDistance {
                minDistance = distance
                closestClusterID = clusterID
            }
        }

        // Update the mean/average of all the dimensions in the closest cluster
        for dimension in 0..<dimensions {
            let value = element.value(at: dimension)
            addToMean(value: value, dimension: dimension, id: closestClusterID)
        }

        updateCounter(at: closestClusterID)
        updateLabel(closestClusterID, at: index)
    }
    
    private mutating func updateCenter(at clusterID: Int) -> Bool {
        let count = counters[clusterID]
        guard count > .zero else { return true }
        
        let oldCenter = _centers[clusterID]
        let mean = means[clusterID]
        
        var didChange = false
        for dimension in 0..<dimensions {
            let oldValue = oldCenter.value(at: dimension)
            let updatedValue = mean.value(at: dimension) / Double(count)
            updateCenter(value: updatedValue, at: clusterID, dimension: dimension)
            
            if abs(oldValue - updatedValue) > threshold {
                didChange = true
            }
        }
        
        return didChange
    }
    
    private mutating func updateLabel(_ value: Int, at id: Int) {
        _labels[id] = value
    }
    
    private mutating func updateCounter(at id: Int) {
        counters[id] += 1
    }
    
    private mutating func addToMean(value: Double, dimension: Int, id: Int) {
        let updatedValue = value + means[id].value(at: dimension)
        means[id].updateValue(updatedValue, at: dimension)
    }
    
    private mutating func updateCenter(value: Double, at id: Int, dimension: Int) {
        _centers[id].updateValue(value, at: dimension)
    }
    
    /// - Complexity
    /// O(n)
    private mutating func setup(kPointCollection: KPointCollection, clusterCount: Int) throws {
        self.dimensions = kPointCollection.dimensions
        self.clusterCount = clusterCount
        self.elements = try validate(kPointCollection.points)
        
        _centers = randomCenters
        _labels = Array(repeating: 0, count: elements.count)
        means = Array(
            repeating: .init(values: Array(repeating: 0.0, count: dimensions)),
            count: clusterCount
        )
        counters = Array(repeating: 0, count: clusterCount)
    }
    
    private mutating func resetCountersAndMeans() {
        for clusterID in 0..<clusterCount {
            counters[clusterID] = 0
            for dimension in 0..<dimensions {
                means[clusterID].updateValue(.zero, at: dimension)
            }
        }
    }
    
    private func validate(_ elements: [KPoint]) throws -> [KPoint] {
        guard dimensions > .zero else { throw KMeansError.invalidDimensions }
        guard clusterCount > .zero else { throw KMeansError.invalidClusters }
        
        var validatedElements = [KPoint]()
        validatedElements.reserveCapacity(elements.count)
        
        for element in elements {
            let maxDimension = element.dimensions
            guard maxDimension == dimensions else {
                throw KMeansError.outOfBoundsDimension(maxDimension - 1)
            }
            validatedElements.append(element)
        }
        
        return validatedElements
    }
    
    // TODO: make use of the seed parameter
    private var randomCenters: [KPoint] {
        return Array(repeating: 0, count: clusterCount) // set 0 as the base index
            .map { Int.random(in: $0..<elements.count) } // Select a random index
            .map { elements[$0] } // Use the random index to select an element
    }
    
}
