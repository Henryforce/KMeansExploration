//
//  UIViewController+AddChild.swift
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 14/1/22.
//

import UIKit

extension UIViewController {
    func addChildControllerToViewStack(_ childController: UIViewController) {
        addChild(childController)
        childController.didMove(toParent: self)
        view.addSubview(childController.view)
    }
}
