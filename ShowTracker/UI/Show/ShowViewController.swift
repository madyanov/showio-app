//
//  ShowViewController.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 30/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

protocol ShowViewControllerDelegate: AnyObject
{
    func didTapAddButton(in showViewController: ShowViewController)
    func didTapDeleteButton(in showViewController: ShowViewController)
    func didTapViewSeasonButton(in showViewController: ShowViewController, show: Show, season: Season)
    func didTapUnseeSeasonButton(in showViewController: ShowViewController, show: Show, season: Season)
}

final class ShowViewController: UIViewController
{
    weak var delegate: ShowViewControllerDelegate?
    weak var episodesCollectionViewDelegate: EpisodesCollectionViewDelegate?
    weak var episodesCollectionViewDataSource: EpisodesCollectionViewDataSource?

    private(set) var model: Show? {
        didSet { fillRows() }
    }

    var isShowAlreadyExists: Bool? {
        didSet {
            infoCell?.isShowAlreadyExists = isShowAlreadyExists
            episodesCell?.isScrollEnabled = isShowAlreadyExists != nil
        }
    }

    private let coordinator: ShowCoordinator

    private let posterHeight: CGFloat = 170
    private let posterOverlapping: CGFloat = .standardSpacing * 3
    private let collapsedHeaderHeight: CGFloat = 44

    private lazy var lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var expandedHeaderHeight: CGFloat {
        var height = posterHeight + collapsedHeaderHeight - posterOverlapping

        if traitCollection.userInterfaceIdiom == .pad {
            height += 44
        }

        return height
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.delaysContentTouches = false
        tableView.separatorColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false

        Cell.register(in: tableView)

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }

        return tableView
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var headerGradientView: GradientView = {
        let gradientView = GradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        gradientView.colors = [
            UIColor.black.withAlphaComponent(0.2),
            UIColor.black.withAlphaComponent(0.45),
        ]

        return gradientView
    }()

    private lazy var backdropImageView: CachedImageView = {
        let cachedImageView = CachedImageView()
        cachedImageView.translatesAutoresizingMaskIntoConstraints = false
        cachedImageView.backgroundColor = .clear
        cachedImageView.contentMode = .scaleAspectFill
        cachedImageView.clipsToBounds = true
        return cachedImageView
    }()

