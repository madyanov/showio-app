//
//  SearchViewController.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 14/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

protocol SearchViewControllerDelegate: AnyObject
{
    func didChangeSearchQuery(in searchViewController: SearchViewController)
}

final class SearchViewController: UIViewController, ShowTransitionSubviewsAnimating
{
    weak var delegate: SearchViewControllerDelegate?

    weak var showsCollectionViewDelegate: ShowsCollectionViewDelegate? {
        didSet { showsCollectionView.delegate = showsCollectionViewDelegate }
    }

    weak var showsCollectionViewDataSource: ShowsCollectionViewDataSource? {
        didSet { showsCollectionView.dataSource = showsCollectionViewDataSource }
    }

    var animatedSubviews: [UIView] = []

    var searchQuery: String? {
        return searchController.searchBar.text
    }

    private let coordinator: SearchCoordinator

    private var blurEffect = UIBlurEffect()

    private lazy var blurredHeaderView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        return visualEffectView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        return searchController
    }()

    private lazy var showsCollectionView: ShowsCollectionView = {
        let showsCollectionView = ShowsCollectionView()
        showsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        showsCollectionView.style = traitCollection.userInterfaceIdiom == .pad ? .default : .minimal
        return showsCollectionView
    }()

    private lazy var poweredByLabel: UILabel = {
        let string = "Powered by TheMovieDB".localized(comment: "The Movie DB attribution label")
        let attributedString = NSMutableAttributedString(string: string)

        attributedString.setAttributes([
            .underlineStyle: 1,
        ], range: (string as NSString).range(of: "TheMovieDB"))

        let label = UILabel()
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTextStyle(.footnote)
        label.attributedText = attributedString
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPoweredByLabel)))
        return label
    }()

    private lazy var activityIndicatorLayoutGuide = UILayoutGuide()

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicatorView
    }()

    private lazy var poweredByLabelCollapsedHeightConstraint =
        poweredByLabel.heightAnchor.constraint(equalToConstant: 0)

    private lazy var blurredHeaderViewBottomConstraint =
        blurredHeaderView.bottomAnchor.constraint(equalTo: poweredByLabel.bottomAnchor)

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Theme.current.statusBarStyle
    }

    init(coordinator: SearchCoordinator) {
        self.coordinator = coordinator

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true

        let backButtonSelector = #selector(UINavigationController.popViewController(animated:))

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "chevron-left-20"),
                                                           style: .plain,
                                                           target: navigationController,
                                                           action: backButtonSelector)

        navigationItem.titleView = searchController.searchBar
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        view.addSubview(showsCollectionView)
        view.addSubview(blurredHeaderView)
        view.addSubview(poweredByLabel)
        view.addSubview(activityIndicatorView)

        showsCollectionView.snap(safe: true)

        view.addLayoutGuide(activityIndicatorLayoutGuide)
        activityIndicatorView.center(in: activityIndicatorLayoutGuide, priority: .defaultLow)

        NSLayoutConstraint.activate([
            activityIndicatorView.topAnchor.constraint(greaterThanOrEqualTo: poweredByLabel.bottomAnchor, constant: 32),
        ], priority: .defaultHigh)

        NSLayoutConstraint.activate([
            blurredHeaderView.leftAnchor.constraint(equalTo: view.leftAnchor),
            blurredHeaderView.rightAnchor.constraint(equalTo: view.rightAnchor),
            blurredHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            blurredHeaderViewBottomConstraint,

            poweredByLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            poweredByLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 4),

            activityIndicatorLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            activityIndicatorLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor),
            activityIndicatorLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor),
            activityIndicatorLayoutGuide.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
        ])

        startListenForThemeChange()

        coordinator.didLoadView(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurredHeaderView.effect = self.blurEffect
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // memory leak fix
        searchController.isActive = false

        transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurredHeaderView.effect = nil
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        blurredHeaderView.effect = blurEffect
        searchController.isActive = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        searchController.searchBar.text = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if traitCollection.verticalSizeClass == .regular {
            blurredHeaderViewBottomConstraint.constant = 12
            poweredByLabelCollapsedHeightConstraint.isActive = false
        } else {
            blurredHeaderViewBottomConstraint.constant = -4
            poweredByLabelCollapsedHeightConstraint.isActive = true
        }

        showsCollectionView.additionalVerticalInset =
            poweredByLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height +
            blurredHeaderViewBottomConstraint.constant + 4
    }

    func reloadShows() {
        showsCollectionView.reloadData()
    }

    func startActivityIndicator() {
        activityIndicatorView.startAnimating()
    }

    func stopActivityIndicator() {
        activityIndicatorView.stopAnimating()
    }

    func hideKeyboard() {
        searchController.searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UISearchControllerDelegate
{
    func didPresentSearchController(_ searchController: UISearchController) {
        // workaround to show keyboard once view appeared
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }

        // workaround to properly layout attribution label
        poweredByLabel.setNeedsUpdateConstraints()
        poweredByLabel.updateConstraintsIfNeeded()

        UIView.animate(withDuration: 0.3) {
            self.poweredByLabel.alpha = 1
        }
    }
}

extension SearchViewController: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        delegate?.didChangeSearchQuery(in: self)
    }
}

extension SearchViewController: UIGestureRecognizerDelegate { }

extension SearchViewController: ThemeChanging
{
    @objc
    func didChangeTheme() {
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()

            self.view.backgroundColor = Theme.current.primaryBackgroundColor
            self.searchController.searchBar.tintColor = Theme.current.tintColor
            self.poweredByLabel.textColor = Theme.current.secondaryForegroundColor
            self.activityIndicatorView.style = Theme.current.activityIndicatorStyle
            self.searchController.searchBar.keyboardAppearance = Theme.current.keyboardAppearance

            self.blurEffect = UIBlurEffect(style: Theme.current.blurStyle)
            self.blurredHeaderView.effect = self.blurEffect
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

extension SearchViewController
{
    @objc
    private func didTapPoweredByLabel() {
        guard let url = URL(string: "https://www.themoviedb.org/") else {
            return
        }

        UIApplication.shared.open(url)
    }
}
