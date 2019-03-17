//
//  PropertyListKeys.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 27/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Foundation
import Toolkit

struct ConfigPropertyListTag { }
typealias ConfigPropertyListKey<T> = PropertyListKey<ConfigPropertyListTag, T>

extension PropertyListKeys {
    static let configTheMovieDBAPIKey = ConfigPropertyListKey<String>("TMDB API Key")
    static let configAdMobEnabled = ConfigPropertyListKey<Bool>("AdMob Enabled")
    static let configAdMobApplicationID = ConfigPropertyListKey<String>("AdMob Application ID")
    static let configAdMobBanners = ConfigPropertyListKey<[String: String]>("AdMob Banners")
    static let configAdMobTestDevices = ConfigPropertyListKey<[String]>("AdMob Test Devices")
    static let configSupportEmail = ConfigPropertyListKey<String>("Support Email")
    static let configPrivacyPolicyURL = ConfigPropertyListKey<String>("Privacy Policy URL")
}
