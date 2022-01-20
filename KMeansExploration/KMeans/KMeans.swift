//
//  KMeans.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 18/1/22.
//

import Foundation

protocol KMeans {
    var labels: [Int] { get }
    init(seed: Int, maxIteration: Int, threshold: Double)
    func compute(kPointCollection: KPointCollection, clusterCount: Int) async throws
}
