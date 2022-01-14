//
//  PointView.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import UIKit

final class PointView: UIView {
    
    enum Constants {
        static let baseColor: UIColor = .white
        static let diameter: CGFloat = 8
        static let radius = diameter / 2
        static let cornerRadius = radius
        static let size: CGSize = .init(width: diameter, height: diameter)
    }
    
    private let mainColor: UIColor
    
    private init(frame: CGRect, color: UIColor) {
        self.mainColor = color
        super.init(frame: frame)
        setup()
    }
    
    convenience init(center: CGPoint, color: UIColor? = nil) {
        let modifiedOrigin = CGPoint(
            x: center.x - Constants.radius,
            y: center.y - Constants.radius
        )
        self.init(
            frame: .init(origin: modifiedOrigin, size: Constants.size),
            color: color ?? Constants.baseColor
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = mainColor
//        layer.shouldRasterize = true
        layer.cornerRadius = Constants.cornerRadius
        clipsToBounds = true
    }
    
}
