//
//  DataPointsViewController.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import UIKit

// TODO: remove comments

final class DataPointsViewController: UIViewController {
    
    private lazy var pointsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
//        view.backgroundColor = .white
        return view
    }()
    
    private var dataPoints: [DataPoint] = [
//            .init(x: 0, y: 0),
//            .init(x: 5, y: 100),
//            .init(x: 305, y: 300),
//            .init(x: 200, y: 50),
//            .init(x: 150, y: 400),
//            .init(x: 278, y: 200),
        
        .init(x: 10, y: 10),
        .init(x: 20, y: 20),
        .init(x: 30, y: 30),
        .init(x: 40, y: 40),
        .init(x: 50, y: 50),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func updateDataPoints(_ dataPoints: [DataPoint]) {
        self.dataPoints = dataPoints
        resetPointViews()
        drawPoints()
    }
    
    private func setup() {
        setupPointsContainerView()
        drawPoints()
    }
    
    private func setupPointsContainerView() {
        view.addSubview(pointsContainerView)
        
        NSLayoutConstraint.activate([
            pointsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pointsContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pointsContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pointsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func drawPoints() {
//        let size = view.bounds.size
        for data in dataPoints {
            let center = data.center
            let dataView = PointView(center: center)
            pointsContainerView.addSubview(dataView)
        }
    }
    
    private func resetPointViews() {
        for pointView in pointsContainerView.subviews where pointView is PointView {
            pointView.removeFromSuperview()
        }
    }
    
}
