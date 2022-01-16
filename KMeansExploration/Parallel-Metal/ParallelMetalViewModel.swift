//
//  ParallelMetalViewModel.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 15/1/22.
//

import UIKit

/// - Note
/// This view model is not thread safe.
/// Adding @MainActor or changing the object definition to an actor instead of a class
/// can make this view model thread safe.
final class ParallelMetalViewModel {
    
//    private var elements = [KPoint]()
    private lazy var kPointCollection = KPointCollection(dimensions: 2)!
    
    /// Random points will be generated between values 0 and 1 inclusive
    @discardableResult
    func randomDataPoints() -> [DataPoint] {
        let maxX = 1.0
        let maxY = 1.0
        
        let maxCount = 50000 + 9 // Int(Int16.max)
        let count = Int.random(in: 50000...maxCount)
        
        var elements = [KPoint]()
        
        for _ in 0..<count {
            let x = CGFloat.random(in: 0...maxX)
            let y = CGFloat.random(in: 0...maxY)
            let point = KPoint(values: [x, y])
            elements.append(point)
        }
        
//        self.elements = elements
        kPointCollection.append(contentsOf: elements)
        return elements.map { DataPoint(x: $0.value(at: 0), y: $0.value(at: 1)) }
    }
    
    func runKMeans() throws -> [DataPoint] {
        let clusters = 5

        if kPointCollection.isEmpty {
            randomDataPoints()
        }
        let elements = kPointCollection.points

        // TODO: change to parallel metal
//        var kMeans = SequentialKMeans()
        var kMeans = ParallelMetalKMeans()

        try kMeans.compute(kPointCollection: kPointCollection, clusterCount: clusters)
//        print(kMeans.centers)
//        print(kMeans.labels)

        return zip(elements, kMeans.labels)
            .map { (element, label) -> DataPoint in
                DataPoint(x: element.value(at: 0), y: element.value(at: 1), groupId: label)
            }
    }
    
//    func runKMeans() throws -> [DataPoint] {
//        let maxCount = 12
//        var input = ContiguousArray<Float>(repeating: 0.0, count: maxCount)
//        (0..<maxCount).forEach({
////            input[$0] = Float(arc4random()) / Float(UInt32.max) * 10.0
//            input[$0] = Float($0)
//        })
//        
//        var kMeans = ParallelMetalKMeans()
////        let result = kMeans.process(data: input)
////        print(result)
//        
////        kMeans.findLabel()
////        kMeans.updateCenters()
//        do {
//            try kMeans.run()
//        } catch(let error) {
//            print(error)
//        }
//        
//        return []
//    }
    
}
