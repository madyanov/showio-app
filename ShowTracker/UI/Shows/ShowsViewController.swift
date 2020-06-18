//
//  ShowsViewController.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 14/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

protocol ShowsViewControllerDelegate: AnyObject
{
    func didTapAddButton(in showsViewController: ShowsViewController)
    func didTapFeedbackButton(in showsViewController: ShowsViewController)
    func didTapPrivacyPolicyButton(in showsViewController: ShowsViewController)
    func didTapSwitchThemeButton(in showsViewController: ShowsViewController)
}

final class ShowsViewController: UIViewController, ShowTransitionSubviewsAnimating
{
    weak var delegate: ShowsViewControllerDelegate?

    weak var showsCollectionViewDelegate: ShowsCollectionViewDelegate? {
        didSet { showsCollectionView.delegate = showsCollectionViewDelegate }
    }

    weak var showsCollectionViewDataSource: ShowsCollectionViewDataSource? {
        didSet { showsCollectionView.dataSource = showsCollectionViewDataSource }
    }

    var animatedSubviews: [UIView] = []

    private let coordinator: ShowsCoordinator

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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Theme.current.statusBarStyle
    }

    init(coordinator: ShowsCoordinator) {
        self.coordinator = coordinator

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "plus-20"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapAddButton))

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ellipsis-20"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(didTapDotsButton))

        navigationItem.titleView = logoImageView

        view.addSubview(showsCollectionView)
        view.addSubview(blurredHeaderView)

        NSLayoutConstraint.activate([
            blurredHeaderView.leftAnchor.constraint(equalTo: view.leftAnchor),
            blurredHeaderView.rightAnchor.constraint(equalTo: view.rightAnchor),
            blurredHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            blurredHeaderView.heightAnchor.constraint(equalTo: topLayoutGuide.heightAnchor),

            showsCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            showsCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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

        startListenForThemeChange()

        coordinator.didLoadView(self)
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
}

extension ShowsViewController: ThemeChanging
{
    @objc
    func didChangeTheme() {
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()

            self.view.backgroundColor = Theme.current.primaryBackgroundColor
            self.logoImageView.tintColor = Theme.current.tintColor
            self.navigationItem.leftBarButtonItem?.tintColor = Theme.current.tintColor.withAlphaComponent(0.5)
            self.blurredHeaderView.effect = UIBlurEffect(style: Theme.current.blurStyle)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)  {
                Theme.current = traitCollection.userInterfaceStyle == .light ? .light : .dark
            }
        }
    }
}

extension ShowsViewController
{
    @objc
    private func didTapAddButton() {
        delegate?.didTapAddButton(in: self)
    }

    @objc
    private func didTapDotsButton(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = button

        if #available(iOS 13.0, *) {} else {
            alertController.addAction(UIAlertAction(title: "Switch Theme".localized(comment: "Switch Theme button"),
                                                    style: .default,
                                                    handler: { _ in
                                                        self.delegate?.didTapSwitchThemeButton(in: self)
                                                    }))
        }

        alertController.addAction(UIAlertAction(title: "Feedback".localized(comment: "Feedback button"),
                                                style: .default,
                                                handler: { _ in
                                                    self.delegate?.didTapFeedbackButton(in: self)
                                                }))

        alertController.addAction(UIAlertAction(title: "Privacy Policy".localized(comment: "Privacy Policy button"),
                                                style: .default,
                                                handler: { _ in
                                                    self.delegate?.didTapPrivacyPolicyButton(in: self)
                                                }))

        alertController.addAction(UIAlertAction(title: "Cancel".localized(comment: "Cancel button"),
                                                style: .cancel))

        present(alertController, animated: true)
    }
}