    private lazy var headerBarView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var collapsedNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTextStyle(.title3)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private lazy var closeButton: Button = {
        let button = Button(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "chevron-down-20"), for: .normal)
        button.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        button.tintColor = .white
        return button
    }()

    private lazy var posterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .standardSpacing
        stackView.alignment = .bottom
        return stackView
    }()

    private lazy var posterImageContainerView: UIView = {
        let view = UIView()
        view.layer.shadowRadius = .standardSpacing
        view.layer.shadowOffset = CGSize(width: 0, height: .standardSpacing / 2)
        view.layer.shadowOpacity = 0.2
        return view
    }()

    private lazy var posterImageView: CachedImageView = {
        let cachedImageView = CachedImageView()
        cachedImageView.translatesAutoresizingMaskIntoConstraints = false
        cachedImageView.backgroundColor = .clear
        cachedImageView.contentMode = .scaleAspectFill
        cachedImageView.layer.cornerRadius = .standardSpacing
        cachedImageView.layer.masksToBounds = true
        return cachedImageView
    }()

    private lazy var posterInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = .standardSpacing
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.title1)
        label.textColor = .white
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var yearLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.body)
        label.textColor = .white
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    // workaround to hide bottom rounded borders
    private lazy var opaqueBottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var headerViewHeightConstraint: NSLayoutConstraint = {
        let constraint = headerView.heightAnchor.constraint(equalToConstant: headerHeight)
        constraint.priority = .highest
        return constraint
    }()

    private lazy var opaqueBottomViewHeightConstraint = opaqueBottomView.heightAnchor.constraint(equalToConstant: 0)

    private lazy var transitionAnimator = ShowTransitionAnimator()

    private var headerHeight: CGFloat = 0 {
        didSet {
            let height = topLayoutGuide.length + headerHeight
            tableView.scrollIndicatorInsets.top = height
            tableView.contentInset.top = height
            tableView.contentOffset.y = -height
        }
    }

    private var shouldCollapseHeader = false
    private var rows: [Cell] = []
    private var cachedRowHeights: [IndexPath: CGFloat] = [:]

    // workaround to prevent jumping when expaniding overview cell
    private var savedTableViewContentOffset: CGPoint?

    private var infoCell: InfoTableViewCell?
    private var progressCell: ProgressTableViewCell?
    private var episodesCell: EpisodesTableViewCell?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return traitCollection.horizontalSizeClass == .regular
            ? Theme.current.statusBarStyle
            : .lightContent
    }

    init(coordinator: ShowCoordinator) {
        self.coordinator = coordinator

        super.init(nibName: nil, bundle: nil)

        transitioningDelegate = transitionAnimator
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false

        view.addSubview(opaqueBottomView)
        view.addSubview(tableView)
        tableView.addSubview(headerView)
        headerView.addSubview(backdropImageView)
        backdropImageView.addSubview(headerGradientView)
        headerView.addSubview(posterStackView)
        posterStackView.addArrangedSubview(posterImageContainerView)
        posterImageContainerView.addSubview(posterImageView)
        posterStackView.addArrangedSubview(posterInfoStackView)
        posterInfoStackView.addArrangedSubview(nameLabel)
        posterInfoStackView.addArrangedSubview(yearLabel)
        headerView.addSubview(headerBarView)
        headerBarView.addSubview(collapsedNameLabel)
        headerBarView.addSubview(closeButton)

        tableView.snap()
        backdropImageView.snap()
        headerGradientView.snap()
        posterImageView.snap(priority: .highest)

        NSLayoutConstraint.activate([
            opaqueBottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
            opaqueBottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
            opaqueBottomView.centerYAnchor.constraint(equalTo: view.bottomAnchor),

            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),

            backdropImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            posterStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor,
                                                    constant: -(.standardSpacing * 2)),

            posterStackView.heightAnchor.constraint(equalToConstant: posterHeight),

            posterImageView.heightAnchor.constraint(equalTo: posterImageView.widthAnchor, multiplier: 1.5),
            posterImageView.heightAnchor.constraint(lessThanOrEqualTo: posterImageContainerView.heightAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: posterOverlapping),

            headerBarView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            headerBarView.heightAnchor.constraint(equalToConstant: collapsedHeaderHeight),

            collapsedNameLabel.leftAnchor.constraint(equalTo: headerBarView.leftAnchor, constant: 56),
            collapsedNameLabel.rightAnchor.constraint(equalTo: headerBarView.rightAnchor, constant: -56),
            collapsedNameLabel.topAnchor.constraint(equalTo: headerBarView.topAnchor),
            collapsedNameLabel.bottomAnchor.constraint(equalTo: headerBarView.bottomAnchor),

            closeButton.widthAnchor.constraint(equalToConstant: 56),
            closeButton.topAnchor.constraint(equalTo: headerBarView.topAnchor),
            closeButton.bottomAnchor.constraint(equalTo: headerBarView.bottomAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerBarView.trailingAnchor),
        ])

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                headerBarView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                headerBarView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),

                posterStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                         constant: .standardSpacing * 3),

                posterStackView.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -(.standardSpacing * 3)
                ),
            ], priority: .highest)
        } else {
            NSLayoutConstraint.activate([
                headerBarView.leftAnchor.constraint(equalTo: view.leftAnchor),
                headerBarView.rightAnchor.constraint(equalTo: view.rightAnchor),
                posterStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .standardSpacing * 3),

                posterStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -(.standardSpacing * 3)),
            ])
        }

        opaqueBottomViewHeightConstraint.isActive = true
        headerViewHeightConstraint.isActive = true

        startListenForThemeChange()

        coordinator.didLoadView(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupHeaderHeight()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        coordinator.viewDidAppear()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupHeaderHeight()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.tableFooterView?.frame.size = CGSize(width: tableView.frame.width, height: 1)
        opaqueBottomViewHeightConstraint.constant = tableView.layer.cornerRadius * 2
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset.bottom = bottomLayoutGuide.length
        tableView.scrollIndicatorInsets.bottom = bottomLayoutGuide.length

        posterImageContainerView.layer.shadowPath = UIBezierPath(
            roundedRect: posterImageView.layer.frame,
            cornerRadius: posterImageView.layer.cornerRadius
        ).cgPath
    }

    func setModel(_ show: Show?, fullTableReload: Bool = false, animated: Bool = false) {
        if show != model {
            posterImageView.setImage(with: show?.posterURL)
            backdropImageView.setImage(with: show?.backdropURL, placeholderURL: show?.posterURL)
        }

        model = show
        collapsedNameLabel.text = show?.name
        nameLabel.text = show?.name
        yearLabel.text = show?.year

        shouldCollapseHeader = show?.posterURL == nil

        if fullTableReload {
            UIView.transition(with: tableView,
                              duration: animated ? 0.4 : 0,
                              options: .transitionCrossDissolve,
                              animations: { self.tableView.reloadData() })
        } else {
            tableView.visibleCells.forEach { cell in
                guard let index = tableView.indexPath(for: cell)?.row else {
                    return
                }

                if case .season(let season, let show)? = rows[at: index],
                    let cell = cell as? SeasonTableViewCell
                {
                    cell.delegate = self
                    cell.setModel(season, show: show, animated: animated)
                } else if case .progress(let show)? = rows[at: index],
                    let cell = cell as? ProgressTableViewCell
                {
                    cell.setModel(show, animated: animated)
                }
            }
        }

        episodesCell?.reloadVisibleItems()
    }
}

