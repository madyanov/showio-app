//
//  InfoTableViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 06/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

protocol InfoTableViewCellDelegate: AnyObject
{
    func didTapAddButton(in infoTableViewCell: InfoTableViewCell)
    func didTapDeleteButton(in infoTableViewCell: InfoTableViewCell)
}

final class InfoTableViewCell: UITableViewCell
{
    weak var delegate: InfoTableViewCellDelegate?

    var model: Show? {
        didSet {
            var ratingString: String?
            var episodeDurationString: String?

            if let rating = model?.rating, rating > 0 {
                ratingString = String(format: "%.1f", rating)
            }

            if let episodeRunTime = model?.episodeRunTime, episodeRunTime > 0 {
                episodeDurationString = "%d min".localized(comment: "Episode duration (minutes)", episodeRunTime)
            }

            infoLabel.text = [
                ratingString,
                model?.genre?.truncated(length: 16),
                episodeDurationString,
            ].compactMap { $0 }.joined(separator: " · ")

            starImageContainerView.isHidden = ratingString == nil
        }
    }

    var isShowAlreadyExists: Bool? {
        didSet {
            let scaledTransform = CGAffineTransform.identity.scaledBy(x: 0.01, y: 0.01)

            addButton.isUserInteractionEnabled = false
            deleteButton.isUserInteractionEnabled = false

            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .allowUserInteraction,
                animations: {
                    if self.isShowAlreadyExists == true {
                        self.addButton.alpha = 0
                        self.deleteButton.alpha = 1
                        self.deleteButton.isUserInteractionEnabled = true
                        self.addButton.transform = scaledTransform
                        self.deleteButton.transform = .identity
                    } else if self.isShowAlreadyExists == false {
                        self.addButton.alpha = 1
                        self.deleteButton.alpha = 0
                        self.addButton.isUserInteractionEnabled = true
                        self.addButton.transform = .identity
                        self.deleteButton.transform = scaledTransform
                    } else {
                        self.addButton.alpha = 0
                        self.deleteButton.alpha = 0
                        self.addButton.transform = scaledTransform
                        self.deleteButton.transform = scaledTransform
                    }
                },
                completion: nil
            )
        }
    }

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = .standardSpacing
        return stackView
    }()

    private lazy var infoContainerView = UIView()

    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }()

    private lazy var starImageContainerView = UIView()

    private lazy var starImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "star-18"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.headline)
        return label
    }()

    private lazy var buttonContainerView = UIView()

    private lazy var addButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        button.highlightedAlpha = 0.5
        button.layer.borderWidth = 1
        button.layer.cornerRadius = .standardSpacing * 1.5
        button.setImage(UIImage(named: "plus-20"), for: .normal)
        button.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
        return button
    }()

    private lazy var deleteButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        button.highlightedAlpha = 0.5
        button.setImage(UIImage(named: "check-20"), for: .normal)
        button.addTarget(self, action: #selector(didTapDeleteButton), for: .touchUpInside)
        return button
    }()

    private lazy var bottomLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var buttonSize = CGSize(width: .tappableSize, height: .tappableSize)

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(infoContainerView)
        infoContainerView.addSubview(infoStackView)
        infoStackView.addArrangedSubview(starImageContainerView)
        starImageContainerView.addSubview(starImageView)
        infoStackView.addArrangedSubview(infoLabel)
        contentStackView.addArrangedSubview(buttonContainerView)
        buttonContainerView.addSubview(addButton)
        buttonContainerView.addSubview(deleteButton)
        contentView.addSubview(bottomLineView)

        contentStackView.snap(insets: UIEdgeInsets(dx: .standardSpacing * 3, dy: .standardSpacing * 2))
        starImageView.snap(insets: UIEdgeInsets(top: 0, left: 0, bottom: 3, right: 0))

        buttonContainerView.size(buttonSize)
        deleteButton.snap()

        NSLayoutConstraint.activate([
            infoStackView.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor),
            infoStackView.trailingAnchor.constraint(lessThanOrEqualTo: infoContainerView.trailingAnchor),
            infoStackView.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor),

            bottomLineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .standardSpacing * 3),
            bottomLineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomLineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomLineView.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        startListenForThemeChange()
        addButton.snap()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InfoTableViewCell: ThemeChanging
{
    @objc
    func didChangeTheme() {
        infoLabel.textColor = Theme.current.primaryForegroundColor
        starImageView.tintColor = Theme.current.ratingColor
        deleteButton.tintColor = Theme.current.primaryBrandColor
        bottomLineView.backgroundColor = Theme.current.primaryForegroundColor.withAlphaComponent(0.1)
        addButton.tintColor = Theme.current.primaryBrandColor
        addButton.layer.borderColor = Theme.current.primaryBrandColor.cgColor
    }
}

extension InfoTableViewCell
{
    @objc
    private func didTapAddButton() {
        guard isShowAlreadyExists == false else {
            return
        }

        delegate?.didTapAddButton(in: self)
    }

    @objc
    private func didTapDeleteButton() {
        guard isShowAlreadyExists == true else {
            return
        }

        delegate?.didTapDeleteButton(in: self)
    }
}
