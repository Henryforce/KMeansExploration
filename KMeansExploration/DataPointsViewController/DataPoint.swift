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
    
    var color: UIColor? {
        guard let groupId = groupId else { return nil }
        switch groupId {
        case 0: return .red
        case 1: return .green
        case 2: return .blue
        case 3: return .yellow
        case 4: return .cyan
        case 5: return .brown
        case 6: return .orange
        default: return nil
        }
    }
}