extension ShowViewController
{
    private enum Cell: CaseIterable
    {
        case info(show: Show?)
        case progress(show: Show?)
        case overview(show: Show?)
        case episodes
        case title(String?)
        case season(Season?, show: Show?)
        case loading

        static var allCases: [Cell] {
            return [
                .info(show: nil),
                .progress(show: nil),
                .overview(show: nil),
                .episodes,
                .title(nil),
                .season(nil, show: nil),
                .loading,
            ]
        }

        var cellClass: AnyClass {
            switch self {
            case .info: return InfoTableViewCell.self
            case .progress: return ProgressTableViewCell.self
            case .overview: return OverviewTableViewCell.self
            case .episodes: return EpisodesTableViewCell.self
            case .title: return TitleTableViewCell.self
            case .season: return SeasonTableViewCell.self
            case .loading: return LoadingTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return String(describing: cellClass)
        }

        func dequeue<T>(from tableView: UITableView, for indexPath: IndexPath) -> T? {
            return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? T
        }

        static func register(in tableView: UITableView) {
            for cell in Cell.allCases {
                tableView.register(cell.cellClass, forCellReuseIdentifier: cell.reuseIdentifier)
            }
        }
    }
}

extension ShowViewController: ShadedAndRounded
{
    var viewWithShadow: UIView? {
        return view
    }

    var viewWithRoundedCorners: UIView? {
        return tableView
    }
}

extension ShowViewController: UITableViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isBeingDismissed else {
            return
        }

        if let contentOffset = savedTableViewContentOffset {
            tableView.contentOffset = contentOffset
        }

        var height = headerHeight - (scrollView.contentOffset.y + headerHeight)
        height = max(topLayoutGuide.length + collapsedHeaderHeight, height)
        headerViewHeightConstraint.constant = height
        tableView.scrollIndicatorInsets.top = height

        let progress = (height - collapsedHeaderHeight - topLayoutGuide.length) /
            (expandedHeaderHeight - collapsedHeaderHeight)

        posterStackView.alpha = progress * 8
        collapsedNameLabel.alpha = (0.05 - progress) * 20

        let distanceToDismiss: CGFloat = traitCollection.verticalSizeClass == .compact ? 80 : 120

        if scrollView.isDragging, height - headerHeight - topLayoutGuide.length > distanceToDismiss {
            presentingViewController?.dismiss(animated: true)
            lightImpactFeedbackGenerator.impactOccurred()
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cachedRowHeights[indexPath] = cell.frame.height
        cell.backgroundColor = .clear
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cachedRowHeights[indexPath] ?? tableView.estimatedRowHeight
    }
}

