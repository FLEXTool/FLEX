//
//  SceneDelegate.swift
//  FLEXample
//
//  Created by Tanner on 3/11/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

import UIKit
import SwiftUI

@objcMembers @available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = FLEXNavigationController(rootViewController: CommitListViewController())
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        FLEXManager.shared.showExplorer()
    }
}

