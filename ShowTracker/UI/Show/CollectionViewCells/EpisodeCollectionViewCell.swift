//
//  EpisodeCollectionViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 16/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

protocol EpisodeCollectionViewCellDelegate: AnyObject
{
    func didTapViewButton(in episodeCollectionViewCell: EpisodeCollectionViewCell)
}

final class EpisodeCollectionViewCell: UICollectionViewCell
{
    weak var delegate: EpisodeCollectionViewCellDelegate?

    var model: Episode? {
        didSet {
            if model != oldValue {
                stillImageView.setImage(with: model?.stillURL,
                                        placeholderURL: model?.show?.value.backdropURL ?? model?.show?.value.posterURL)
            }

            seasonAndEpisodeLabel.text = "S%02dE%02d".localized(comment: "Season & episode number",
                                                                model?.seasonNumber ?? 0,
                                                                model?.number ?? 0)

            nameLabel.text = model?.name
            overviewText.text = model?.overview
            viewButton.isViewed = model?.canView == true ? model?.isViewed == true : nil

            if let localizedAirDate = model?.localizedAirDate {
                airDateContainerView.isHidden = false
                airDateLabel.text = localizedAirDate
            } else {
                airDateContainerView.isHidden = true
            }
        }
    }

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .standardSpacing * 2
        return stackView
    }()

    private lazy var stillImageView: CachedImageView = {
        let cachedImageView = CachedImageView()
        cachedImageView.translatesAutoresizingMaskIntoConstraints = false
        cachedImageView.backgroundColor = .clear
        cachedImageView.layer.cornerRadius = .standardSpacing
        cachedImageView.layer.masksToBounds = true
        cachedImageView.contentMode = .scaleAspectFill
        return cachedImageView
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .standardSpacing
        stackView.alignment = .center
        return stackView
    }()

    private lazy var nameStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .standardSpacing / 2
        return stackView
    }()

    private lazy var seasonAndEpisodeLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.title3)
        label.setContentCompressionResistancePriority(.highest, for: .vertical)
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.headline)
        label.setContentCompressionResistancePriority(.highest, for: .vertical)
        return label
    }()

    private lazy var viewButton: ViewButton = {
        let viewButton = ViewButton()
        viewButton.delegate = self
        viewButton.size = CGSize(width: .tappableSize, height: .tappableSize)
        viewButton.setContentHuggingPriority(.required, for: .horizontal)
        viewButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        return viewButton
    }()

    private lazy var airDateContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = .standardSpacing / 2
        return view
    }()

    private lazy var airDateStacKView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }()

    private lazy var airDateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "clock-18"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.highest, for: .vertical)
        return imageView
    }()

    private lazy var airDateLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.body)
        return label
    }()

    private lazy var overviewText: CollapsedText = {
        let collapsedText = CollapsedText()

        collapsedText.onTapReadMoreButton = { [weak self] in
            guard let self = self else {
                return
            }

            UIView.animate(withDuration: 0.3) {
                self.contentStackView.layoutIfNeeded()

                UIView.animate(withDuration: 0.3) {
                    if self.stillImageView.alpha == 0 {
                        self.stillImageView.alpha = 1
                    } else if self.stillImageView.frame.height < self.stillImageView.layer.cornerRadius * 2 {
                        self.stillImageView.alpha = 0
                    }
                }
            }
        }

        return collapsedText
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(stillImageView)
        contentStackView.addArrangedSubview(headerStackView)
        headerStackView.addArrangedSubview(nameStackView)
        nameStackView.addArrangedSubview(seasonAndEpisodeLabel)
        nameStackView.addArrangedSubview(nameLabel)
        headerStackView.addArrangedSubview(viewButton)
        contentStackView.addArrangedSubview(airDateContainerView)
        airDateContainerView.addSubview(airDateStacKView)
        airDateStacKView.addArrangedSubview(airDateImageView)
        airDateStacKView.addArrangedSubview(airDateLabel)
        contentStackView.addArrangedSubview(overviewText)

        airDateStacKView.snap(insets: UIEdgeInsets(.standardSpacing * 1.5), priority: .highest)

        NSLayoutConstraint.activate([
            contentStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            contentStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            stillImageView.heightAnchor.constraint(lessThanOrEqualTo: stillImageView.widthAnchor, multiplier: 0.4),
        ])

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
        ], priority: .highest - 1)

        NSLayoutConstraint.activate([
            stillImageView.heightAnchor.constraint(equalTo: stillImageView.widthAnchor, multiplier: 0.4),
        ], priority: .defaultHigh)

        startListenForThemeChange()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        overviewText.isCollapsed = true
        stillImageView.alpha = 1
    }
}

extension EpisodeCollectionViewCell: ThemeChanging
{
    @objc
    func didChangeTheme() {
        seasonAndEpisodeLabel.textColor = Theme.current.primaryForegroundColor
        nameLabel.textColor = Theme.current.primaryForegroundColor
        airDateContainerView.backgroundColor = Theme.current.primaryBrandColor.withAlphaComponent(0.05)
        airDateImageView.tintColor = Theme.current.primaryBrandColor
        airDateLabel.textColor = Theme.current.primaryBrandColor
    }
}

extension EpisodeCollectionViewCell: ViewButtonDelegate
{
    func didTapViewButton(in viewButton: ViewButton) {
        delegate?.didTapViewButton(in: self)
    }

    func didTapUnseeButton(in viewButton: ViewButton) {
        // do nothing
    }
}
