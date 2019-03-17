//
//  ShowsViewController.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 14/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Foundation
import UIKit
import GoogleMobileAds

protocol ShowsViewControllerDelegate: AnyObject {
    func didTapAddButton(in showsViewController: ShowsViewController)
    func didTapFeedbackButton(in showsViewController: ShowsViewController)
    func didTapPrivacyPolicyButton(in showsViewController: ShowsViewController)
    func didTapSwitchThemeButton(in showsViewController: ShowsViewController)
}

class ShowsViewController: UIViewController, ShowTransitionAnimatingSubviews {
    weak var delegate: ShowsViewControllerDelegate?
    weak var showsCollectionViewDelegate: ShowsCollectionViewDelegate?
    weak var showsCollectionViewDataSource: ShowsCollectionViewDataSource?

    var animatedSubviews: [UIView] = []
    var shouldShowBottomBanner = true

    var bottomBannerAdMobUnitID: String? {
        didSet { bannerView.adUnitID = bottomBannerAdMobUnitID }
    }

    var adMobTestDevices: [String] = []

    private lazy var adMobRequest: GADRequest = {
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID] + adMobTestDevices
        return request
    }()

    private lazy var blurredHeaderView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        return visualEffectView
    }()

    private lazy var showsCollectionView: ShowsCollectionView = {
        let showsCollectionView = ShowsCollectionView()
        showsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        showsCollectionView.delegate = showsCollectionViewDelegate
        showsCollectionView.dataSource = showsCollectionViewDataSource
        showsCollectionView.isPersistentPosterImageCaching = true
        showsCollectionView.canDeleteItems = true
        return showsCollectionView
    }()

    private lazy var logoImageView: UIImageView = {
        let image = UIImage(named: "logo-25")
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(origin: .zero, size: image?.size ?? .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var bannerView: GADBannerView = {
        let bannerView = GADBannerView()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.isHidden = true
        return bannerView
    }()

    private lazy var showsCollectionViewBottomToBannerConstraint =
        showsCollectionView.bottomAnchor.constraint(equalTo: bannerView.topAnchor)

    private lazy var showsCollectionViewBottomToViewContstraint =
        showsCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Theme.current.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "plus-20"),
            style: .plain,
            target: self,
            action: #selector(didTapAddButton)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "ellipsis-20"),
            style: .plain,
            target: self,
            action: #selector(didTapDotsButton)
        )

        navigationItem.titleView = logoImageView

        view.addSubview(showsCollectionView)
        view.addSubview(blurredHeaderView)
        view.addSubview(bannerView)

        NSLayoutConstraint.activate([
            blurredHeaderView.leftAnchor.constraint(equalTo: view.leftAnchor),
            blurredHeaderView.rightAnchor.constraint(equalTo: view.rightAnchor),
            blurredHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            blurredHeaderView.heightAnchor.constraint(equalTo: topLayoutGuide.heightAnchor),

            bannerView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            showsCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            showsCollectionViewBottomToViewContstraint,
        ])

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                showsCollectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                showsCollectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                showsCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
                showsCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            ])
        }

        if shouldShowBottomBanner {
            bannerView.load(adMobRequest)
        }

        startListenForThemeChange()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateBannerAdSize()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateBannerAdSize()
    }

    func performBatchUpdates(_ updates: () -> Void) {
        showsCollectionView.performBatchUpdates(updates)
    }

    func insertShow(at index: Int) {
        showsCollectionView.insertItems(at: [IndexPath(item: index, section: 0)])
    }

    func deleteShow(at index: Int) {
        showsCollectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
    }

    func updateShow(at index: Int, show: Show) {
        showsCollectionView.cellForItem(at: IndexPath(item: index, section: 0))?.model = show
    }

    private func updateBannerAdSize() {
        if UIDevice.current.orientation.isLandscape {
            bannerView.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            bannerView.adSize = kGADAdSizeSmartBannerPortrait
        }
    }

    private func showBanner() {
        bannerView.alpha = 0
        bannerView.isHidden = false
        showsCollectionViewBottomToViewContstraint.isActive = false
        showsCollectionViewBottomToBannerConstraint.isActive = true

        UIView.animate(withDuration: 0.3) {
            self.bannerView.alpha = 1
        }
    }

    private func hideBanner() {
        bannerView.alpha = 1
        showsCollectionViewBottomToBannerConstraint.isActive = false
        showsCollectionViewBottomToViewContstraint.isActive = true

        UIView.animate(withDuration: 0.3, animations: {
            self.bannerView.alpha = 0
        }, completion: { _ in
            self.bannerView.isHidden = true
        })
    }

    @objc private func didTapAddButton() {
        delegate?.didTapAddButton(in: self)
    }

    @objc private func didTapDotsButton(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = button

        alertController.addAction(UIAlertAction(
            title: "Switch Theme".localized(comment: "Switch Theme button"),
            style: .default,
            handler: { _ in
                self.delegate?.didTapSwitchThemeButton(in: self)
            }
        ))

        alertController.addAction(UIAlertAction(
            title: "Feedback".localized(comment: "Feedback button"),
            style: .default,
            handler: { _ in
                self.delegate?.didTapFeedbackButton(in: self)
            }
        ))

        alertController.addAction(UIAlertAction(
            title: "Privacy Policy".localized(comment: "Privacy Policy button"),
            style: .default,
            handler: { _ in
                self.delegate?.didTapPrivacyPolicyButton(in: self)
            }
        ))

        alertController.addAction(UIAlertAction(
            title: "Cancel".localized(comment: "Cancel button"),
            style: .cancel
        ))

        present(alertController, animated: true)
    }
}

extension ShowsViewController: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        showBanner()
    }

    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        hideBanner()
        print("!!! AdMob: \(error.localizedDescription)")
    }
}

extension ShowsViewController: ChangingTheme {
    @objc func didChangeTheme() {
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()

            self.view.backgroundColor = Theme.current.primaryBackgroundColor
            self.logoImageView.tintColor = Theme.current.tintColor
            self.navigationItem.leftBarButtonItem?.tintColor = Theme.current.tintColor.withAlphaComponent(0.33)
            self.blurredHeaderView.effect = UIBlurEffect(style: Theme.current.blurStyle)
        }
    }
}
