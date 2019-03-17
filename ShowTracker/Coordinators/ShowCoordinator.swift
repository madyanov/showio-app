//
//  ShowCoordinator.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 30/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Foundation
import UIKit
import Toolkit
import Promises

protocol ShowCoordinatorDelegate: AnyObject {
    func didClose(_ showCoordinator: ShowCoordinator)
}

class ShowCoordinator: Coordinator {
    weak var delegate: ShowCoordinatorDelegate?

    var childCoordinators: [Coordinator] = []

    var viewController: UIViewController {
        return showViewController
    }

    var model: Show? {
        get { return showViewController.model }
        set { showViewController.setModel(newValue, fullTableReload: true) }
    }

    private let services: ServiceContainer
    private let numberOfPreloadedEpisodes = 2

    private var isShowAlreadyExists: Bool? {
        get { return showViewController.isShowAlreadyExists }
        set { showViewController.isShowAlreadyExists = newValue }
    }

    private lazy var showTransitionAnimator = ShowTransitionAnimator()

    private lazy var showViewController: ShowViewController = {
        let showViewController = ShowViewController()
        showViewController.delegate = self
        showViewController.episodesCollectionViewDelegate = self
        showViewController.episodesCollectionViewDataSource = self
        showViewController.transitioningDelegate = showTransitionAnimator
        showViewController.modalPresentationStyle = .custom
        showViewController.modalPresentationCapturesStatusBarAppearance = true
        return showViewController
    }()

    private var episodesCollectionViewEndingItemStyle: EndingCollectionViewCell.Style? {
        guard let show = model, let lastEpisode = show.episodes.last?.value else {
            return nil
        }

        if show.isDummy != true && show.isSaved != true && show.numberOfEpisodes > numberOfPreloadedEpisodes {
            return .loading
        } else if show.inProduction ?? false {
            return .pending(show.localizedNextEpisodeAirDate)
        } else if lastEpisode.canView {
            return .finished
        }

        return nil
    }

    init(services: ServiceContainer) {
        self.services = services
    }

    func actualizeModel() {
        guard let show = model else {
            return
        }

        self.isShowAlreadyExists = nil

        services.shows.get(show: show, includingEpisodes: true)
            .then { existingShow in
                if let existingShow = existingShow {
                    self.isShowAlreadyExists = existingShow.isSoftDeleted == false
                    self.showViewController.setModel(existingShow, fullTableReload: true, animated: true)
                } else {
                    self.services.shows.load(show: show)
                        .then { remoteShow in
                            self.isShowAlreadyExists = false
                            self.showViewController.setModel(remoteShow, fullTableReload: true, animated: true)
                        }
                }
            }
    }

    @discardableResult
    private func addShow() -> Promise<Void> {
        guard let show = model else {
            return Promise(value: ())
        }

        isShowAlreadyExists = nil

        return services.shows.add(show: show)
            .then { show -> Void in
                self.isShowAlreadyExists = show != nil
                self.showViewController.setModel(show, animated: true)
            }
    }
}

extension ShowCoordinator: ShowViewControllerDelegate {
    func didDisappear(_ showViewConntroller: ShowViewController) {
        delegate?.didClose(self)
    }

    func didTapAddButton(in showViewController: ShowViewController) {
        addShow()
    }

    func didTapDeleteButton(in showViewController: ShowViewController) {
        guard let show = model else {
            return
        }

        isShowAlreadyExists = nil

        services.shows.delete(show: show)
            .then { deletedShow in
                self.isShowAlreadyExists = false
                self.showViewController.setModel(deletedShow, animated: true)
            }
    }
}

extension ShowCoordinator: EpisodesCollectionViewDelegate {
    func episodesCollectionView(_ episodesCollectionView: EpisodesCollectionView,
                                didScrollFrom page: Int,
                                to newPage: Int)
    {
        let index = newPage > page ? page : newPage

        guard let episode = model?.episodes[at: index] else {
            return
        }

        let viewShow = {
            guard let show = self.model, let episode = show.episodes[at: index] else {
                return
            }

            let updatedShow = self.services.shows.view(episode: episode, of: show, viewed: newPage > page)
            self.showViewController.setModel(updatedShow, animated: true)
        }

        if isShowAlreadyExists == false, newPage > page, episode.value.isViewed != true {
            addShow().then { _ in viewShow() }
        } else if isShowAlreadyExists == true {
            viewShow()
        }
    }

    func initialPageIndex(in episodesCollectionView: EpisodesCollectionView) -> Int? {
        guard let lastViewedEpisodeIndex = model?.lastViewedEpisodeIndex else {
            return nil
        }

        return lastViewedEpisodeIndex + 1
    }
}

extension ShowCoordinator: EpisodesCollectionViewDataSource {
    func shouldAppendEndingItem(in episodesCollectionView: EpisodesCollectionView) -> Bool {
        return episodesCollectionViewEndingItemStyle != nil
    }

    func endingItemStyle(in episodeCollectionView: EpisodesCollectionView) -> EndingCollectionViewCell.Style {
        return episodesCollectionViewEndingItemStyle ?? .loading
    }

    func numberOfItems(in episodesCollectionView: EpisodesCollectionView) -> Int {
        if case .loading? = episodesCollectionViewEndingItemStyle {
            return min(model?.episodes.count ?? 0, numberOfPreloadedEpisodes)
        }

        return model?.episodes.count ?? 0
    }

    func episodesCollectionView(_ episodesCollectionView: EpisodesCollectionView,
                                episodeForItemAt index: Int) -> Episode
    {
        let episodes = model?.episodes ?? []
        var episode = episodes[index].value
        episode.stillURL = services.shows.stillURL(for: episode.stillPath)
        return episode
    }
}
