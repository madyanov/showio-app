//
//  ProgressTableViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 06/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class ProgressTableViewCell: UITableViewCell
{
    private lazy var progressView: ProgressView = {
        let progressView = ProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.leadingLabelText = "Total progress".localized(comment: "Total progress label")
        return progressView
    }()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(progressView)
        progressView.snap(insets: UIEdgeInsets(dx: .standardSpacing * 3, dy: .standardSpacing * 2))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setModel(_ show: Show?, animated: Bool = false) {
        progressView.setProgress(show?.progress ?? 0, animated: animated)
        progressView.trailingLabelText = show.map { "\($0.numberOfViewedEpisodes)/\($0.numberOfEpisodes)" }
    }
}
