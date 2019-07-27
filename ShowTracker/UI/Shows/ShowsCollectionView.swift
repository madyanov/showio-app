//
//  ShowsCollectionView.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 23/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

protocol ShowsCollectionViewDelegate: AnyObject
{
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView,
                             didTapOn cell: ShowCollectionViewCell,
                             at index: Int)

    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, didTapDeleteButtonForItemAt index: Int)
}

extension ShowsCollectionViewDelegate
{
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, didTapDeleteButtonForItemAt index: Int) { }
}

protocol ShowsCollectionViewDataSource: AnyObject
{
    func numberOfItems(in showsCollectionView: ShowsCollectionView) -> Int
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, showForItemAt index: Int) -> Show
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, prefetchItemsAt indices: [Int])
}

extension ShowsCollectionViewDataSource
{
    func showsCollectionView(_ showsCollectionView: ShowsCollectionView, prefetchItemsAt indices: [Int]) { }
}

final class ShowsCollectionView: UIView
{
    enum Style
    {
        case `default`
        case minimal
    }

    weak var delegate: ShowsCollectionViewDelegate?
    weak var dataSource: ShowsCollectionViewDataSource?

    var isPersistentPosterImageCaching = false
    var canDeleteItems = false

    var style = Style.default {
        didSet { sizingShowCollectionViewCell.style = style == .minimal ? .minimal : .default }
    }

    var additionalVerticalInset: CGFloat = 0

    private lazy var collectionViewLayout = ShowsCollectionViewLayout()

    private let showCellReuseIdentifier = "showCell"

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.keyboardDismissMode = .onDrag
        collectionView.register(ShowCollectionViewCell.self, forCellWithReuseIdentifier: showCellReuseIdentifier)
        return collectionView
    }()

    private lazy var sizingShowCollectionViewCell: ShowCollectionViewCell = {
        let showCollectionViewCell = ShowCollectionViewCell()
        showCollectionViewCell.style = style == .minimal ? .minimal : .default
        return showCollectionViewCell
    }()

    private var shouldScrollToTop = false
    private var cachedItemSize: CGSize?

    convenience init() {
        self.init(frame: .zero)

        addSubview(collectionView)
        collectionView.snap()

        startListenForThemeChange()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cachedItemSize = nil

        let spacing: CGFloat = style == .minimal ? .standardSpacing * 2 : .standardSpacing * 3
        collectionViewLayout.minimumInteritemSpacing = spacing
        collectionViewLayout.minimumLineSpacing = spacing

        collectionViewLayout.sectionInset = UIEdgeInsets(top: spacing + additionalVerticalInset,
                                                         left: spacing,
                                                         bottom: spacing,
                                                         right: spacing)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cachedItemSize = nil
        collectionViewLayout.invalidateLayout()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow != nil {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillChangeFrame),
                                                   name: UIResponder.keyboardWillChangeFrameNotification,
                                                   object: nil)
        } else {
            NotificationCenter.default.removeObserver(self,
                                                      name: UIResponder.keyboardWillChangeFrameNotification,
                                                      object: nil)
        }
    }

    func performBatchUpdates(_ updates: () -> Void) {
        collectionView.performBatchUpdates(updates) { _ in
            if self.shouldScrollToTop {
                self.scrollToTop()
                self.shouldScrollToTop = false
            }
        }
    }

    func reloadData() {
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    func insertItems(at indexPaths: [IndexPath]) {
        collectionView.insertItems(at: indexPaths)
        shouldScrollToTop = indexPaths.contains { $0.item == 0 }
    }

    func deleteItems(at indexPaths: [IndexPath]) {
        collectionView.deleteItems(at: indexPaths)
    }

    func cellForItem(at indexPath: IndexPath) -> ShowCollectionViewCell? {
        return collectionView.cellForItem(at: indexPath) as? ShowCollectionViewCell
    }
}

