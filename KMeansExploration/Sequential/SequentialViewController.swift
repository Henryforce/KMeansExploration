//
//  SequentialViewController.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import UIKit

final class SequentialViewController: UIViewController {
    
    private lazy var dataPointsViewController: DataPointsViewController = {
        let points = viewModel.randomDataPoints()
        let viewController = DataPointsViewController(with: points)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        return viewController
    }()
    
    private lazy var viewModel = SequentialViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataPointsViewController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /// Observation:
        /// Running KMeans sequentially using GCD or Swift Concurrency
        /// moves the execution to a different thread other than the main
        /// thread in the host computer.
        
        // Run the algorithm sequentially using a global queue
//        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            guard let dataPoints = try? self?.viewModel.runKMeans() else { return }
//            DispatchQueue.main.async { [weak self] in
//                self?.dataPointsViewController.updateDataPoints(dataPoints)
//            }
//        }
        
        // Run the algorithm sequentially in a detached Task
        Task.detached(priority: .high) { [weak self] in
            try await Task.sleep(nanoseconds: 1000 * 1000 * 1000) // sleep one second
            let viewModel = await self?.viewModel // get a reference to the view model
            guard let dataPoints = try? viewModel?.runKMeans() else { return } // run the view model function in this detached task
            await self?.dataPointsViewController.updateDataPoints(dataPoints)
        }
    }
    
    private func setupDataPointsViewController() {
        addChildControllerToViewStack(dataPointsViewController)
        
        NSLayoutConstraint.activate([
            dataPointsViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            dataPointsViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dataPointsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dataPointsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
}
