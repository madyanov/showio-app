//
//  ShowsCoordinator.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 14/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import CoreData
import Toolkit

final class ShowsCoordinator: NSObject
{
    private weak var showsViewController: ShowsViewController? {
        didSet {
            showsViewController?.delegate = self
            showsViewController?.showsCollectionViewDelegate = self
            showsViewController?.showsCollectionViewDataSource = self
        }
    }

    private lazy var searchViewController = SearchCoordinator.makeViewController(with: services)

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

    static func makeViewController(with services: ServiceContainer) -> ShowsViewController {
        let coordinator = ShowsCoordinator(services: services)
        let viewController = ShowsViewController(coordinator: coordinator)
        return viewController
    }

    func didLoadView(_ viewController: ShowsViewController) {
        showsViewController = viewController

        try? fetchedResultsController.performFetch()

        startListenForThemeChange()
    }
}

extension ShowsCoordinator: ShowsViewControllerDelegate
{
    func didTapAddButton(in showsViewController: ShowsViewController) {
        showsViewController.navigationController?.pushViewController(searchViewController, animated: true)
    }

    func didTapFeedbackButton(in showsViewController: ShowsViewController) {
        guard
            let email = services.config[.configSupportEmail],
            let url = URL(string: "mailto:\(email)")
        else {
            return
        }

        UIApplication.shared.open(url)
    }

    func didTapPrivacyPolicyButton(in showsViewController: ShowsViewController) {
        guard
            let privacyPolicyURL = services.config[.configPrivacyPolicyURL],
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

extension ShowsCoordinator: ShowsCollectionViewDelegate
{
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView,
                             didTapOn cell: ShowCollectionViewCell,
                             at index: Int)
    {
        let showViewController = ShowCoordinator.makeViewController(with: show(at: index), services: services)
        showsViewController?.animatedSubviews = [cell.posterImageView]
        showsViewController?.present(showViewController, animated: true)
    }

    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, didTapDeleteButtonForItemAt index: Int) {
        deleteShow(at: index)
    }
}

extension ShowsCoordinator: ShowsCollectionViewDataSource
{
    func numberOfItems(in showsCollectionView: ShowsCollectionView) -> Int {
        return fetchedResultsController.sections?.first?.numberOfObjects ?? 0
    }

    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, showForItemAt index: Int) -> Show {
        return show(at: index)
    }
}

extension ShowsCoordinator: NSFetchedResultsControllerDelegate
{
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?)
    {
        changes.append((type: type, indexPath: indexPath, newIndexPath: newIndexPath))
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        showsViewController?.performBatchUpdates {
            for change in changes {
                let index = change.indexPath?.item ?? 0
                let newIndex = change.newIndexPath?.item ?? 0

                switch change.type {
                case .insert: showsViewController?.insertShow(at: newIndex)
                case .delete: showsViewController?.deleteShow(at: index)
                case .update: showsViewController?.updateShow(at: index, show: show(at: index))
                case .move:
                    showsViewController?.deleteShow(at: index)
                    showsViewController?.insertShow(at: newIndex)
                @unknown default:
                    assertionFailure("Unknown NSFetchedResultsChangeType")
                }
            }
        }

        changes.removeAll()
    }
}

extension ShowsCoordinator: ThemeChanging
{
    @objc
    func didChangeTheme() {
        showsViewController?.navigationController?.navigationBar.tintColor = Theme.current.tintColor
    }
}

extension ShowsCoordinator
{
    private func show(at index: Int) -> Show {
        return Show(from: fetchedResultsController.object(at: IndexPath(item: index, section: 0)))
    }

    private func deleteShow(at index: Int) {
        services.shows.delete(show: show(at: index), soft: false)
    }
}
