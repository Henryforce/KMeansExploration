//
//  KMeansViewModel.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 18/1/22.
//

import UIKit

final class KMeansViewModel {
    
    enum Implementation {
        case sequential
        case gcd
        case nsOperation
        case swiftAsync
        case metal
    }
    
    private let implementation: Implementation
    private lazy var kPointCollection = KPointCollection(dimensions: 2)!
    
    init(with implementation: Implementation) {
        self.implementation = implementation
    }
    
    /// Random points will be generated between values 0 and 1 inclusive
    @discardableResult
    func randomDataPoints() -> [DataPoint] {
        let maxX = 1.0
        let maxY = 1.0
        
        let maxCount = 10000 + 9 // Int(Int16.max)
        let count = Int.random(in: 10000...maxCount)
        
        var elements = [KPoint]()
        
        for _ in 0..<count {
            let x = CGFloat.random(in: 0...maxX)
            let y = CGFloat.random(in: 0...maxY)
            let point = KPoint(values: [x, y])
            elements.append(point)
        }
        
        kPointCollection.append(contentsOf: elements)
        return elements.map { DataPoint(x: $0.value(at: 0), y: $0.value(at: 1)) }
    }
    
    func run() async throws -> [DataPoint] {
        let clusters = 5
        if kPointCollection.isEmpty {
            randomDataPoints()
        }
        let elements = kPointCollection.points
        
        let kMeans = kMeansImplementation
        try await kMeans.compute(kPointCollection: kPointCollection, clusterCount: clusters)
        
        return zip(elements, kMeans.labels)
            .map { (element, label) -> DataPoint in
                DataPoint(x: element.value(at: 0), y: element.value(at: 1), groupId: label)
            }
    }
    
    // TODO: implement more options
    private var kMeansImplementation: KMeans {
        switch implementation {
        case .swiftAsync:
            return ParallelSwiftConcurrencyKMeans()
        default:
            return ParallelSwiftConcurrencyKMeans()
        }
    }
    
}
