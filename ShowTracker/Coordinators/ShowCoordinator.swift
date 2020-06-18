//
//  ShowCoordinator.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 30/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit
import Promises

final class ShowCoordinator
{
    var model: Show?

    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

    private let services: ServiceContainer
    private let numberOfPreloadedEpisodes = 2

    private var isShowAlreadyExists: Bool? {
        get { return showViewController?.isShowAlreadyExists }
        set { showViewController?.isShowAlreadyExists = newValue }
    }

    private weak var showViewController: ShowViewController? {
        didSet {
            showViewController?.delegate = self
            showViewController?.episodesCollectionViewDelegate = self
            showViewController?.episodesCollectionViewDataSource = self
        }
    }

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

    static func makeViewController(with model: Show?, services: ServiceContainer) -> ShowViewController {
        let coordinator = ShowCoordinator(services: services)
        coordinator.model = model

        let viewController = ShowViewController(coordinator: coordinator)

        return viewController
    }

    func didLoadView(_ viewController: ShowViewController) {
        showViewController = viewController
        setModel(model, fullTableReload: true)
    }

    func viewDidAppear() {
        actualizeModel()
    }

    func actualizeModel() {
        guard let show = model else {
            return
        }

        isShowAlreadyExists = nil

        services.shows.get(show: show, includingEpisodes: true)
            .then { [weak self] existingShow in
                if let existingShow = existingShow {
                    self?.isShowAlreadyExists = existingShow.isSoftDeleted == false
                    self?.setModel(existingShow, fullTableReload: true, animated: true)
                } else {
                    self?.services.shows.load(show: show)
                        .then { remoteShow in
                            self?.isShowAlreadyExists = false
                            self?.setModel(remoteShow, fullTableReload: true, animated: true)
                        }
                }
            }
    }
}

extension ShowCoordinator: ShowViewControllerDelegate
{
    func didTapAddButton(in showViewController: ShowViewController) {
        addShow()
    }

    func didTapDeleteButton(in showViewController: ShowViewController) {
        guard let show = model else {
            return
        }

        isShowAlreadyExists = nil

        services.shows.delete(show: show)
            .then { [weak self] deletedShow in
                self?.isShowAlreadyExists = false
                self?.setModel(deletedShow, animated: true)
            }
    }

    func didTapViewSeasonButton(in showViewController: ShowViewController, show: Show, season: Season) {
        let viewSeason = { [weak self] in
            season.episodes.forEach { self?.services.shows.view(episode: $0, of: show) }
            self?.actualizeModel()
        }

        if isShowAlreadyExists == false {
            addShow().then { _ in viewSeason() }
        } else {
            viewSeason()
        }
    }

    func didTapUnseeSeasonButton(in showViewController: ShowViewController, show: Show, season: Season) {
        season.episodes.forEach { services.shows.view(episode: $0, of: show, viewed: false) }
        actualizeModel()
    }
}

extension ShowCoordinator: EpisodesCollectionViewDelegate
{
    func episodesCollectionView(_ episodesCollectionView: EpisodesCollectionView,
                                didScrollFrom page: Int,
                                to newPage: Int)
    {
        let index = newPage > page ? page : newPage

        guard let episode = model?.episodes[at: index] else {
            return
        }

        let viewShow = { [weak self] in
            guard let show = self?.model, let episode = show.episodes[at: index] else {
                return
            }

            let updatedShow = self?.services.shows.view(episode: episode, of: show, viewed: newPage > page)
            self?.setModel(updatedShow, animated: true)
        }

        if isShowAlreadyExists == false, newPage > page, episode.value.isViewed != true {
            addShow().then { _ in viewShow() }
        } else if isShowAlreadyExists == true {
            viewShow()
        }
    }

    func initialPageIndex(in episodesCollectionView: EpisodesCollectionView) -> Int? {
        guard let lastViewedEpisodeIndex = model?.lastViewedEpisodeIndex else {
            return 0
        }

        return lastViewedEpisodeIndex + 1
    }
}

extension ShowCoordinator: EpisodesCollectionViewDataSource
{
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

extension ShowCoordinator
{
    @discardableResult
    private func addShow() -> Promise<Void> {
        guard let show = model else {
            return .void
        }

        isShowAlreadyExists = nil

        return services.shows.add(show: show)
            .then { [weak self] show -> Void in
                self?.isShowAlreadyExists = show != nil
                self?.setModel(show, animated: true)
                self?.notificationFeedbackGenerator.notificationOccurred(show == nil ? .error : .success)
            }
    }

    private func setModel(_ show: Show?, fullTableReload: Bool = false, animated: Bool = false) {
        model = show
        showViewController?.setModel(show, fullTableReload: fullTableReload, animated: animated)
    }
}
