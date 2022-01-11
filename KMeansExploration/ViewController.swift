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
        addChild(mainController)
        mainController.didMove(toParent: self)
        mainController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainController.view)
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
        var controller: UIViewController?
        switch index {
        default:
            break
        }
        guard let controller = controller else { return }
        navigationController?.pushViewController(controller, animated: true)
    }
}

struct MainView: View {
    let items = [
        "AsyncStream - Simple",
        "AsyncStream - Rx Behavior",
        "Multiple producer - single consumer in KMeans"
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
