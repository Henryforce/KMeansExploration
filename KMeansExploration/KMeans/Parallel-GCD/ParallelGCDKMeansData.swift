//
//  ParallelGCDKMeansData.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 18/1/22.
//

import Foundation

final class ParallelGCDKMeansData {
    
    private let dimensions: Int
    private let clusterCount: Int
    private let dataIOQueue: DispatchQueue
    
    private var _centers: [KPoint]
    private var _counters: [Int]
    private var _means: [KPoint]
    private var _labels: [Int]
    private var _didChange = false
    
    var labels: [Int] { dataIOQueue.sync { _labels } }
    var centers: [KPoint] { dataIOQueue.sync { _centers } }
    var means: [KPoint] { dataIOQueue.sync { _means } }
    var counters: [Int] { dataIOQueue.sync { _counters } }
    var didChange: Bool { dataIOQueue.sync { _didChange } }
    
    init(
        elements: [KPoint],
        dimensions: Int,
        clusterCount: Int,
        dataIOQueue: DispatchQueue = DispatchQueue(label: "ParallelGCDKMeansData", qos: .userInteractive)
    ) {
        self.clusterCount = clusterCount
        self.dimensions = dimensions
        self._labels = Array(repeating: 0, count: elements.count)
        self._centers = Self.centersFrom(elements, clusterCount: clusterCount, seed: 1)
        self._means = Array(
            repeating: .init(values: Array(repeating: 0.0, count: dimensions)),
            count: clusterCount
        )
        self._counters = Array(repeating: 0, count: clusterCount)
        self.dataIOQueue = dataIOQueue
    }
    
    func updateLabel(value: Int, at id: Int) {
        dataIOQueue.async(flags: .barrier) {
            self._labels[id] = value
        }
    }
    
    func updateCounter(at id: Int) {
        dataIOQueue.async(flags: .barrier) {
            self._counters[id] += 1
        }
    }
    
    func addToMean(value: Double, dimension: Int, id: Int) {
        dataIOQueue.async(flags: .barrier) {
            let updatedValue = self._means[id].value(at: dimension) + value
            self._means[id].updateValue(updatedValue, at: dimension)
        }
    }
    
    func updateCenter(value: Double, at id: Int, dimension: Int, didChange: Bool) {
        dataIOQueue.async(flags: .barrier) {
            self._centers[id].updateValue(value, at: dimension)
            self._didChange = self._didChange || didChange
        }
    }
    
    func reset() {
        dataIOQueue.async(flags: .barrier) {
            self._didChange = false
            for clusterId in 0..<self.clusterCount {
                self._counters[clusterId] = 0
                for dimension in 0..<self.dimensions {
                    self._means[clusterId].updateValue(.zero, at: dimension)
                }
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
