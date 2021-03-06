//
//  ViewController.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 10/1/22.
//

import UIKit
import SwiftUI

protocol ViewControllerDelegate: AnyObject {
    func itemPressed(at index: Int)
}

final class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        addMainView()
    }
    
    private func addMainView() {
        var mainView = MainView()
        mainView.delegate = self
        
        let mainController = UIHostingController(rootView: mainView)
        mainController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildControllerToViewStack(mainController)
        
        NSLayoutConstraint.activate([
            mainController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mainController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

}

extension ViewController: ViewControllerDelegate {
    func itemPressed(at index: Int) {
        guard let kMeansImpl = kMeansImplementation(for: index) else { return }
        let viewModel = KMeansViewModel(with: kMeansImpl)
        let viewController = KMeansViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func kMeansImplementation(for index: Int) -> KMeansViewModel.Implementation? {
        switch index {
        case 0: return .sequential
        case 1: return .gcd
        case 2: return .nsOperation
        case 3: return .swiftAsync
        case 4: return .metal
        default: return nil
        }
    }
}

struct MainView: View {
    let items = [
        "Sequential",
        "Parallel with GCD",
        "Parallel with NSOperation",
        "Parallel with Swift Concurrency",
        "Parallel with Metal",
    ].enumerated().map { MainItem(id: $0, title: $1) }
    weak var delegate: ViewControllerDelegate?
    
    struct MainItem: Identifiable {
        let id: Int
        let title: String
    }
    
    var body: some View {
        List(items) { item in
            Text(item.title)
                .onTapGesture {
                    delegate?.itemPressed(at: item.id)
                }
        }
    }
}
