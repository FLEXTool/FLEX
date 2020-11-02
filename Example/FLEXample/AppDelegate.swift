//
//  AppDelegate.swift
//  FLEXample
//
//  Created by Tanner on 3/11/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

import UIKit

@UIApplicationMain @objcMembers
class AppDelegate: UIResponder, UIApplicationDelegate {
    var repeatingLogExampleTimer: Timer!
    var window: UIWindow?

    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FLEXManager.shared.isNetworkDebuggingEnabled = true
        
        // Add at least oen custom user defaults key to explore
        UserDefaults.standard.set("foo", forKey: "FLEXamplePrefFoo")
        
        // To show off the system log viewer, send 10 example log messages at 3 second intervals
        self.repeatingLogExampleTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] (_) in
            if let self = self {
                NSLog("Example log \(self.exampleLogSent)")
        
                self.exampleLogSent += 1
                if self.exampleLogSent > self.exampleLogLimit {
                    self.repeatingLogExampleTimer.invalidate()
                }
            }
        }
        
        // To show off the network logger, send several misc network requests
        MiscNetworkRequests.sendExampleRequests()
        
        // For < iOS 13, set up the window here
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 13 {
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = FLEXNavigationController(
                rootViewController: CommitListViewController()
            )
            self.window = window
            window.makeKeyAndVisible()
            FLEXManager.shared.showExplorer()
        }
        
        return true
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: nil, sessionRole: session.role)
    }
    
    
    let exampleLogLimit = 10
    var exampleLogSent = 0
}
