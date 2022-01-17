//
//  ParallelSwiftConcurrencyKMeansData.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 17/1/22.
//

import Foundation

actor ParallelSwiftConcurrencyKMeansData {
    
    let dimensions: Int
    let clusterCount: Int
    
    var centers: [KPoint]
    var counters: [Int]
    var means: [KPoint]
    var labels: [Int]
    
    private var labelUpdatedCounter = 0
    private var centerUpdatedCounter = 0
    private var centerDidChange = false
    private var labelUpdatedContinuation: CheckedContinuation<Void, Never>?
    private var centerUpdatedContinuation: CheckedContinuation<Bool, Never>?
    
    init(elements: [KPoint], dimensions: Int, clusterCount: Int) {
        self.clusterCount = clusterCount
        self.dimensions = dimensions
        self.labels = Array(repeating: 0, count: elements.count)
        self.centers = Self.centersFrom(elements, clusterCount: clusterCount, seed: 1)
        self.means = Array(
            repeating: .init(values: Array(repeating: 0.0, count: dimensions)),
            count: clusterCount
        )
        self.counters = Array(repeating: 0, count: clusterCount)
    }
    
    func waitForLabelsToBeUpdated() async {
        await withCheckedContinuation({ continuation in
            labelUpdatedContinuation = continuation
        })
    }
    
    func waitForCentersToBeUpdated() async -> Bool {
        await withCheckedContinuation({ continuation in
            centerUpdatedContinuation = continuation
        })
    }
    
    func updateLabel(value: Int, at id: Int) {
        labels[id] = value
        
        labelUpdatedCounter += 1
        if labelUpdatedCounter >= labels.count,
           let labelUpdatedContinuation = labelUpdatedContinuation {
            labelUpdatedContinuation.resume()
            self.labelUpdatedContinuation = nil
        }
    }
    
    func updateCounter(at id: Int) {
        counters[id] += 1
    }
    
    func addToMean(value: Double, dimension: Int, id: Int) {
        let updatedValue = means[id].value(at: dimension) + value
        means[id].updateValue(updatedValue, at: dimension)
    }
    
    func updateCenter(value: Double, at id: Int, dimension: Int, didChange: Bool) {
        centers[id].updateValue(value, at: dimension)
        
        centerUpdatedCounter += 1
        centerDidChange = centerDidChange || didChange
        if centerUpdatedCounter >= centers.count,
           let centerUpdatedContinuation = centerUpdatedContinuation {
            centerUpdatedContinuation.resume(returning: centerDidChange)
            self.centerUpdatedContinuation = nil
        }
    }
    
    func reset() {
        labelUpdatedCounter = 0
        centerUpdatedCounter = 0
        centerDidChange = false
        for clusterId in 0..<clusterCount {
            counters[clusterId] = 0
            for dimension in 0..<dimensions {
                means[clusterId].updateValue(.zero, at: dimension)
            }
        }
    }
    
    static func centersFrom(_ elements: [KPoint], clusterCount: Int, seed: Int) -> [KPoint] {
        var tempCenters = [KPoint]()
        
        for _ in 0..<clusterCount {
            let index = Int.random(in: 0..<elements.count)
            tempCenters.append(elements[index])
        }
        
        return tempCenters
    }
}
