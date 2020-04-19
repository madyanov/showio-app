//
//  AppDelegate.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 23/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    private lazy var services = Services()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        start()

        let showsViewController = ShowsCoordinator.makeViewController(with: services)

        let navigationController = UINavigationController()
        navigationController.navigationBar.makeTransparent()
        navigationController.viewControllers = [showsViewController]

        window = UIWindow()
        window?.backgroundColor = .white
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        setTheme()

        application.setMinimumBackgroundFetchInterval(60 * 60 * 3)

        return true
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        syncShows(completionHandler)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        services.shows.preloadImages()
    }
}

extension AppDelegate
{
    private func start() {
        UserDefaults.standard[.lastLaunchDate] = Date()

        syncShows()
    }

    private func syncShows(_ completion: ((UIBackgroundFetchResult) -> Void)? = nil) {
        services
            .shows
            .configure()
            .then { self.services.shows.syncRunningShows() }
            .then { completion?($0 > 0 ? .newData : .noData) }
            .catch { _ in completion?(.noData) }
    }

    private func setTheme() {
        if #available(iOS 13.0, *) {
            Theme.current = window?.traitCollection.userInterfaceStyle == .light ? .light : .dark
        } else {
            Theme.current = Theme(rawValue: UserDefaults.standard[.currentTheme] ?? "") ?? .light
        }
    }
}
