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
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: nil, sessionRole: session.role)
    }

    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FLEXManager.shared.isNetworkDebuggingEnabled = true

        // To show off the global entries, register one of each type

        FLEXManager.shared.globalEntriesContainer.registerGlobalEntry(withName: "Level 1 - Object", cellAccessoryType: .none) {
            return "Level 1 - Object"
        }

        FLEXManager.shared.globalEntriesContainer.registerGlobalEntry(withName: "Level 1 - View controller", cellAccessoryType: .none) {
            let label = UILabel()
            label.text = "Level 1 - View controller"
            label.translatesAutoresizingMaskIntoConstraints = false

            let controller = UIViewController()
            controller.view.backgroundColor = .darkGray
            controller.view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
            ])

            return controller
        }

        FLEXManager.shared.globalEntriesContainer.registerGlobalEntry(withName: "Level 1 - Action", cellAccessoryType: .none) { host in
            FLEXAlert.showQuickAlert("Level 1 - Action", from: host)
        }

        FLEXManager.shared.globalEntriesContainer.registerNestedGlobalEntry(withName: "Level 1 - Nested") { container in
            container.registerGlobalEntry(withName: "Level 2 - Object", cellAccessoryType: .none) {
                return "Level 2 - Object"
            }

            container.registerGlobalEntry(withName: "Level 2 - View controller", cellAccessoryType: .none) {
                let label = UILabel()
                label.text = "Level 2 - View controller"
                label.translatesAutoresizingMaskIntoConstraints = false

                let controller = UIViewController()
                controller.view.backgroundColor = .darkGray
                controller.view.addSubview(label)
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
                ])

                return controller
            }

            container.registerGlobalEntry(withName: "Level 2 - Action", cellAccessoryType: .none) { host in
                FLEXAlert.showQuickAlert("Level 2 - Action", from: host)
            }

            container.registerNestedGlobalEntry(withName: "Level 2 - Nested") { level2Container in
                level2Container.registerGlobalEntry(withName: "Level 3 - Action", cellAccessoryType: .none) { host in
                    FLEXAlert.showQuickAlert("Level 3 - Action", from: host)
                }
            }
        }

        // Add at least one custom user defaults key to explore
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
        
        // For testing unarchiving of objects
        self.archiveBob()
        
        // For < iOS 13, set up the window here
        self.setupWindow()
        
        return true
    }
    
    func setupWindow() {
        guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 13 else {
            return
        }
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = FLEXNavigationController(
            rootViewController: CommitListViewController()
        )
        self.window = window
        window.makeKeyAndVisible()
        FLEXManager.shared.showExplorer()
    }
    
    func archiveBob() {
        let documents = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first! as NSString
        let whereToSaveBob = documents.appendingPathComponent("Bob.plist")
        try! NSKeyedArchiver.archivedData(
            withRootObject: Person.bob(), requiringSecureCoding: false
        ).write(to: URL(fileURLWithPath: whereToSaveBob), options: [])
    }
    
    let exampleLogLimit = 10
    var exampleLogSent = 0
}
