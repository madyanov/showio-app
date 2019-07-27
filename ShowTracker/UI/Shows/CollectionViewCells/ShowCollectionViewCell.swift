//
//  ShowCollectionViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 24/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

protocol ShowCollectionViewCellDelegate: AnyObject
{
    func willDelete(cell: ShowCollectionViewCell)
    func didTap(on cell: ShowCollectionViewCell)
}

final class ShowCollectionViewCell: UICollectionViewCell
{
    enum Style
    {
        case `default`
        case minimal
    }

    weak var delegate: ShowCollectionViewCellDelegate?

    var isPersistentPosterImageCaching = false
    var shouldCancelTapGesture = false

    var style = Style.default {
        didSet {
            nameLabel.setTextStyle(style == .default ? .body : .footnote)
            yearLabel.setTextStyle(style == .default ? .callout : .footnote)
        }
    }

    var model: Show? {
        didSet {
            if model != oldValue {
                posterImageView.setImage(with: model?.posterURL, persistent: isPersistentPosterImageCaching)
            }

            nameLabel.text = model?.name
            yearLabel.text = model?.firstAirDate?.year
            isDummy = model?.isDummy ?? false
            progressBarView.progress = model?.progress ?? 0
            progressBarView.isHidden = progressBarView.progress == 0

            if let numberOfNewEpisodes = model?.numberOfNewEpisodes, numberOfNewEpisodes > 0 {
                numberOfNewEpisodesButton.isHidden = false
                numberOfNewEpisodesButton.setTitle("+\(numberOfNewEpisodes)", for: .normal)
            } else {
                numberOfNewEpisodesButton.isHidden = true
            }
        }
    }

    lazy var posterImageView: CachedImageView = {
        let cachedImageView = CachedImageView()
        cachedImageView.translatesAutoresizingMaskIntoConstraints = false
        cachedImageView.backgroundColor = .clear
        cachedImageView.contentMode = .scaleAspectFill
        cachedImageView.layer.cornerRadius = .standardSpacing / 2
        cachedImageView.layer.masksToBounds = true
        return cachedImageView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .standardSpacing
        return stackView
    }()

    private lazy var posterContainerView: UIView = {
        let view = UIView()
        view.layer.shadowRadius = .standardSpacing
        view.layer.shadowOffset = CGSize(width: 0, height: .standardSpacing / 2)
        view.layer.shadowOpacity = 0.2
        return view
    }()

    private lazy var progressBarView: ProgressBarView = {
        let progressBarView = ProgressBarView()
        progressBarView.translatesAutoresizingMaskIntoConstraints = false
        progressBarView.shouldRoundCorners = false
        return progressBarView
    }()

    private lazy var footerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = .standardSpacing / 2
        return stackView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.body)
        return label
    }()

    private lazy var yearLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.callout)
        return label
    }()

    private lazy var dummyBlurredOverlay: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.alpha = 0
        return visualEffectView
    }()

    private lazy var dummyActivityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .white)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicatorView
    }()

    private lazy var numberOfNewEpisodesButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.contentEdgeInsets = UIEdgeInsets(dx: 6, dy: .standardSpacing / 2)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("+4", for: .normal)
        button.setTextStyle(.footnote)
        button.backgroundColor = UIColor.red.withAlphaComponent(0.9)
        button.layer.cornerRadius = .standardSpacing / 2
        return button
    }()

    private lazy var touchGestureRecognizer: UILongPressGestureRecognizer = {
        let longPresGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didTouch))
        longPresGestureRecognizer.delegate = self
        longPresGestureRecognizer.minimumPressDuration = 0
        return longPresGestureRecognizer
    }()

    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))

    private var isDummy = false {
        didSet {
            if isDummy {
                dummyActivityIndicatorView.startAnimating()
                dummyBlurredOverlay.alpha = 1
            } else {
                dummyActivityIndicatorView.startAnimating()

                UIView.animate(withDuration: 0.3) {
                    self.dummyBlurredOverlay.alpha = 0
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(touchGestureRecognizer)
        addGestureRecognizer(tapGestureRecognizer)

        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(posterContainerView)
        posterContainerView.addSubview(posterImageView)
        posterImageView.addSubview(progressBarView)
        contentStackView.addArrangedSubview(footerStackView)
        footerStackView.addArrangedSubview(nameLabel)
        footerStackView.addArrangedSubview(yearLabel)
        posterImageView.addSubview(dummyBlurredOverlay)
        posterImageView.addSubview(numberOfNewEpisodesButton)
        dummyBlurredOverlay.contentView.addSubview(dummyActivityIndicatorView)

        contentStackView.snap()
        posterImageView.snap()
        dummyBlurredOverlay.snap()
        dummyActivityIndicatorView.center()

        NSLayoutConstraint.activate([
            posterImageView.heightAnchor.constraint(equalTo: posterImageView.widthAnchor, multiplier: 1.5),

            progressBarView.leadingAnchor.constraint(equalTo: posterImageView.leadingAnchor),
            progressBarView.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor),
            progressBarView.bottomAnchor.constraint(equalTo: posterImageView.bottomAnchor),

            numberOfNewEpisodesButton.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor,
                                                                constant: -(.standardSpacing / 2)),

            numberOfNewEpisodesButton.topAnchor.constraint(equalTo: posterImageView.topAnchor,
                                                           constant: .standardSpacing / 2),
        ])

        startListenForThemeChange()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // workaround to set correct shadow path after device rotation
        DispatchQueue.main.async {
            self.posterContainerView.layer.shadowPath = UIBezierPath(
                roundedRect: self.posterContainerView.layer.bounds,
                cornerRadius: self.posterImageView.layer.cornerRadius
            ).cgPath
        }
    }

    @objc
    func deleteAction() {
        delegate?.willDelete(cell: self)
    }
}

extension ShowCollectionViewCell: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
}

extension ShowCollectionViewCell: ThemeChanging
{
    @objc
    func didChangeTheme() {
        progressBarView.backgroundColor = Theme.current.primaryBackgroundColor.withAlphaComponent(0.8)
        nameLabel.textColor = Theme.current.primaryForegroundColor
        yearLabel.textColor = Theme.current.secondaryForegroundColor
    }
}

extension ShowCollectionViewCell
{
    @objc
    private func didTouch(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard !isDummy else {
            return
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: {
            switch gestureRecognizer.state {
            case .began:
                self.shouldCancelTapGesture = false
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            default:
                self.transform = .identity
            }
        })
    }

    @objc
    private func didTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard !isDummy, !shouldCancelTapGesture else {
            return
        }

        delegate?.didTap(on: self)
    }
}
