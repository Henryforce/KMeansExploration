//
//  DataPointsViewController.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import UIKit

final class DataPointsViewController: UIViewController {
    
    private lazy var pointsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var dataPoints: [DataPoint]
    private var firstDisplay = false
    
    init(with dataPoints: [DataPoint] = []) {
        self.dataPoints = dataPoints
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !firstDisplay else { return }
        firstDisplay = true
        drawPoints()
    }
    
    func updateDataPoints(_ dataPoints: [DataPoint]) {
        self.dataPoints = dataPoints
        resetPointViews()
        drawPoints()
    }
    
    private func setup() {
        setupPointsContainerView()
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
        let maxX = pointsContainerView.bounds.maxX
        let maxY = pointsContainerView.bounds.maxY
        
        for data in dataPoints {
            let center = data.center
            let color = data.color
            
            let adjustedCenter = CGPoint(
                x: center.x * maxX,
                y: center.y * maxY
            )
            
            let dataView = PointView(center: adjustedCenter, color: color)
            pointsContainerView.addSubview(dataView)
        }
    }
    
    private func resetPointViews() {
        var counter = 0
        for pointView in pointsContainerView.subviews where pointView is PointView {
            pointView.removeFromSuperview()
            counter += 1
        }
        print("Removed \(counter) points")
    }
    
}
