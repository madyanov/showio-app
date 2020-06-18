//
//  TheMovieDBClient.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 23/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Foundation
import Toolkit
import Promises

final class TheMovieDBClient
{
    enum ShowRequestMode
    {
        case withoutEpisodes
        case withFirstEpisodes
        case withEpisodesStartingFromSeason(Int)
    }

    struct ImageSize
    {
        static let poster = ImageSize("w300")
        static let backdrop = ImageSize("w780")
        static let still = ImageSize("w780")

        let name: String

        init(_ name: String) {
            self.name = name
        }
    }

    enum Error: Swift.Error
    {
        case invalidURL
        case network(Swift.Error)
        case http(Int)
        case invalidResponse
        case format(Swift.Error)
        case validation(String)
    }

    struct CodingKey: Swift.CodingKey
    {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    struct ShowResponse: Codable
    {
        struct Genre: Codable
        {
            var id: Int?
            var name: String?
        }

        struct Network: Codable
        {
            var name: String?
        }

        struct Episode: Codable
        {
            var id: Int?
            var seasonNumber: Int?
            var episodeNumber: Int?
            var name: String?
            var airDate: String?
            var overview: String?
            var stillPath: String?
        }

        struct Season: Codable
        {
            var id: Int?
            var seasonNumber: Int?
            var name: String?
            var airDate: String?
            var overview: String?
            var posterPath: String?
            var episodeCount: Int?
            var episodes: [Episode]?
        }

        var id: Int?
        var originalName: String?
        var name: String?
        var overview: String?
        var posterPath: String?
        var backdropPath: String?
        var firstAirDate: String?
        var popularity: Double?
        var voteCount: Int?
        var voteAverage: Double?
        var episodeRunTime: [Int]?
        var inProduction: Bool?
        var numberOfSeasons: Int?
        var numberOfEpisodes: Int?
        var lastAirDate: String?
        var originCountry: [String]?
        var nextEpisodeToAir: Episode?
        var networks: [Network]?
        var genres: [Genre]?
        var seasons: [Season]?

        // workaround to get all episodes T_T
        var season1: Season?, season2: Season?, season3: Season?, season4: Season?, season5: Season?
        var season6: Season?, season7: Season?, season8: Season?, season9: Season?, season10: Season?
        var season11: Season?, season12: Season?, season13: Season?, season14: Season?, season15: Season?
        var season16: Season?, season17: Season?, season18: Season?, season19: Season?, season20: Season?
        var season21: Season?, season22: Season?, season23: Season?, season24: Season?, season25: Season?
        var season26: Season?, season27: Season?, season28: Season?, season29: Season?, season30: Season?
        var season31: Season?, season32: Season?, season33: Season?, season34: Season?, season35: Season?
        var season36: Season?, season37: Season?, season38: Season?, season39: Season?, season40: Season?
        var season41: Season?, season42: Season?, season43: Season?, season44: Season?, season45: Season?
        var season46: Season?, season47: Season?, season48: Season?, season49: Season?, season50: Season?
        var season51: Season?, season52: Season?, season53: Season?, season54: Season?, season55: Season?
        var season56: Season?, season57: Season?, season58: Season?, season59: Season?, season60: Season?
        var season61: Season?, season62: Season?, season63: Season?, season64: Season?, season65: Season?
        var season66: Season?, season67: Season?, season68: Season?, season69: Season?, season70: Season?
        var season71: Season?, season72: Season?, season73: Season?, season74: Season?, season75: Season?
        var season76: Season?, season77: Season?, season78: Season?, season79: Season?, season80: Season?
        var season81: Season?, season82: Season?, season83: Season?, season84: Season?, season85: Season?
        var season86: Season?, season87: Season?, season88: Season?, season89: Season?, season90: Season?
        var season91: Season?, season92: Season?, season93: Season?, season94: Season?, season95: Season?
        var season96: Season?, season97: Season?, season98: Season?, season99: Season?, season100: Season?

        var seasonProperties: [Season] {
            let mirror = Mirror(reflecting: self)

            return mirror.children.compactMap { property, value in
                guard property?.hasPrefix("season") ?? false, let season = value as? Season else {
                    return nil
                }

                return season
            }
        }
    }

    struct SearchResponse: Codable
    {
        var results: [ShowResponse]?
    }

    private struct ConfigurationResponse: Codable
    {
        struct Images: Codable
        {
            var secureBaseUrl: String
        }

        var images: Images
    }

    static let defaultLanguage = "en"

    var endpoint = "https://api.themoviedb.org/3/"
    var language = Locale.preferredLanguages.first ?? Locale.current.languageCode ?? defaultLanguage
    var timeout: TimeInterval = 60

    private let maximumNumberOfSeasons = 20

    private var apiKey: String
    private var configuration: ConfigurationResponse?

    private var secureBaseURL: String {
        return configuration?.images.secureBaseUrl ?? "https://image.tmdb.org/t/p/"
    }

    private var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        return .custom { keys in
            let last = keys.last?.stringValue
                .lowercased()
                .replacingOccurrences(of: "(\\w)_(\\w)", with: "$1 $2", options: .regularExpression)
                .replacingOccurrences(of: "/", with: " ")
                .split(separator: " ")
                .enumerated()
                .map { $0.offset > 0 ? $0.element.capitalized : String($0.element) }
                .joined() ?? ""

            // swiftlint:disable:next force_unwrapping
            return CodingKey(stringValue: last)!
        }
    }

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func configure() -> Promise<Void> {
        guard configuration == nil else {
            return .void
        }

        return request(path: "configuration", type: ConfigurationResponse.self)
            .then { self.configuration = $0 }
    }