extension ShowViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[at: indexPath.row]

        if case .info(let show)? = row,
            let cell: InfoTableViewCell = row?.dequeue(from: tableView, for: indexPath)
        {
            infoCell = cell
            cell.isShowAlreadyExists = isShowAlreadyExists
            cell.model = show
            cell.delegate = self
            return cell
        } else if case .progress(let show)? = row,
            let cell: ProgressTableViewCell = row?.dequeue(from: tableView, for: indexPath)
        {
            progressCell = cell
            cell.setModel(show)
            return cell
        } else if case .overview(let show)? = row,
            let cell: OverviewTableViewCell = row?.dequeue(from: tableView, for: indexPath)
        {
            cell.onTapReadMoreButton = { [weak self] in
                cell.isCollapsed.toggle()

                // workaround to prevent jumping when expaniding overview cell
                self?.savedTableViewContentOffset = self?.tableView.contentOffset
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
                self?.savedTableViewContentOffset = nil
            }

            cell.model = show
            return cell
        } else if case .episodes? = row,
            let cell: EpisodesTableViewCell = row?.dequeue(from: tableView, for: indexPath)
        {
            episodesCell = cell
            cell.episodesCollectionViewDelegate = episodesCollectionViewDelegate
            cell.episodesCollectionViewDataSource = episodesCollectionViewDataSource
            return cell
        } else if case .title(let title)? = row,
            let cell: TitleTableViewCell = row?.dequeue(from: tableView, for: indexPath)
        {
            cell.title = title
            return cell
        } else if case .season(let season, let show)? = row,
            let cell: SeasonTableViewCell = row?.dequeue(from: tableView, for: indexPath)
        {
            cell.delegate = self
            cell.setModel(season, show: show)
            return cell
        } else if case .loading? = row,
            let cell: LoadingTableViewCell = row?.dequeue(from: tableView, for: indexPath)
        {
            return cell
        }

        return UITableViewCell()
    }
}

extension ShowViewController: UIGestureRecognizerDelegate { }

extension ShowViewController: InfoTableViewCellDelegate
{
    func didTapDeleteButton(in infoTableViewCell: InfoTableViewCell) {
        delegate?.didTapDeleteButton(in: self)
    }

    func didTapAddButton(in infoTableViewCell: InfoTableViewCell) {
        delegate?.didTapAddButton(in: self)
    }
}

extension ShowViewController: SeasonTableViewCellDelegate
{
    func didTapViewButton(in cell: SeasonTableViewCell) {
        guard let show = model, let season = cell.season else {
            return
        }

        delegate?.didTapViewSeasonButton(in: self, show: show, season: season)
    }

    func didTapUnseeButton(in cell: SeasonTableViewCell) {
        guard let show = model, let season = cell.season else {
            return
        }

        delegate?.didTapUnseeSeasonButton(in: self, show: show, season: season)
    }
}

extension ShowViewController: ShowTransitionSubviewsAnimating
{
    var animatedSubviews: [UIView] {
        get {
            guard traitCollection.verticalSizeClass == .regular else {
                return []
            }

            return [posterImageView]
        }
        // TODO: looks weird
        set { } // swiftlint:disable:this unused_setter_value
    }
}

extension ShowViewController: ThemeChanging
{
    @objc
    func didChangeTheme() {
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()

            self.tableView.backgroundColor = Theme.current.primaryBackgroundColor
            self.opaqueBottomView.backgroundColor = Theme.current.primaryBackgroundColor
            self.tableView.indicatorStyle = Theme.current.scrollIndicatorStyle
        }
    }
}

extension ShowViewController
{
    private func fillRows() {
        rows = []
        rows.append(.info(show: model))

        if model?.overview?.isEmpty == false {
            rows.append(.overview(show: model))
        }

        if model?.episodes.isEmpty == false {
            rows.append(.title("Episodes".localized(comment: "Episodes title label")))
            rows.append(.progress(show: model))
            rows.append(.episodes)

            if model?.seasons.isEmpty == false {
                rows.append(.title("Seasons".localized(comment: "Seasons title label")))
                model?.seasons.forEach { rows.append(.season($0.value, show: model)) }
            }
        } else {
            rows.append(.loading)
        }
    }

    private func setupHeaderHeight() {
        if shouldCollapseHeader || traitCollection.verticalSizeClass != .regular {
            headerHeight = collapsedHeaderHeight
            posterStackView.isHidden = true
        } else {
            headerHeight = expandedHeaderHeight
            posterStackView.isHidden = false
        }
    }

    @objc
    private func didTapCloseButton() {
        presentingViewController?.dismiss(animated: true)
    }
}
