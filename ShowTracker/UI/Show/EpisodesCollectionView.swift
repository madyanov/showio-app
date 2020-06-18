//
//  EpisodesCollectionView.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 16/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

protocol EpisodesCollectionViewDelegate: AnyObject
{
    func episodesCollectionView(_ episodesCollectionView: EpisodesCollectionView,
                                didScrollFrom page: Int,
                                to newPage: Int)

    func initialPageIndex(in episodesCollectionView: EpisodesCollectionView) -> Int?
}

protocol EpisodesCollectionViewDataSource: AnyObject
{
    func numberOfItems(in episodesCollectionView: EpisodesCollectionView) -> Int
    func shouldAppendEndingItem(in episodesCollectionView: EpisodesCollectionView) -> Bool
    func endingItemStyle(in episodeCollectionView: EpisodesCollectionView) -> EndingCollectionViewCell.Style

    func episodesCollectionView(_ episodesCollectionView: EpisodesCollectionView,
                                episodeForItemAt index: Int) -> Episode
}

extension EpisodesCollectionViewDelegate
{
    func initialPageIndex(in episodesCollectionView: EpisodesCollectionView) -> Int? { return nil }
}

final class EpisodesCollectionView: UIView
{
    weak var delegate: EpisodesCollectionViewDelegate? {
        didSet {
            if let initialPageIndex = delegate?.initialPageIndex(in: self) {
                currentPageIndex = initialPageIndex
                updateScrollViewContentOffset()
            }
        }
    }

    weak var dataSource: EpisodesCollectionViewDataSource?

    var contentSize: CGSize {
        return collectionViewLayout.collectionViewContentSize
    }

    var isScrollEnabled = true {
        didSet {
            isUserInteractionEnabled = isScrollEnabled

            if !isScrollEnabled {
                overlayView.isHidden = false
                activityIndicatorView.startAnimating()

                UIView.animate(withDuration: 0.3) {
                    self.overlayView.alpha = 1
                }
            } else {
                overlayView.isHidden = false
                activityIndicatorView.stopAnimating()

                UIView.animate(withDuration: 0.3, animations: {
                    self.overlayView.alpha = 0
                }, completion: { _ in
                    self.overlayView.isHidden = true
                })
            }
        }
    }

    var currentPageIndex = 0

    private lazy var overlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0
        return view
    }()

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicatorView
    }()

    private lazy var collectionViewLayout: EpisodesCollectionViewLayout = {
        let collectionViewLayout = EpisodesCollectionViewLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumLineSpacing = .standardSpacing * 2
        collectionViewLayout.minimumInteritemSpacing = .standardSpacing * 2
        return collectionViewLayout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.addGestureRecognizer(scrollView.panGestureRecognizer)
        collectionView.register(EpisodeCollectionViewCell.self, forCellWithReuseIdentifier: episodeCellReuseIdentifier)
        collectionView.register(EndingCollectionViewCell.self, forCellWithReuseIdentifier: endingCellReuseIdentifier)
        return collectionView
    }()

    private lazy var scrollView: ScrollView = {
        let scrollView = ScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isHidden = true
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        return scrollView
    }()

    private lazy var sizingEpisodeCollectionViewCell = EpisodeCollectionViewCell()

    private var cachedItemSize: CGSize?

    private let episodeCellReuseIdentifier = "episodeCell"
    private let endingCellReuseIdentifier = "endingCell"

    private var itemWidth: CGFloat {
        return collectionView.bounds.width - collectionViewLayout.sectionInset.horizontal
    }

    private var shouldAppendEndingItem: Bool {
        return dataSource?.shouldAppendEndingItem(in: self) ?? false
    }

    private var numberOfItems: Int {
        return dataSource?.numberOfItems(in: self) ?? 0
    }

    convenience init() {
        self.init(frame: .zero)

        addSubview(collectionView)
        addSubview(scrollView)
        addSubview(overlayView)
        overlayView.addSubview(activityIndicatorView)

        collectionView.snap()
        scrollView.snap()
        overlayView.snap()
        activityIndicatorView.center()

        startListenForThemeChange()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cachedItemSize = nil

        var additionalSectionInsets = UIEdgeInsets.zero

        if traitCollection.horizontalSizeClass == .compact {
            additionalSectionInsets = globalSafeAreaInsets
        }

        collectionViewLayout.sectionInset = UIEdgeInsets(top: .standardSpacing * 2,
                                                         left: additionalSectionInsets.left + .standardSpacing * 3,
                                                         bottom: .standardSpacing * 2,
                                                         right: additionalSectionInsets.right + .standardSpacing * 3)

        updateScrollViewContentSize()
        updateScrollViewContentOffset()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cachedItemSize = nil
        collectionViewLayout.invalidateLayout()
    }

    func reloadVisibleItems() {
        let oldCount = collectionView.numberOfItems(inSection: 0)
        var newCount = numberOfItems

        if shouldAppendEndingItem {
            newCount += 1
        }

        if oldCount < newCount {
            let indexPathsToInsert = (oldCount..<newCount).map { IndexPath(item: $0, section: 0) }
            collectionView.insertItems(at: indexPathsToInsert)
        } else if oldCount > newCount {
            let indexPathsToDelete = (newCount..<oldCount).map { IndexPath(item: $0, section: 0) }
            collectionView.deleteItems(at: indexPathsToDelete)
        }

        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else {
                continue
            }

            configureCell(cell, at: indexPath)
        }

        if oldCount != newCount {
            updateScrollViewContentSize()
        }
    }
}