    func search(query: String, limit: Int = 100) -> Promise<[Show]> {
        return configure()
            .then { _ in
                return self.request(path: "search/tv",
                                    type: SearchResponse.self,
                                    parameters: ["query": query])
            }
            .then { self.map($0.results ?? [], limit: limit) }
    }

    func trending(limit: Int = 100) -> Promise<[Show]> {
        return configure()
            .then { _ in self.request(path: "trending/tv/day", type: SearchResponse.self) }
            .then { self.map($0.results ?? [], limit: limit) }
    }

    func show(id: Int, mode: ShowRequestMode) -> Promise<Show> {
        let request: ([Int]) -> Promise<Show> = { seasons in
            let append = seasons
                .map { "season/\($0)" }
                .joined(separator: ",")

            let parameters = ["append_to_response": append]

            return self.request(path: "tv/\(id)", type: ShowResponse.self, parameters: parameters)
                .then { show -> Show in
                    guard self.validate(show: show) else {
                        throw Error.validation("show validation error")
                    }

                    return self.show(from: show, includingEpisodes: true)
                }
        }

        var seasons: [Int] = []

        switch mode {
        case .withFirstEpisodes:
            seasons = [1, 2]
        case .withEpisodesStartingFromSeason(let fromSeason):
            seasons = Array(fromSeason...fromSeason + maximumNumberOfSeasons - 1)
        default:
            seasons = []
        }

        return request(seasons)
            .then { show in
                var show = show
                let dispatchGroup = DispatchGroup()

                if case .withEpisodesStartingFromSeason(var fromSeason) = mode {
                    fromSeason += self.maximumNumberOfSeasons

                    for season in stride(from: fromSeason, to: show.seasons.count, by: self.maximumNumberOfSeasons) {
                        let seasons = Array(season...season + self.maximumNumberOfSeasons - 1)

                        dispatchGroup.enter()

                        request(seasons)
                            .then { show.merge($0) }
                            .finally { dispatchGroup.leave() }
                    }
                }

                return Promise { completion in
                    dispatchGroup.notify(queue: .main) {
                        completion(.success(show))
                    }
                }
            }
    }

    func imageURL(for path: String?, size: ImageSize) -> URL? {
        guard let path = path, !path.isEmpty else {
            return nil
        }

        return URL(string: secureBaseURL + size.name + path)
    }
}

extension TheMovieDBClient
{
    private func request<T: Codable>(path: String,
                                     type: T.Type,
                                     parameters: [String: String] = [:]) -> Promise<T>
    {
        guard let url = endpoint(path: path, parameters: parameters) else {
            assertionFailure("!!! TMDBAPI: \(path) - invalid URL")
            return Promise(error: Error.invalidURL)
        }

        let urlRequest = URLRequest(url: url,
                                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                    timeoutInterval: timeout)

        return Promise { completion in
            URLSession.shared
                .dataTask(with: urlRequest) { data, urlResponse, error in
                    if let error = error {
                        print("!!! TMDBAPI: \(path) - \(error.localizedDescription)")
                        completion(.failure(Error.network(error)))
                        return
                    }

                    if let httpURLResponse = urlResponse as? HTTPURLResponse,
                        httpURLResponse.statusCode < 200 || httpURLResponse.statusCode >= 300
                    {
                        print("!!! TMDBAPI: \(path) - HTTP Status Code \(httpURLResponse.statusCode)")
                        completion(.failure(Error.http(httpURLResponse.statusCode)))
                        return
                    }

                    guard let data = data else {
                        print("!!! TMDBAPI: \(path) - invalid response")
                        completion(.failure(Error.invalidResponse))
                        return
                    }

                    do {
                        let jsonDecoder = JSONDecoder()
                        jsonDecoder.keyDecodingStrategy = self.keyDecodingStrategy
                        completion(.success(try jsonDecoder.decode(type, from: data)))
                    } catch {
                        assertionFailure("!!! TMDBAPI: \(path) - \(error.localizedDescription)")
                        completion(.failure(Error.format(error)))
                    }
                }
                .resume()
        }
    }

    private func endpoint(path: String, parameters: [String: String] = [:]) -> URL? {
        guard let url = URL(string: endpoint)?.appendingPathComponent(path) else {
            return nil
        }

        var parameters = parameters
        parameters["api_key"] ??= apiKey
        parameters["language"] ??= language

        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
        return urlComponents?.url
    }

    private func validate(show: ShowResponse) -> Bool {
        return show.id ?? 0 > 0
    }

    private func map(_ results: [ShowResponse], limit: Int) -> [Show] {
        return results
            .filter {
                return
                    !($0.name ?? "").isEmpty &&
                    !($0.posterPath ?? "").isEmpty &&
                    !($0.firstAirDate ?? "").isEmpty
            }
            .sorted {
                if $0.voteAverage != $1.voteAverage && $0.voteCount ?? 0 > 100 && $1.voteCount ?? 0 > 100 {
                    return $0.voteAverage ?? 0 > $1.voteAverage ?? 0
                } else {
                    return $0.popularity ?? 0 > $1.popularity ?? 0
                }
            }
            .prefix(limit)
            .map { show(from: $0) }
    }

    private func show(from showResponse: ShowResponse, includingEpisodes: Bool = false) -> Show {
        return Show(from: showResponse,
                    includingEpisodes: includingEpisodes,
                    posterURL: imageURL(for: showResponse.posterPath, size: .poster),
                    backdropURL: imageURL(for: showResponse.backdropPath, size: .backdrop))
    }
}
