//
//  DataPoint.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import UIKit

struct DataPoint {
    let x: CGFloat
    let y: CGFloat
    let groupId: Int?
    
    init(
        x: CGFloat,
        y: CGFloat,
        groupId: Int? = nil
    ) {
        self.x = x
        self.y = y
        self.groupId = groupId
    }
}

extension DataPoint {
    var center: CGPoint { .init(x: x, y: y) }
}
