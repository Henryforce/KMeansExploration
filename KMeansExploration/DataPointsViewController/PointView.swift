//
//  PointView.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import UIKit

final class PointView: UIView {
    
    enum Constants {
        static let baseColor: UIColor = .black
        static let diameter: CGFloat = 5
        static let radius = diameter / 2
        static let cornerRadius = diameter
        static let size: CGSize = .init(width: diameter, height: diameter)
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    convenience init(center: CGPoint) {
        let modifiedOrigin = CGPoint(
            x: center.x - Constants.radius,
            y: center.y - Constants.radius
        )
        self.init(frame: .init(origin: modifiedOrigin, size: Constants.size))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = Constants.baseColor
//        layer.shouldRasterize = true
        layer.cornerRadius = Constants.cornerRadius
        clipsToBounds = true
    }
    
}
