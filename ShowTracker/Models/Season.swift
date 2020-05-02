//
//  Season.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 29/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import CoreData
import UIKit
import Toolkit

struct Season: Model, Identifiable
{
    var show: Ref<Show>?

    var id: Int
    var number: Int
    var name: String?
    var airDate: Date?
    var overview: String?
    var posterPath: String?
    var numberOfEpisodes: Int
    var numberOfViewedEpisodes: Int
    var episodes: [Ref<Episode>] = []

    var progress: Float {
        return numberOfEpisodes > 0
            ? Float(numberOfViewedEpisodes) / Float(numberOfEpisodes)
            : 0
    }

    init(from response: TheMovieDBClient.ShowResponse.Season, show: Ref<Show>?, includingEpisodes: Bool) {
        self.show = show

        id = response.id ?? 0
        number = response.seasonNumber ?? 0
        name = response.name
        airDate = response.airDate?.date()
        overview = response.overview
        posterPath = response.posterPath
        numberOfEpisodes = response.episodeCount ?? 0
        numberOfViewedEpisodes = 0

        guard includingEpisodes else {
            return
        }

        episodes = response.episodes?
            .map { Ref(value: Episode(from: $0, season: Ref(value: self))) }
            .filter { $0.value.number > 0 && $0.value.airDate ?? Date() < Date() }
            .sorted { $0.value.number < $1.value.number } ?? []

        numberOfEpisodes = !episodes.isEmpty ? episodes.count : numberOfEpisodes
    }

    init(from entity: SeasonEntity, show: Ref<Show>?, includingEpisodes: Bool) {
        self.show = show

        id = Int(entity.id)
        number = Int(entity.number)
        name = entity.name
        airDate = entity.airDate
        overview = entity.overview
        posterPath = entity.posterPath
        numberOfEpisodes = Int(entity.numberOfEpisodes)
        numberOfViewedEpisodes = Int(entity.numberOfViewedEpisodes)

        guard includingEpisodes else {
            return
        }

        episodes = (entity.episodes?.allObjects as? [EpisodeEntity])?
            .map { Ref(value: Episode(from: $0, season: Ref(value: self))) }
            .sorted { $0.value.number < $1.value.number } ?? []
    }

    @discardableResult
    func fill(entity: SeasonEntity, for context: NSManagedObjectContext) -> SeasonEntity {
        entity.id = Int64(id)
        entity.name = name
        entity.airDate = airDate
        entity.number = Int32(number)
        entity.overview = overview
        entity.posterPath = posterPath
        entity.numberOfEpisodes = Int32(numberOfEpisodes)
        entity.numberOfViewedEpisodes = Int32(numberOfViewedEpisodes)

        for episode in episodes {
            entity.addToEpisodes(episode.value.fill(entity: EpisodeEntity(context: context), for: context))
        }

        return entity
    }
}

extension Season
{
    init(from response: TheMovieDBClient.ShowResponse.Season) {
        self.init(from: response, show: nil, includingEpisodes: false)
    }

    init(from entity: SeasonEntity) {
        self.init(from: entity, show: nil, includingEpisodes: false)
    }
}

extension SeasonEntity: KeepingProperties
{
    public func shouldKeepProperty(_ property: String, databaseValue: Any?, contextValue: Any?) -> Bool {
        return [
            #keyPath(numberOfViewedEpisodes),
        ].contains(property)
    }
}
