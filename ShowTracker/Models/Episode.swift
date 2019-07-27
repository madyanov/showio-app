//
//  Episode.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 13/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import CoreData
import Toolkit

struct Episode: Model, Identifiable
{
    var season: Ref<Season>?

    var id: Int
    var seasonNumber: Int
    var number: Int
    var name: String?
    var airDate: Date?
    var overview: String?
    var stillPath: String?
    var stillURL: URL?
    var isViewed: Bool?
    var isNew: Bool?

    var show: Ref<Show>? {
        return season?.value.show
    }

    var canView: Bool {
        if let airDate = airDate {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let airDay = calendar.startOfDay(for: airDate)
            return today >= airDay
        }

        return true
    }

    var localizedAirDate: String? {
        guard let airDate = airDate else {
            return nil
        }

        let calendar = Calendar.current
        let airDay = calendar.startOfDay(for: airDate)
        let today = calendar.startOfDay(for: Date())

        if calendar.isDateInYesterday(airDay) {
            return "Aired yesterday".localized(comment: "Air date is yesterday")
        } else if calendar.isDateInToday(airDay) {
            return "Airs today".localized(comment: "Air date is today")
        } else if calendar.isDateInTomorrow(airDay) {
            return "Airs tomorrow".localized(comment: "Air date is tomorrow")
        } else if airDay < today {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
            dateFormatter.doesRelativeDateFormatting = true
            let formattedDate = dateFormatter.string(from: airDate)

            return "Aired on %@".localized(comment: "Air date is in past", formattedDate)
        } else {
            return "Airs in %d days"
                .localized(comment: "Air date is in future after %d days", airDate.days(since: today) ?? 0)
        }
    }

    init(from response: TheMovieDBClient.ShowResponse.Episode, season: Ref<Season>?) {
        self.season = season

        id = response.id ?? 0
        seasonNumber = response.seasonNumber ?? 0
        number = response.episodeNumber ?? 0
        name = response.name
        airDate = response.airDate?.date()
        overview = response.overview
        stillPath = response.stillPath
    }

    init(from entity: EpisodeEntity, season: Ref<Season>?) {
        self.season = season

        id = Int(entity.id)
        seasonNumber = Int(entity.seasonNumber)
        number = Int(entity.number)
        name = entity.name
        airDate = entity.airDate
        overview = entity.overview
        stillPath = entity.stillPath
        isViewed = entity.isViewed
        isNew = entity.isNew
    }

    @discardableResult
    func fill(entity: EpisodeEntity, for context: NSManagedObjectContext) -> EpisodeEntity {
        entity.id = Int64(id)
        entity.seasonNumber = Int32(seasonNumber)
        entity.name = name
        entity.airDate = airDate
        entity.number = Int32(number)
        entity.overview = overview
        entity.stillPath = stillPath
        entity.isViewed = isViewed ?? false
        entity.isNew = isNew ?? true
        return entity
    }
}

extension Episode
{
    init(from response: TheMovieDBClient.ShowResponse.Episode) {
        self.init(from: response, season: nil)
    }

    init(from entity: EpisodeEntity) {
        self.init(from: entity, season: nil)
    }
}

extension EpisodeEntity: KeepingProperties
{
    public func shouldKeepProperty(_ property: String, databaseValue: Any?, contextValue: Any?) -> Bool {
        return [
            #keyPath(isViewed),
            #keyPath(isNew),
        ].contains(property)
    }
}
