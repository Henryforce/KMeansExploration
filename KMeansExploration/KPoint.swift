//
//  KPoint.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import Foundation

struct KPoint {
    private var _values: [Double] // _values can only be internally mutated
    
    /// Each value represent a dimension
    var values: [Double] { _values }
    
    init(values: [Double]) {
        self._values = values
    }
}

extension KPoint {
    var dimensions: Int { _values.count }
    
    func value(at dimension: Int) -> Double {
        return _values[dimension]
    }
    
    mutating func updateValue(_ value: Double, at dimension: Int) {
        _values[dimension] = value
    }
}
