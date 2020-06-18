//
//  Services.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 23/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

protocol ServiceContainer
{
    var config: PropertyList<ConfigPropertyListTag> { get }
    var shows: ShowsService { get }
    var showStorage: ShowStorage { get }
    var imageCache: ImageCache { get }
    var theMovieDBClient: TheMovieDBClient { get }
    var coreData: CoreData { get }
}

final class Services: ServiceContainer
{
    // swiftlint:disable:next force_try
    lazy var config = try! PropertyList<ConfigPropertyListTag>(name: "Config")

    // swiftlint:disable:next force_unwrapping
    lazy var theMovieDBClient = TheMovieDBClient(apiKey: config[.configTheMovieDBAPIKey]!)

    lazy var shows = ShowsService(
        application: UIApplication.shared,
        storage: showStorage,
        client: theMovieDBClient,
        imageCache: imageCache
    )

    lazy var showStorage = ShowStorage(coreData: coreData)
    lazy var imageCache = ImageCache.shared

    lazy var coreData =
        CoreData(containerType: .cloudKit(containerIdentifier:
            "iCloud." + (Bundle.main.bundleIdentifier ?? "")))
}
