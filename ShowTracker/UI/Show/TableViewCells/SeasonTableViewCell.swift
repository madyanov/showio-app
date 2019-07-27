//
//  SeasonTableViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 07/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class SeasonTableViewCell: UITableViewCell
{
    private lazy var progressView: ProgressView = {
        let progressView = ProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(progressView)
        progressView.snap(insets: UIEdgeInsets(dx: .standardSpacing * 3, dy: .standardSpacing * 2))
    }

    func setModel(_ season: Season?, show: Show?, animated: Bool = false) {
        guard let season = season else {
            progressView.setProgress(0, animated: animated)
            progressView.leadingLabelText = nil
            progressView.trailingLabelText = nil
            return
        }

        let seasonName = season.name ?? "Season %d".localized(comment: "Default season name", season.number)
        progressView.leadingLabelText = "\(season.number). \(seasonName)"
        progressView.trailingLabelText = "\(season.numberOfViewedEpisodes)/\(season.numberOfEpisodes)"
        progressView.setProgress(season.progress, animated: animated)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
