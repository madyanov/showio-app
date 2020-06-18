//
//  EpisodesTableViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 16/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

final class EpisodesTableViewCell: UITableViewCell
{
    weak var episodesCollectionViewDelegate: EpisodesCollectionViewDelegate? {
        didSet { episodesCollectionView.delegate = episodesCollectionViewDelegate }
    }

    weak var episodesCollectionViewDataSource: EpisodesCollectionViewDataSource? {
        didSet { episodesCollectionView.dataSource = episodesCollectionViewDataSource }
    }

    var isScrollEnabled: Bool {
        get { return episodesCollectionView.isScrollEnabled }
        set { episodesCollectionView.isScrollEnabled = newValue }
    }

    private lazy var episodesCollectionView: EpisodesCollectionView = {
        let episodesCollectionView = EpisodesCollectionView()
        episodesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        return episodesCollectionView
    }()

    private lazy var topGradientView: GradientView = {
        let gradientView = GradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()

    private lazy var episodesCollectionViewWidthConstraint =
        episodesCollectionView.widthAnchor.constraint(equalToConstant: 0)

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(episodesCollectionView)
        contentView.addSubview(topGradientView)

        episodesCollectionView.snap(to: self, priority: .highest)

        NSLayoutConstraint.activate([
            episodesCollectionViewWidthConstraint,

            topGradientView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            topGradientView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            topGradientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topGradientView.heightAnchor.constraint(equalToConstant: .standardSpacing * 2),
        ])

        startListenForThemeChange()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                          verticalFittingPriority: UILayoutPriority) -> CGSize
    {
        episodesCollectionViewWidthConstraint.constant = targetSize.width
        episodesCollectionView.layoutIfNeeded()
        return CGSize(width: targetSize.width, height: episodesCollectionView.contentSize.height)
    }

    func reloadVisibleItems() {
        episodesCollectionView.reloadVisibleItems()
    }
}

extension EpisodesTableViewCell: ThemeChanging
{
    @objc
    func didChangeTheme() {
        topGradientView.colors = [Theme.current.primaryBackgroundColor, Theme.current.clearBackgroundColor]
    }
}
