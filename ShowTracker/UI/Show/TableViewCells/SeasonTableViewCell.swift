//
//  SeasonTableViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 07/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

protocol SeasonTableViewCellDelegate: AnyObject
{
    func didTapViewButton(in cell: SeasonTableViewCell)
    func didTapUnseeButton(in cell: SeasonTableViewCell)
}

final class SeasonTableViewCell: UITableViewCell
{
    weak var delegate: SeasonTableViewCellDelegate?

    private(set) var season: Season?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .standardSpacing * 2
        return stackView
    }()

    private lazy var viewButton: ViewButton = {
        let viewButton = ViewButton()
        viewButton.delegate = self
        return viewButton
    }()

    private lazy var progressView = ProgressView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(stackView)
        stackView.addArrangedSubview(viewButton)
        stackView.addArrangedSubview(progressView)

        stackView.snap(insets: UIEdgeInsets(dx: .standardSpacing * 3, dy: .standardSpacing * 2))
    }

    func setModel(_ season: Season?, show: Show?, animated: Bool = false) {
        self.season = season

        viewButton.isViewed = season?.progress == 1

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

extension SeasonTableViewCell: ViewButtonDelegate
{
    func didTapViewButton(in viewButton: ViewButton) {
        delegate?.didTapViewButton(in: self)
    }

    func didTapUnseeButton(in viewButton: ViewButton) {
        delegate?.didTapUnseeButton(in: self)
    }
}
