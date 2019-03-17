//
//  ShowsCoordinator.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 14/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import GoogleMobileAds
import Toolkit

class ShowsCoordinator: NSObject, Coordinator {
    var childCoordinators: [Coordinator] = []

    var viewController: UIViewController {
        Theme.current = Theme(rawValue: UserDefaults.standard[.currentTheme] ?? "") ?? .light
        return navigationController
    }

    private lazy var navigationController: UINavigationController = {
        let navigationController = UINavigationController()
        navigationController.navigationBar.makeTransparent()
        navigationController.viewControllers = [showsViewController]
        return navigationController
    }()

    private lazy var showsViewController: ShowsViewController = {
        let showsViewController = ShowsViewController()
        showsViewController.delegate = self
        showsViewController.showsCollectionViewDelegate = self
        showsViewController.showsCollectionViewDataSource = self
        showsViewController.shouldShowBottomBanner = !isFirstLaunch && services.config[.configAdMobEnabled] ?? false
        showsViewController.bottomBannerAdMobUnitID = services.config[.configAdMobBanners]?["shows_bottom"]
        showsViewController.adMobTestDevices = services.config[.configAdMobTestDevices] ?? []
        return showsViewController
    }()

    private lazy var searchCoordinator: SearchCoordinator = {
        let searchCoordinator = SearchCoordinator(services: services)
        searchCoordinator.delegate = self
        return searchCoordinator
    }()

    private lazy var fetchedResultsController: NSFetchedResultsController<ShowEntity> = {
        let fetchedResultsController = services.shows.makeFetchedResultsController()
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    private var isFirstLaunch: Bool {
        return UserDefaults.standard[.lastLaunchDate] == nil
    }

    private let services: ServiceContainer
    private var changes: [(type: NSFetchedResultsChangeType, indexPath: IndexPath?, newIndexPath: IndexPath?)] = []

    init(services: ServiceContainer) {
        self.services = services
    }

    func start() {
        if let adMobApplicaitonID = services.config[.configAdMobApplicationID] {
            GADMobileAds.configure(withApplicationID: adMobApplicaitonID)
        }

        services.shows.configure()
        try? fetchedResultsController.performFetch()

        UserDefaults.standard[.lastLaunchDate] = Date()
        startListenForThemeChange()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        services.shows.preloadImages()
    }

    func application(_ application: UIApplication,
                     performFetchWith completion: ((UIBackgroundFetchResult) -> Void)?)
    {
        services.shows.syncRunningShows()
            .then { numberOfNewEpisodes in
                if numberOfNewEpisodes > 0 {
                    completion?(.newData)
                } else {
                    completion?(.noData)
                }
            }
            .catch { _ in completion?(.noData) }
    }

    private func show(at index: Int) -> Show {
        return Show(from: fetchedResultsController.object(at: IndexPath(item: index, section: 0)))
    }

    private func deleteShow(at index: Int) {
        services.shows.delete(show: show(at: index), soft: false)
    }

    private func makeShowCoordinator() -> ShowCoordinator {
        let showCoordinator = ShowCoordinator(services: services)
        showCoordinator.delegate = self
        return showCoordinator
    }
}

extension ShowsCoordinator: ShowsViewControllerDelegate {
    func didTapAddButton(in showsViewController: ShowsViewController) {
        startCoordinator(searchCoordinator)
        navigationController.pushViewController(searchCoordinator.viewController, animated: true)
    }

    func didTapFeedbackButton(in showsViewController: ShowsViewController) {
        guard let email = services.config[.configSupportEmail],
              let url = URL(string: "mailto:\(email)")
        else {
            return
        }

        UIApplication.shared.open(url)
    }

    func didTapPrivacyPolicyButton(in showsViewController: ShowsViewController) {
        guard let privacyPolicyURL = services.config[.configPrivacyPolicyURL],
              let url = URL(string: privacyPolicyURL)
        else {
            return
        }

        UIApplication.shared.open(url)
    }

    func didTapSwitchThemeButton(in showsViewController: ShowsViewController) {
        Theme.current = Theme.current == .light ? .dark : .light
        UserDefaults.standard[.currentTheme] = Theme.current.rawValue
    }
}

extension ShowsCoordinator: SearchCoordinatorDelegate {
    func didClose(_ searchCoordinator: SearchCoordinator) {
        stopCoordinator(searchCoordinator)
    }
}

extension ShowsCoordinator: ShowsCollectionViewDelegate {
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView,
                             didTapOn cell: ShowCollectionViewCell,
                             at index: Int)
    {
        let showCoordinator = makeShowCoordinator()
        showCoordinator.model = show(at: index)
        startCoordinator(showCoordinator)

        showsViewController.animatedSubviews = [cell.posterImageView]

        showsViewController.present(showCoordinator.viewController, animated: true) {
            showCoordinator.actualizeModel()
        }
    }

    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, didTapDeleteButtonForItemAt index: Int) {
        deleteShow(at: index)
    }
}

extension ShowsCoordinator: ShowsCollectionViewDataSource {
    func numberOfItems(in showsCollectionView: ShowsCollectionView) -> Int {
        return fetchedResultsController.sections?.first?.numberOfObjects ?? 0
    }

    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, showForItemAt index: Int) -> Show {
        return show(at: index)
    }
}

extension ShowsCoordinator: ShowCoordinatorDelegate {
    func didClose(_ showCoordinator: ShowCoordinator) {
        stopCoordinator(showCoordinator)
    }
}

extension ShowsCoordinator: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?)
    {
        changes.append((type: type, indexPath: indexPath, newIndexPath: newIndexPath))
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        showsViewController.performBatchUpdates {
            for change in changes {
                let index = change.indexPath?.item ?? 0
                let newIndex = change.newIndexPath?.item ?? 0

                switch change.type {
                case .insert: showsViewController.insertShow(at: newIndex)
                case .delete: showsViewController.deleteShow(at: index)
                case .update: showsViewController.updateShow(at: index, show: show(at: index))
                case .move:
                    showsViewController.deleteShow(at: index)
                    showsViewController.insertShow(at: newIndex)
                }
            }
        }

        changes.removeAll()
    }
}

extension ShowsCoordinator: ChangingTheme {
    @objc func didChangeTheme() {
        navigationController.navigationBar.tintColor = Theme.current.tintColor
    }
}
