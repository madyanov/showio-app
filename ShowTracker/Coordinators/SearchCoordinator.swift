//
//  SearchCoordinator.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 14/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Foundation
import UIKit
import Toolkit

protocol SearchCoordinatorDelegate: AnyObject {
    func didClose(_ searchCoordinator: SearchCoordinator)
}

class SearchCoordinator: Coordinator {
    weak var delegate: SearchCoordinatorDelegate?

    var childCoordinators: [Coordinator] = []

    var viewController: UIViewController {
        return searchViewController
    }

    private lazy var searchViewController: SearchViewController = {
        let searchViewController = SearchViewController()
        searchViewController.delegate = self
        searchViewController.showsCollectionViewDelegate = self
        searchViewController.showsCollectionViewDataSource = self
        return searchViewController
    }()

    private lazy var debouncedSearchRequest = debounce(0.67) { (query: String) in
        guard query == self.searchViewController.searchQuery else {
            self.searchViewController.stopActivityIndicator()
            return
        }

        self.services.shows.search(query: query)
            .then { shows in
                guard query == self.searchViewController.searchQuery else {
                    return
                }

                self.shows = shows
                self.query = query
            }
            .finally { self.searchViewController.stopActivityIndicator() }
    }

    private let services: ServiceContainer
    private var query: String?

    private var shows: [Show] = [] {
        didSet {
            guard shows != oldValue else {
                return
            }

            searchViewController.reloadShows()
        }
    }

    func start() {
        loadTrendingShows()
    }

    private func clearSearchResults() {
        shows = []
        query = nil
    }

    private func loadTrendingShows() {
        searchViewController.startActivityIndicator()

        self.services.shows.trending()
            .then { shows in
                self.shows = shows
                self.query = nil
            }
            .finally { self.searchViewController.stopActivityIndicator() }
    }

    private func makeShowCoordinator() -> ShowCoordinator {
        let showCoordinator = ShowCoordinator(services: services)
        showCoordinator.delegate = self
        return showCoordinator
    }

    init(services: ServiceContainer) {
        self.services = services
    }
}

extension SearchCoordinator: SearchViewControllerDelegate {
    func didDisappear(_ searchViewController: SearchViewController) {
        delegate?.didClose(self)
    }

    func didChangeSearchQuery(in searchViewController: SearchViewController) {
        guard let query = searchViewController.searchQuery, !query.isEmpty else {
            loadTrendingShows()
            return
        }

        guard query != self.query else {
            return
        }

        clearSearchResults()
        searchViewController.startActivityIndicator()
        debouncedSearchRequest(query)
    }
}

extension SearchCoordinator: ShowsCollectionViewDelegate {
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView,
                             didTapOn cell: ShowCollectionViewCell,
                             at index: Int)
    {
        let showCoordinator = makeShowCoordinator()
        showCoordinator.model = shows[at: index]
        startCoordinator(showCoordinator)

        searchViewController.animatedSubviews = [cell.posterImageView]
        searchViewController.hideKeyboard()

        searchViewController.present(showCoordinator.viewController, animated: true) {
            showCoordinator.actualizeModel()
        }
    }
}

extension SearchCoordinator: ShowsCollectionViewDataSource {
    func numberOfItems(in showsCollectionView: ShowsCollectionView) -> Int {
        return shows.count
    }

    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, showForItemAt index: Int) -> Show {
        return shows[index]
    }
}

extension SearchCoordinator: ShowCoordinatorDelegate {
    func didClose(_ showCoordinator: ShowCoordinator) {
        stopCoordinator(showCoordinator)
    }
}
