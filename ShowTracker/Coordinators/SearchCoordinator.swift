//
//  SearchCoordinator.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 14/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

final class SearchCoordinator
{
    private weak var searchViewController: SearchViewController? {
        didSet {
            searchViewController?.delegate = self
            searchViewController?.showsCollectionViewDelegate = self
            searchViewController?.showsCollectionViewDataSource = self
        }
    }

    private lazy var debouncedSearchRequest = debounce(0.67) { [weak self] (query: String) in
        guard query == self?.searchViewController?.searchQuery else {
            self?.searchViewController?.stopActivityIndicator()
            return
        }

        self?.services.shows.search(query: query)
            .then { shows in
                guard query == self?.searchViewController?.searchQuery else {
                    return
                }

                self?.shows = shows
                self?.query = query
            }
            .finally { self?.searchViewController?.stopActivityIndicator() }
    }

    private let services: ServiceContainer
    private var query: String?

    private var shows: [Show] = [] {
        didSet {
            guard shows != oldValue else {
                return
            }

            searchViewController?.reloadShows()
        }
    }

    init(services: ServiceContainer) {
        self.services = services
    }

    static func makeViewController(with services: ServiceContainer) -> SearchViewController {
        let coordinator = SearchCoordinator(services: services)
        let viewController = SearchViewController(coordinator: coordinator)
        return viewController
    }

    func didLoadView(_ viewController: SearchViewController) {
        searchViewController = viewController

        loadTrendingShows()
    }
}

extension SearchCoordinator: SearchViewControllerDelegate
{
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

extension SearchCoordinator: ShowsCollectionViewDelegate
{
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView,
                             didTapOn cell: ShowCollectionViewCell,
                             at index: Int)
    {
        let showViewController = ShowCoordinator.makeViewController(with: shows[at: index], services: services)
        searchViewController?.animatedSubviews = [cell.posterImageView]
        searchViewController?.hideKeyboard()
        searchViewController?.present(showViewController, animated: true)
    }
}

extension SearchCoordinator: ShowsCollectionViewDataSource
{
    func numberOfItems(in showsCollectionView: ShowsCollectionView) -> Int {
        return shows.count
    }

    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, showForItemAt index: Int) -> Show {
        return shows[index]
    }
}

extension SearchCoordinator
{
    private func clearSearchResults() {
        shows = []
        query = nil
    }

    private func loadTrendingShows() {
        searchViewController?.startActivityIndicator()

        self.services.shows.trending()
            .then { [weak self] shows in
                self?.shows = shows
                self?.query = nil
            }
            .finally { [weak self] in
                self?.searchViewController?.stopActivityIndicator()
            }
    }
}
