//
//  KMeansError.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import Foundation

enum KMeansError: Error {
    case invalidClusters
    case invalidDimensions
    case outOfBoundsDimension(Int)
    case gpuError
}
