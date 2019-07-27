//
//  CollapsedText.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 17/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class CollapsedText: UIView
{
    var isCollapsed = true {
        didSet {
            if isCollapsed {
                textLabel.numberOfLines = collapsedNumberOfLines
                readMoreButton.setTitle(readMoreButtonTitle, for: .normal)
            } else {
                textLabel.numberOfLines = 0
                readMoreButton.setTitle(readLessButtonTitle, for: .normal)
            }
        }
    }

    var collapsedNumberOfLines = 3 {
        didSet {
            if isCollapsed {
                textLabel.numberOfLines = collapsedNumberOfLines
            }
        }
    }

    var hasReadMoreButton = false {
        didSet {
            readMoreButton.isHidden = !hasReadMoreButton
            textLabel.isUserInteractionEnabled = !hasReadMoreButton
        }
    }

    var text: String? {
        get { return textLabel.text }
        set {
            let text = newValue?.isEmpty ?? true
                ? "No description available.".localized(comment: "Default episode description")
                : newValue

            textLabel.text = text
        }
    }

    var onTapReadMoreButton: (() -> Void)?

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.setTextStyle(.body)
        label.contentMode = .top
        label.numberOfLines = collapsedNumberOfLines
        label.setContentCompressionResistancePriority(.highest, for: .vertical)
        label.isUserInteractionEnabled = !hasReadMoreButton
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapReadMoreButton)))
        return label
    }()

    private lazy var readMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTextStyle(.body)
        button.setTitle(readMoreButtonTitle, for: .normal)
        button.setContentCompressionResistancePriority(.highest, for: .vertical)
        button.setContentHuggingPriority(.highest, for: .vertical)
        button.addTarget(self, action: #selector(didTapReadMoreButton), for: .touchUpInside)
        button.contentVerticalAlignment = .top
        button.contentHorizontalAlignment = .left
        button.isHidden = !hasReadMoreButton

        if #available(iOS 11.0, *) {
            button.contentHorizontalAlignment = .leading
        }

        return button
    }()

    private let readMoreButtonTitle = "Read More".localized(comment: "Read More button title")
    private let readLessButtonTitle = "Read Less".localized(comment: "Read Less button title")

    convenience init() {
        self.init(frame: .zero)

        addSubview(contentStackView)
        contentStackView.addArrangedSubview(textLabel)
        contentStackView.addArrangedSubview(readMoreButton)

        contentStackView.snap()

        startListenForThemeChange()
    }
}

extension CollapsedText: ThemeChanging
{
    @objc
    func didChangeTheme() {
        textLabel.textColor = Theme.current.primaryForegroundColor
        readMoreButton.setTitleColor(Theme.current.primaryBrandColor, for: .normal)
    }
}

extension CollapsedText
{
    @objc
    private func didTapReadMoreButton() {
        isCollapsed.toggle()
        onTapReadMoreButton?()
    }
}
