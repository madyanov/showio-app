//
//  Show.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 23/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import CoreData
import UIKit
import Toolkit

struct Show: Model, Identifiable
{
    var id: Int
    var objectID: NSManagedObjectID?
    var originalName: String
    var name: String
    var overview: String?
    var posterURL: URL?
    var backdropURL: URL?
    var firstAirDate: Date?
    var episodeRunTime: Int
    var rating: Double
    var inProduction: Bool?
    var lastAirDate: Date?
    var nextEpisodeAirDate: Date?
    var network: String?
    var country: String?
    var genres: [String] = []
    var isDummy: Bool?
    var isSoftDeleted: Bool?
    var numberOfSeasons: Int
    var numberOfViewedEpisodes: Int
    var numberOfEpisodes: Int
    var episodes: [Ref<Episode>] = []
    var isSaved: Bool?
    var numberOfNewEpisodes: Int
    var isFinished: Bool?
    var creationDate: Date?

    var seasons: [Ref<Season>] = [] {
        didSet {
            guard !seasons.isEmpty else {
                return
            }

            episodes = seasons
                .reduce([]) { episodes, season in
                    return episodes + season.value.episodes
                }
                .sorted {
                    if $0.value.seasonNumber != $1.value.seasonNumber {
                        return $0.value.seasonNumber < $1.value.seasonNumber
                    } else {
                        return $0.value.number < $1.value.number
                    }
                }

            numberOfSeasons = seasons.count
            numberOfEpisodes = seasons.reduce(0) { $0 + $1.value.numberOfEpisodes }
        }
    }

    var lastViewedEpisodeIndex: Int? {
        return episodes.lastIndex { $0.value.isViewed ?? false }
    }

    var progress: Float {
        return numberOfEpisodes > 0
            ? Float(numberOfViewedEpisodes) / Float(numberOfEpisodes)
            : 0
    }

    var year: String? {
        guard let firstAirYear = firstAirDate?.year else {
            return nil
        }

        if inProduction == true {
            return "%@ · Running".localized(comment: "Running show year", firstAirYear)
        } else if inProduction == false {
            return "%@ · Ended".localized(comment: "Ended show year", firstAirYear)
        } else {
            return firstAirYear
        }
    }

    var genre: String? {
        return genres.first?.components(separatedBy: " ").first
    }

    var localizedNextEpisodeAirDate: String? {
        guard let nextEpisodeAirDate = nextEpisodeAirDate else {
            return "Next episode air date is unknown :(".localized(comment: "Next episode air date is unknown")
        }

        let calendar = Calendar.current
        let nextEpisodeAirDay = calendar.startOfDay(for: nextEpisodeAirDate)
        let today = calendar.startOfDay(for: Date())
        let days = nextEpisodeAirDay.days(since: today) ?? 0

        guard days > 0 else {
            return nil
        }

        if days == 1 {
            return "Next episode airs tomorrow".localized(comment: "Air date for next episode is tomorrow")
        } else {
            return "Next episode airs in %d days".localized(comment: "Air date for next episode after %d days", days)
        }
    }

    init(from response: TheMovieDBClient.ShowResponse,
         includingEpisodes: Bool,
         posterURL: URL?,
         backdropURL: URL?)
    {
        id = response.id ?? 0
        originalName = response.originalName ?? ""
        name = response.name ?? ""
        overview = response.overview
        episodeRunTime = response.episodeRunTime?.first ?? 0
        rating = response.voteCount ?? 0 > 10 ? response.voteAverage ?? 0 : 0
        firstAirDate = response.firstAirDate?.date()
        inProduction = response.inProduction
        lastAirDate = response.lastAirDate?.date()
        nextEpisodeAirDate = response.nextEpisodeToAir?.airDate?.date()
        network = response.networks?.first?.name
        country = response.originCountry?.first
        numberOfSeasons = response.numberOfSeasons ?? 0
        numberOfEpisodes = response.numberOfEpisodes ?? 0
        numberOfViewedEpisodes = 0
        numberOfNewEpisodes = 0

        self.posterURL = posterURL
        self.backdropURL = backdropURL

        genres = response.genres?
            .sorted { $0.id ?? 0 < $1.id ?? 0 }
            .compactMap { $0.name?.capitalizingFirstLetter } ?? []

        ({
            let fullSeasons = response.seasonProperties

            seasons = response.seasons?
                .compactMap { shortSeason in
                    guard shortSeason.episodeCount ?? 0 > 0 else {
                        return nil
                    }

                    var fullSeason = fullSeasons.first { $0.seasonNumber == shortSeason.seasonNumber }
                    fullSeason?.id = shortSeason.id

                    return Ref(value: Season(from: fullSeason ?? shortSeason,
                                             show: Ref(value: self),
                                             includingEpisodes: includingEpisodes))
                }
                .filter { $0.value.number > 0 && $0.value.airDate ?? Date() < Date() }
                .sorted { $0.value.number < $1.value.number } ?? []
        })()
    }