extension EpisodesCollectionView: UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        if let size = cachedItemSize {
            return size
        }

        configureCell(sizingEpisodeCollectionViewCell, at: indexPath)

        let size = sizingEpisodeCollectionViewCell.contentView.systemLayoutSizeFitting(
            CGSize(width: itemWidth, height: 1),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )

        cachedItemSize = size
        return size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }

        let width = itemWidth + collectionViewLayout.minimumInteritemSpacing
        collectionView.contentOffset.x = scrollView.contentOffset.x * width / scrollView.bounds.width

        let newPageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width + 0.5)

        if scrollView.isDragging, newPageIndex != currentPageIndex {
            delegate?.episodesCollectionView(self, didScrollFrom: currentPageIndex, to: newPageIndex)
            currentPageIndex = newPageIndex
        }
    }
}

extension EpisodesCollectionView: UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfItems = self.numberOfItems

        if shouldAppendEndingItem {
            numberOfItems += 1
        }

        return numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if shouldAppendEndingItem,
            indexPath.item >= numberOfItems,
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: endingCellReuseIdentifier,
                for: indexPath
            ) as? EndingCollectionViewCell
        {
            cell.style = dataSource?.endingItemStyle(in: self) ?? .loading
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: episodeCellReuseIdentifier, for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }
}

extension EpisodesCollectionView: EpisodeCollectionViewCellDelegate
{
    func didTapViewButton(in episodeCollectionViewCell: EpisodeCollectionViewCell) {
        scrollToNextPage()
    }
}

extension EpisodesCollectionView: ThemeChanging
{
    @objc
    func didChangeTheme() {
        overlayView.backgroundColor = Theme.current.primaryBackgroundColor.withAlphaComponent(0.67)
        activityIndicatorView.style = Theme.current.activityIndicatorStyle
    }
}

extension EpisodesCollectionView
{
    private func configureCell(_ cell: UICollectionViewCell, at indexPath: IndexPath) {
        guard
            let episodeCell = cell as? EpisodeCollectionViewCell,
            var episode = dataSource?.episodesCollectionView(self, episodeForItemAt: indexPath.item)
        else {
            if let loadingCell = cell as? EndingCollectionViewCell, case .loading = loadingCell.style {
                collectionView.reloadItems(at: [indexPath])
            }

            return
        }

        if episodeCell == sizingEpisodeCollectionViewCell {
            episode.season = nil
            episode.stillPath = nil
            episode.stillURL = nil
            episode.overview = String(repeating: "\n", count: 2)
        }

        episodeCell.delegate = self
        episodeCell.model = episode
    }

    private func scrollToNextPage() {
        scrollToPage(currentPageIndex + 1)
    }

    func updateScrollViewContentOffset() {
        scrollView.contentOffset.x = CGFloat(currentPageIndex) * scrollView.bounds.width
    }

    private func scrollToPage(_ page: Int) {
        let contentOffset = CGPoint(x: scrollView.bounds.width * CGFloat(page), y: 0)
        scrollView.setContentOffset(contentOffset, animated: true)
        delegate?.episodesCollectionView(self, didScrollFrom: currentPageIndex, to: page)
        currentPageIndex = page
    }

    private func updateScrollViewContentSize() {
        scrollView.contentSize = CGSize(
            width: CGFloat(collectionView.numberOfItems(inSection: 0)) * scrollView.bounds.width,
            height: bounds.height
        )
    }
}

private class ScrollView: UIScrollView
{
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton {
            return true
        }

        return super.touchesShouldCancel(in: view)
    }
}
