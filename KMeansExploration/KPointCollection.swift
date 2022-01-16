//
//  KPointCollection.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import Foundation

struct KPointCollection {
    
    let dimensions: Int
    private var _points: [KPoint]
    
    init?(dimensions: Int) {
        guard dimensions > .zero else { return nil }
        self.dimensions = dimensions
        self._points = [KPoint]()
    }
    
    ///
    /// Initialize from a collection of points with each point having the same d elements.
    /// Fails to initialize if the points don't have the same dimensions (items count).
    ///
    /// - Complexity
    /// O(n)
    ///
    init?(points: [[Double]]) {
        guard !points.isEmpty else { return nil }
        
        let baseDimensions = points[0].count
        var kPoints = [KPoint]()
        kPoints.reserveCapacity(points.count)
        
        for point in points {
            if point.count != baseDimensions {
                return nil
            }
            kPoints.append(KPoint(values: point))
        }
        
        self.dimensions = baseDimensions
        self._points = kPoints
    }
    
}

extension KPointCollection {
    var points: [KPoint] { _points }
    var count: Int { _points.count }
    var isEmpty: Bool { _points.isEmpty }
    
    // TODO: check
    func point(at index: Int) -> KPoint {
        _points[index]
    }
    
    @discardableResult
    mutating func append(_ point: [Double]) -> Bool {
        guard point.count == dimensions else { return false }
        _points.append(KPoint(values: point))
        return true
    }
    
    @discardableResult
    mutating func append(_ point: KPoint) -> Bool {
        guard point.dimensions == dimensions else { return false }
        _points.append(point)
        return true
    }
    
    @discardableResult
    mutating func append(contentsOf points: [KPoint]) -> Bool {
        guard !points.isEmpty, points[0].dimensions == dimensions else { return false }
        let previousCount = _points.count
        
        for point in points {
            // There is a corrupt item, abort appending and remove all previously appended items in this function
            guard point.dimensions == dimensions else {
                while _points.count > previousCount {
                    _points.removeLast()
                }
                return false
            }
            append(point)
        }
        return true
    }
}

extension KPointCollection {
    var contiguousFloatArray: ContiguousArray<Float> {
        var data = ContiguousArray<Float>.init(repeating: 0.0, count: _points.count * dimensions)
//        data.reserveCapacity(_points.count * dimensions)
        var index = 0
        
        for point in points {
//            let values = point.values.map { Float($0) }
//            data.append(contentsOf: values)
            for value in point.values {
                data[index] = Float(value)
                index += 1
            }
        }
        
        return data
    }
}

extension Array where Element == KPoint {
    var contiguousFloatArray: ContiguousArray<Float> {
        let dimensions = first?.dimensions ?? 0
        var data = ContiguousArray<Float>.init(repeating: 0.0, count: count * dimensions)
        var index = 0
        
        for point in self {
            for value in point.values {
                data[index] = Float(value)
                index += 1
            }
        }
        
        return data
    }
}