extension ShowsCollectionView: UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath)
    {
        guard collectionView.isDragging else {
            return
        }

        cell.alpha = 0
        cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)

        UIView.animate(withDuration: 0.3) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        UIMenuController.shared.menuItems = [
            UIMenuItem(title: "Delete".localized(comment: "Delete menu item title"),
                       action: #selector(ShowCollectionViewCell.deleteAction)),
        ]

        let cell = collectionView.cellForItem(at: indexPath) as? ShowCollectionViewCell
        cell?.shouldCancelTapGesture = canDeleteItems
        return canDeleteItems
    }

    func collectionView(_ collectionView: UICollectionView,
                        canPerformAction action: Selector,
                        forItemAt indexPath: IndexPath,
                        withSender sender: Any?) -> Bool
    {
        return action == #selector(ShowCollectionViewCell.deleteAction)
    }

    func collectionView(_ collectionView: UICollectionView,
                        performAction action: Selector,
                        forItemAt indexPath: IndexPath,
                        withSender sender: Any?)
    {
        // workaround to show menu
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        if let size = cachedItemSize {
            return size
        }

        configureCell(sizingShowCollectionViewCell, at: indexPath)

        let contentWidth = collectionView.bounds.width -
            self.collectionViewLayout.sectionInset.horizontal -
            collectionView.contentInset.horizontal

        let sizeRatio = collectionView.bounds.height / collectionView.bounds.width
        var numberOfColumns: CGFloat = 0

        if traitCollection.userInterfaceIdiom == .pad {
            numberOfColumns = sizeRatio < 1 ? 5 : 4
        } else if style == .minimal {
            numberOfColumns = sizeRatio < 1 ? 5 : 3
        } else {
            numberOfColumns = sizeRatio < 1 ? 4 : 2
        }

        let interitemSpacing = self.collectionViewLayout.minimumInteritemSpacing
        let width = (contentWidth - interitemSpacing * (numberOfColumns - 1)) / numberOfColumns - 1

        let height = sizingShowCollectionViewCell.contentView.systemLayoutSizeFitting(
            CGSize(width: width, height: 1),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        ).height

        let size = CGSize(width: width, height: height)
        cachedItemSize = size
        return size
    }
}

extension ShowsCollectionView: UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfItems(in: self) ?? 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: showCellReuseIdentifier, for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }
}

extension ShowsCollectionView: UICollectionViewDataSourcePrefetching
{
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        dataSource?.showsCollectionView(self, prefetchItemsAt: indexPaths.map { $0.item })
    }
}

extension ShowsCollectionView: ShowCollectionViewCellDelegate
{
    func willDelete(cell: ShowCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            delegate?.showsCollectionView(self, didTapDeleteButtonForItemAt: indexPath.item)
        }
    }

    func didTap(on cell: ShowCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            delegate?.showsCollectionView(self, didTapOn: cell, at: indexPath.item)
        }
    }
}

extension ShowsCollectionView: ThemeChanging
{
    @objc
    func didChangeTheme() {
        collectionView.indicatorStyle = Theme.current.scrollIndicatorStyle
    }
}

extension ShowsCollectionView
{
    private func configureCell(_ cell: UICollectionViewCell, at indexPath: IndexPath) {
        guard
            let cell = cell as? ShowCollectionViewCell,
            var show = dataSource?.showsCollectionView(self, showForItemAt: indexPath.item)
        else {
            return
        }

        if cell == sizingShowCollectionViewCell {
            show.posterURL = nil
            show.backdropURL = nil
        }

        cell.delegate = self
        cell.style = style == .minimal ? .minimal : .default
        cell.isPersistentPosterImageCaching = isPersistentPosterImageCaching
        cell.model = show
    }

    private func scrollToTop() {
        if #available(iOS 11.0, *) {
            let offset = CGPoint(x: -collectionView.adjustedContentInset.left,
                                 y: -collectionView.adjustedContentInset.top)

            collectionView.setContentOffset(offset, animated: true)
        } else {
            let offset = CGPoint(x: -collectionView.contentInset.left, y: -collectionView.contentInset.top)
            collectionView.setContentOffset(offset, animated: true)
        }
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let window = UIApplication.shared.windows.first,
            let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }

        let keyboardHeight = window.bounds.height - keyboardFrame.minY
        collectionView.contentInset.bottom = keyboardHeight
        collectionView.scrollIndicatorInsets.bottom = keyboardHeight
    }
}
