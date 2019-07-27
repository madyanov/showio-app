//
//  Themes.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 11/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

protocol ThemeChanging: AnyObject
{
    func startListenForThemeChange()
    func didChangeTheme() // must be declared as @objc
}

extension ThemeChanging
{
    func startListenForThemeChange() {
        didChangeTheme()

        NotificationCenter.default.addObserver(self,
                                               selector: Selector(("didChangeTheme")),
                                               name: .didChangeTheme,
                                               object: nil)
    }
}

extension Notification.Name
{
    static let didChangeTheme = Notification.Name("didChangeTheme")
}

protocol Style
{
    var clearBackgroundColor: UIColor { get }
    var primaryBackgroundColor: UIColor { get }
    var secondaryBackgroundColor: UIColor { get }
    var primaryForegroundColor: UIColor { get }
    var secondaryForegroundColor: UIColor { get }
    var primaryBrandColor: UIColor { get }
    var secondaryBrandColor: UIColor { get }
    var tintColor: UIColor { get }
    var ratingColor: UIColor { get }
    var blurStyle: UIBlurEffect.Style { get }
    var statusBarStyle: UIStatusBarStyle { get }
    var activityIndicatorStyle: UIActivityIndicatorView.Style { get }
    var keyboardAppearance: UIKeyboardAppearance { get }
    var scrollIndicatorStyle: UIScrollView.IndicatorStyle { get }
}

enum Theme: String, Style
{
    case light
    case dark

    static var current = Theme.light {
        didSet { NotificationCenter.default.post(name: .didChangeTheme, object: nil) }
    }

    var clearBackgroundColor: UIColor
        { return style.clearBackgroundColor }
    var primaryBackgroundColor: UIColor
        { return style.primaryBackgroundColor }
    var secondaryBackgroundColor: UIColor
        { return style.secondaryBackgroundColor }
    var primaryForegroundColor: UIColor
        { return style.primaryForegroundColor }
    var secondaryForegroundColor: UIColor
        { return style.secondaryForegroundColor }
    var primaryBrandColor: UIColor
        { return style.primaryBrandColor }
    var secondaryBrandColor: UIColor
        { return style.secondaryBrandColor }
    var tintColor: UIColor
        { return style.tintColor }
    var ratingColor: UIColor
        { return style.ratingColor }
    var blurStyle: UIBlurEffect.Style
        { return style.blurStyle }
    var statusBarStyle: UIStatusBarStyle
        { return style.statusBarStyle }
    var activityIndicatorStyle: UIActivityIndicatorView.Style
        { return style.activityIndicatorStyle }
    var keyboardAppearance: UIKeyboardAppearance
        { return style.keyboardAppearance }
    var scrollIndicatorStyle: UIScrollView.IndicatorStyle
        { return style.scrollIndicatorStyle }

    private var style: Style {
        switch self {
        case .light: return Theme.lightStyle
        case .dark: return Theme.darkStyle
        }
    }

    private static let lightStyle = LightStyle()
    private static let darkStyle = DarkStyle()
}

private struct LightStyle: Style
{
    var clearBackgroundColor: UIColor
        { return primaryBackgroundColor.withAlphaComponent(0) }
    var primaryBackgroundColor: UIColor
        { return .white }
    var secondaryBackgroundColor: UIColor
        { return primaryBrandColor.lighterBy(0.95) ?? clearBackgroundColor }
    var primaryForegroundColor: UIColor
        { return UIColor(hex: 0x202020) }
    var secondaryForegroundColor: UIColor
        { return primaryForegroundColor.lighterBy(0.33) ?? clearBackgroundColor }
    var primaryBrandColor: UIColor
        { return UIColor(hex: 0x3498DB) }
    var secondaryBrandColor: UIColor
        { return UIColor(hex: 0x34A8DB) }
    var tintColor: UIColor
        { return primaryForegroundColor }
    var ratingColor: UIColor
        { return UIColor(hex: 0xF1C40F) }
    var blurStyle: UIBlurEffect.Style
        { return .extraLight }
    var statusBarStyle: UIStatusBarStyle
        { return .default }
    var activityIndicatorStyle: UIActivityIndicatorView.Style
        { return .gray }
    var keyboardAppearance: UIKeyboardAppearance
        { return .default }
    var scrollIndicatorStyle: UIScrollView.IndicatorStyle
        { return .default }
}

private struct DarkStyle: Style
{
    var clearBackgroundColor: UIColor
        { return primaryBackgroundColor.withAlphaComponent(0) }
    var primaryBackgroundColor: UIColor
        { return UIColor(hex: 0x202020) }
    var secondaryBackgroundColor: UIColor
        { return primaryBrandColor.lighterBy(0.95) ?? clearBackgroundColor }
    var primaryForegroundColor: UIColor
        { return UIColor(hex: 0xf0f0f0) }
    var secondaryForegroundColor: UIColor
        { return primaryForegroundColor.darkerBy(0.5) ?? clearBackgroundColor }
    var primaryBrandColor: UIColor
        { return UIColor(hex: 0x3498DB) }
    var secondaryBrandColor: UIColor
        { return UIColor(hex: 0x34A8DB) }
    var tintColor: UIColor
        { return primaryBrandColor }
    var ratingColor: UIColor
        { return UIColor(hex: 0xF1C40F) }
    var blurStyle: UIBlurEffect.Style
        { return .dark }
    var statusBarStyle: UIStatusBarStyle
        { return .lightContent }
    var activityIndicatorStyle: UIActivityIndicatorView.Style
        { return .white }
    var keyboardAppearance: UIKeyboardAppearance
        { return .dark }
    var scrollIndicatorStyle: UIScrollView.IndicatorStyle
        { return .white }
}
