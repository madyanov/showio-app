//
//  EndingCollectionViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 23/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class EndingCollectionViewCell: UICollectionViewCell
{
    enum Style
    {
        case loading
        case finished
        case pending(String?)
    }

    var style = Style.loading {
        didSet {
            activityIndicatorView.isHidden = true
            activityIndicatorView.stopAnimating()
            finishFlagImageView.isHidden = true

            switch style {
            case .loading:
                activityIndicatorView.isHidden = false
                activityIndicatorView.startAnimating()
            case .finished:
                finishFlagImageView.isHidden = false
            case .pending(let localizedNextEpisodeAirDate):
                clockImageView.isHidden = false
                nextEpisodeAirDateLabel.isHidden = localizedNextEpisodeAirDate == nil
                nextEpisodeAirDateLabel.text = localizedNextEpisodeAirDate
            }
        }
    }

    private lazy var containerLayoutGuide = UILayoutGuide()

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .gray)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }()

    private lazy var finishFlagImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "flag-checkered-100"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private lazy var clockImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "clock-100"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private lazy var imageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var nextEpisodeAirDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(activityIndicatorView)
        contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(finishFlagImageView)
        imageContainerView.addSubview(clockImageView)
        contentView.addSubview(nextEpisodeAirDateLabel)

        contentView.addLayoutGuide(containerLayoutGuide)

        activityIndicatorView.center(in: containerLayoutGuide)
        imageContainerView.center(in: containerLayoutGuide)
        finishFlagImageView.snap()
        clockImageView.snap()

        NSLayoutConstraint.activate([
            containerLayoutGuide.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerLayoutGuide.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            containerLayoutGuide.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            containerLayoutGuide.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),

            nextEpisodeAirDateLabel.topAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 32),
            nextEpisodeAirDateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nextEpisodeAirDateLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -32),
        ])

        startListenForThemeChange()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EndingCollectionViewCell: ThemeChanging
{
    @objc
    func didChangeTheme() {
        finishFlagImageView.tintColor = Theme.current.primaryBrandColor.withAlphaComponent(0.67)
        clockImageView.tintColor = Theme.current.primaryBrandColor.withAlphaComponent(0.67)
        nextEpisodeAirDateLabel.textColor = Theme.current.primaryBrandColor
    }
}
