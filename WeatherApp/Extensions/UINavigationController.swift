//
//  UINavigationController.swift
//  WeatherApp
//
//
//

import Foundation
import UIKit

// Provide Default Swipe left gesture for back navigation to all screen.
//
// `@retroactive` is required here: this declares a conformance between two
// types from UIKit (UINavigationController and UIGestureRecognizerDelegate),
// which Swift 6 calls a "retroactive conformance". Without the annotation the
// compiler warns that UIKit could adopt this conformance itself later and
// silently change the behaviour. The annotation states that the conformance is
// deliberate and that we accept responsibility for it.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