    init(from entity: ShowEntity, includingEpisodes: Bool) {
        id = Int(entity.id)
        objectID = entity.objectID
        originalName = entity.originalName ?? ""
        name = entity.name ?? ""
        overview = entity.overview
        posterURL = URL(string: entity.posterURL ?? "")
        backdropURL = URL(string: entity.backdropURL ?? "")
        firstAirDate = entity.firstAirDate
        episodeRunTime = Int(entity.episodeRunTime)
        rating = entity.rating
        inProduction = entity.inProduction
        lastAirDate = entity.lastAirDate
        nextEpisodeAirDate = entity.nextEpisodeAirDate
        network = entity.network
        country = entity.country
        genres = entity.genres ?? []
        isDummy = entity.isDummy
        isSoftDeleted = entity.isSoftDeleted
        numberOfSeasons = Int(entity.numberOfSeasons)
        numberOfEpisodes = Int(entity.numberOfEpisodes)
        numberOfViewedEpisodes = Int(entity.numberOfViewedEpisodes)
        numberOfNewEpisodes = Int(entity.numberOfNewEpisodes)
        isFinished = entity.isFinished
        isSaved = true

        ({
            seasons = (entity.seasons?.allObjects as? [SeasonEntity])?
                .map { Ref(value: Season(from: $0, show: Ref(value: self), includingEpisodes: includingEpisodes)) }
                .sorted { $0.value.number < $1.value.number } ?? []
        })()
    }

    @discardableResult
    func fill(entity: ShowEntity, for context: NSManagedObjectContext) -> ShowEntity {
        entity.id = Int64(id)
        entity.originalName = originalName
        entity.name = name
        entity.overview = overview
        entity.posterURL = posterURL?.absoluteString
        entity.backdropURL = backdropURL?.absoluteString
        entity.firstAirDate = firstAirDate
        entity.episodeRunTime = Int32(episodeRunTime)
        entity.creationDate = creationDate ?? Date()
        entity.rating = rating
        entity.inProduction = inProduction ?? false
        entity.lastAirDate = lastAirDate
        entity.nextEpisodeAirDate = nextEpisodeAirDate
        entity.network = network
        entity.country = country
        entity.genres = genres
        entity.isDummy = isDummy ?? false
        entity.isSoftDeleted = isSoftDeleted ?? false
        entity.numberOfSeasons = Int32(numberOfSeasons)
        entity.numberOfEpisodes = Int32(numberOfEpisodes)
        entity.numberOfViewedEpisodes = Int32(numberOfViewedEpisodes)
        entity.numberOfNewEpisodes = Int32(numberOfNewEpisodes)
        entity.isFinished = isFinished ?? false
        entity.hasNewEpisodes = numberOfNewEpisodes > 0

        for season in seasons {
            entity.addToSeasons(season.value.fill(entity: SeasonEntity(context: context), for: context))
        }

        return entity
    }

    mutating func merge(_ show: Show) {
        let fullSeasons = seasons.filter { !$0.value.episodes.isEmpty } +
            show.seasons.filter { !$0.value.episodes.isEmpty }

        seasons = fullSeasons + show.seasons.filter { season in
            return !fullSeasons.contains { $0 == season }
        }
    }
}

extension Show
{
    init(from response: TheMovieDBClient.ShowResponse) {
        self.init(from: response, includingEpisodes: false, posterURL: nil, backdropURL: nil)
    }

    init(from entity: ShowEntity) {
        self.init(from: entity, includingEpisodes: false)
    }
}

extension ShowEntity: KeepingProperties
{
    public func shouldKeepProperty(_ property: String, databaseValue: Any?, contextValue: Any?) -> Bool {
        return [
            #keyPath(numberOfViewedEpisodes),
        ].contains(property)
    }
}
