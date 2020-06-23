//
//  ShowsService.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 05/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import CoreData
import UIKit
import Toolkit
import Promises

// todo: refactor data layer
final class ShowsService
{
    private let application: UIApplication
    private let storage: ShowStorage
    private let client: TheMovieDBClient
    private let imageCache: ImageCache

    private var cachedTrendingShows: [Show] = []

    init(application: UIApplication, storage: ShowStorage, client: TheMovieDBClient, imageCache: ImageCache) {
        self.application = application
        self.storage = storage
        self.client = client
        self.imageCache = imageCache
    }

    func preloadImages() {
        imageCache.warmUp()
    }

    @discardableResult
    func configure() -> Promise<Void> {
        return client.configure()
    }

    func search(query: String) -> Promise<[Show]> {
        return client.search(query: query)
    }

    func trending() -> Promise<[Show]> {
        guard cachedTrendingShows.isEmpty else {
            return Promise(value: cachedTrendingShows)
        }

        return client.trending()
            .then { shows -> [Show] in
                self.cachedTrendingShows = shows
                return shows
            }
    }

    func load(show: Show) -> Promise<Show> {
        return client.show(id: show.id, mode: .withFirstEpisodes)
    }

    func stillURL(for stillPath: String?) -> URL? {
        return client.imageURL(for: stillPath, size: .still)
    }

    func makeFetchedResultsController() -> NSFetchedResultsController<ShowEntity> {
        return storage.makeFetchedResultsController()
    }

    func add(show: Show) -> Promise<Show?> {
        var show = show
        show.isDummy = true
        show.isSoftDeleted = false

        return storage.create(show: show)
            .then { _ in self.add(id: show.id) }
            .then { _ in self.get(show: show, includingEpisodes: true) }
    }

    func get(show: Show, includingEpisodes: Bool = false) -> Promise<Show?> {
        return storage.get(show: show, includingEpisodes: includingEpisodes)
    }

    @discardableResult
    func delete(show: Show, soft: Bool = true) -> Promise<Show?> {
        if let posterURL = show.posterURL {
            imageCache.clear(for: posterURL)
        }

        if let backdropURL = show.backdropURL {
            imageCache.clear(for: backdropURL)
        }

        if soft {
            var show = show
            show.isSoftDeleted = true

            return storage.update(show: show)
                .then { _ in return show }
        } else {
            return storage.delete(show: show)
                .then { _ in return nil }
        }
    }

    @discardableResult
    func view(episode: Ref<Episode>, of show: Show, viewed: Bool = true) -> Show {
        guard episode.value.canView, episode.value.isViewed != viewed else {
            return show
        }

        episode.value.isViewed = viewed

        var show = show
        let delta = viewed ? 1 : -1

        show.numberOfViewedEpisodes =
            (delta + show.numberOfViewedEpisodes).clamped(to: 0...show.numberOfEpisodes)

        if let season = show.seasons.first(where: {
            $0.value.episodes.contains { $0 == episode }
        }) {
            season.value.numberOfViewedEpisodes =
                (delta + season.value.numberOfViewedEpisodes).clamped(to: 0...season.value.numberOfEpisodes)
        }

        storage.update(episode: episode.value)

        return show
    }

    func syncRunningShows() -> Promise<Int> {
        // get running shows from the local storage
        return storage.runningShows()
            .then { shows in
                self.fetchShowsWithNewEpisodes(shows)
            }
    }
}

extension ShowsService
{
    private func add(id: Int) -> Promise<Void> {
        application.isNetworkActivityIndicatorVisible = true

        return client
            .show(id: id, mode: .withEpisodesStartingFromSeason(1))
            .then { show in
                guard let posterURL = show.posterURL else {
                    return .void
                }

                self.imageCache.load(from: posterURL, persistent: true)

                if let backdropURL = show.backdropURL {
                    self.imageCache.load(from: backdropURL, persistent: true)
                }

                return self.storage.create(show: show)
            }
            .finally { self.application.isNetworkActivityIndicatorVisible = false }
    }

    private func fetchShowsWithNewEpisodes(_ shows: [Show]) -> Promise<Int> {
        let dispatchGroup = DispatchGroup()
        var totalNumberOfNewEpisodes = 0

        for show in shows {
            dispatchGroup.enter()

            // fetch each show from the remote API
            self.client.show(id: show.id, mode: .withoutEpisodes)
                .then { remoteShow in
                    // compare remote show and local show
                    guard remoteShow.numberOfEpisodes > show.numberOfEpisodes else {
                        dispatchGroup.leave()
                        return
                    }

                    // if remote show has new episodes,
                    // fetch them (starting from the last local season) and save to the local storage
                    self.client
                        .show(id: show.id,
                              mode: .withEpisodesStartingFromSeason(show.seasons.last?.value.number ?? 1))
                        .then { remoteShow in
                            var remoteShow = remoteShow
                            var overwriteCreationDate = false

                            let numberOfNewEpisodes = remoteShow.numberOfEpisodes - show.numberOfEpisodes
                            totalNumberOfNewEpisodes += numberOfNewEpisodes

                            // if show is finished or already has new episodes, increment its number of new episodes
                            if show.isFinished ?? false || show.numberOfNewEpisodes > 0 {
                                overwriteCreationDate = show.isFinished ?? false
                                remoteShow.numberOfNewEpisodes = show.numberOfNewEpisodes + numberOfNewEpisodes
                            }

                            self.storage.create(show: remoteShow,
                                                overwriteCreationDate: overwriteCreationDate)
                        }
                        .finally { dispatchGroup.leave() }
                }
        }

        return Promise<Int> { completion in
            dispatchGroup.notify(queue: .main) {
                completion(.success(totalNumberOfNewEpisodes))
            }
        }
    }
}
