//
//  ShowStorage.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 23/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Foundation
import CoreData
import Toolkit
import Promises

final class ShowStorage: Storage {
    func getRunningShows() -> Promise<[Show]> {
        return Promise { completion in
            let request = self.runningShowsFetchRequest()

            self.coreData.performBackgroundTask { context in
                do {
                    let showEntities = try context.fetch(request)
                    let shows = showEntities.map { Show(from: $0, includingEpisodes: false) }
                    completion(.success(shows))
                } catch {
                    assertionFailure("!!! ShowStorage: get running - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    func get(show: Show, includingEpisodes: Bool = false) -> Promise<Show?> {
        return Promise { completion in
            let request = self.showFetchRequest(for: show.id)

            self.coreData.performBackgroundTask { context in
                do {
                    guard let showEntity = try context.fetch(request).first else {
                        completion(.success(nil))
                        return
                    }

                    let show = Show(from: showEntity, includingEpisodes: includingEpisodes)
                    completion(.success(show))
                } catch {
                    assertionFailure("!!! ShowStorage: get show - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    func makeFetchedResultsController() -> NSFetchedResultsController<ShowEntity> {
        let request: NSFetchRequest = ShowEntity.fetchRequest()
        request.fetchBatchSize = 200
        request.predicate = NSPredicate(format: "%K = NO", argumentArray: [#keyPath(ShowEntity.isSoftDeleted)])

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ShowEntity.hasNewEpisodes, ascending: false),
            NSSortDescriptor(keyPath: \ShowEntity.isFinished, ascending: true),
            NSSortDescriptor(keyPath: \ShowEntity.creationDate, ascending: false),
        ]

        return NSFetchedResultsController<ShowEntity>(
            fetchRequest: request,
            managedObjectContext: coreData.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    // TODO: refactor this hell
    @discardableResult
    func create(show: Show, overwriteCreationDate: Bool = true) -> Promise<Void> {
        return Promise { completion in
            let create: (Show) -> Void = { show in
                self.coreData.performBackgroundTask { context in
                    context.mergePolicy = NSMergePolicy.conditionalPropertyOverwriting

                    do {
                        show.fill(entity: ShowEntity(context: context), for: context)
                        try context.save()
                        completion(.success)
                    } catch {
                        assertionFailure("!!! ShowStorage: create show - \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }

            let request = self.showFetchRequest(for: show.id)

            // workaround to calculate some show properties before creation if show already exists
            self.coreData.performBackgroundTask { context in
                do {
                    var show = show

                    if let showEntity = try context.fetch(request).first {
                        show.isFinished = showEntity.numberOfViewedEpisodes == show.numberOfEpisodes

                        if !overwriteCreationDate {
                            show.creationDate = showEntity.creationDate
                        }
                    }

                    create(show)
                } catch {
                    assertionFailure("!!! ShowStorage: create show - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    func delete(show: Show) -> Promise<Void> {
        return Promise { completion in
            let request = self.showFetchRequest(for: show.id)

            self.coreData.performBackgroundTask { context in
                do {
                    if let showEntity = try context.fetch(request).first {
                        context.delete(showEntity)
                        try context.save()
                    }

                    completion(.success)
                } catch {
                    assertionFailure("!!! ShowStorage: delete show - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    func update(show: Show) -> Promise<Void> {
        return Promise { completion in
            let request = self.showFetchRequest(for: show.id)

            self.coreData.performBackgroundTask { context in
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

                do {
                    if let showEntity = try context.fetch(request).first {
                        show.propagate(entity: showEntity, for: context)
                        try context.save()
                    }

                    completion(.success)
                } catch {
                    assertionFailure("!!! ShowStorage: update show - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    // TODO: refactor this hell
    @discardableResult
    func update(episode: Episode) -> Promise<Void> {
        return Promise { completion in
            let request = self.episodeFetchRequest(for: episode.id)

            self.coreData.performBackgroundTask { context in
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

                do {
                    if let episodeEntity = try context.fetch(request).first,
                        let seasonEntity = episodeEntity.season,
                        let showEntity = seasonEntity.show
                    {
                        var episode = episode

                        // consistency management
                        if let isViewed = episode.isViewed, isViewed != episodeEntity.isViewed {
                            seasonEntity.numberOfViewedEpisodes =
                                ((isViewed ? 1 : -1) + seasonEntity.numberOfViewedEpisodes)
                                .clamped(to: 0...seasonEntity.numberOfEpisodes)

                            showEntity.numberOfViewedEpisodes =
                                ((isViewed ? 1 : -1) + showEntity.numberOfViewedEpisodes)
                                .clamped(to: 0...showEntity.numberOfEpisodes)

                            if isViewed && episode.isNew ?? false {
                                showEntity.numberOfNewEpisodes = max(0, showEntity.numberOfNewEpisodes - 1)
                                showEntity.hasNewEpisodes = showEntity.numberOfNewEpisodes > 0
                                episode.isNew = false
                            }

                            showEntity.isFinished = showEntity.numberOfViewedEpisodes == showEntity.numberOfEpisodes
                        }

                        episode.propagate(entity: episodeEntity, for: context)
                        try context.save()
                    }

                    completion(.success)
                } catch {
                    assertionFailure("!!! ShowStorage: update episode - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    private func showFetchRequest(for id: Int) -> NSFetchRequest<ShowEntity> {
        let request: NSFetchRequest = ShowEntity.fetchRequest()
        request.fetchLimit = 1

        request.predicate = NSPredicate(format: "%K = %d", argumentArray: [
            #keyPath(ShowEntity.id),
            id,
        ])

        return request
    }

    private func episodeFetchRequest(for id: Int) -> NSFetchRequest<EpisodeEntity> {
        let request: NSFetchRequest = EpisodeEntity.fetchRequest()
        request.fetchLimit = 1

        request.predicate = NSPredicate(format: "%K = %d", argumentArray: [
            #keyPath(EpisodeEntity.id),
            id,
        ])

        return request
    }

    private func runningShowsFetchRequest() -> NSFetchRequest<ShowEntity> {
        let request: NSFetchRequest = ShowEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "%K = NO AND %K = YES AND (%K == nil OR %K <= %@)",
            argumentArray: [
                #keyPath(ShowEntity.isSoftDeleted),
                #keyPath(ShowEntity.inProduction),
                #keyPath(ShowEntity.nextEpisodeAirDate),
                #keyPath(ShowEntity.nextEpisodeAirDate),
                Calendar.current.startOfDay(for: Date()),
            ]
        )

        return request
    }
}
