//
//  ProgressView.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 10/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class ProgressView: UIView
{
    var spacing: CGFloat = .standardSpacing {
        didSet { contentStackView.spacing = spacing }
    }

    var textStyle = UIFont.TextStyle.body {
        didSet {
            leadingLabel.setTextStyle(textStyle)
            trailingLabel.setTextStyle(textStyle)
        }
    }

    var progressBarHeight: CGFloat = .standardSpacing {
        didSet { progressBarView.height = progressBarHeight }
    }

    var hasLabels = true {
        didSet {
            leadingLabel.isHidden = !hasLabels
            trailingLabel.isHidden = !hasLabels
        }
    }

    var leadingLabelText: String? {
        get { return leadingLabel.text }
        set { leadingLabel.text = newValue }
    }

    var trailingLabelText: String? {
        get { return trailingLabel.text }
        set { trailingLabel.text = newValue }
    }

    var progress: Float {
        get { return progressBarView.progress }
        set { progressBarView.progress = newValue }
    }

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = spacing
        return stackView
    }()

    private lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = .standardSpacing
        return stackView
    }()

    private lazy var leadingLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(textStyle)
        label.isHidden = !hasLabels
        return label
    }()

    private lazy var trailingLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(textStyle)
        label.isHidden = !hasLabels
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private lazy var progressBarView: ProgressBarView = {
        let progressBarView = ProgressBarView()
        progressBarView.height = progressBarHeight
        return progressBarView
    }()

    convenience init() {
        self.init(frame: .zero)

        addSubview(contentStackView)
        contentStackView.addArrangedSubview(labelsStackView)
        labelsStackView.addArrangedSubview(leadingLabel)
        labelsStackView.addArrangedSubview(trailingLabel)
        contentStackView.addArrangedSubview(progressBarView)

        contentStackView.snap()

        startListenForThemeChange()
    }

    func setProgress(_ progress: Float, animated: Bool = false) {
        progressBarView.setProgress(progress, animated: animated)
    }
}

extension ProgressView: ThemeChanging
{
    @objc
    func didChangeTheme() {
        leadingLabel.textColor = Theme.current.secondaryForegroundColor
        trailingLabel.textColor = Theme.current.secondaryForegroundColor
    }
}
