//
//  PropertyListKeys.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 27/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Toolkit

struct ConfigPropertyListTag { }
typealias ConfigPropertyListKey<T> = PropertyListKey<ConfigPropertyListTag, T>

extension PropertyListKeys
{
    static let configTheMovieDBAPIKey = ConfigPropertyListKey<String>("TMDB API Key")
    static let configSupportEmail = ConfigPropertyListKey<String>("Support Email")
    static let configPrivacyPolicyURL = ConfigPropertyListKey<String>("Privacy Policy URL")
}
