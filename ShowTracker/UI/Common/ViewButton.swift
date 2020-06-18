//
//  ViewButton.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 22.03.2020.
//  Copyright © 2020 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

protocol ViewButtonDelegate: AnyObject
{
    func didTapViewButton(in viewButton: ViewButton)
    func didTapUnseeButton(in viewButton: ViewButton)
}

final class ViewButton: UIView
{
    weak var delegate: ViewButtonDelegate?

    var size = CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)

    var isViewed: Bool? {
        didSet {
            let scaledTransform = CGAffineTransform.identity.scaledBy(x: 0.01, y: 0.01)
            viewButton.layer.removeAllAnimations()
            unseeButton.layer.removeAllAnimations()

            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .allowUserInteraction,
                animations: {
                    if self.isViewed == true {
                        self.viewButton.alpha = 0
                        self.unseeButton.alpha = 1
                        self.viewButton.transform = scaledTransform
                        self.unseeButton.transform = .identity
                    } else if self.isViewed == false {
                        self.viewButton.alpha = 1
                        self.unseeButton.alpha = 0
                        self.viewButton.transform = .identity
                        self.unseeButton.transform = scaledTransform
                    } else {
                        self.viewButton.alpha = 0
                        self.unseeButton.alpha = 0
                        self.viewButton.transform = scaledTransform
                        self.unseeButton.transform = scaledTransform
                    }
                },
                completion: nil
            )
        }
    }

    override var intrinsicContentSize: CGSize { size }

    private lazy var viewButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        button.highlightedAlpha = 0.5
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = .standardSpacing
        button.setImage(UIImage(named: "eye-20"), for: .normal)
        button.addTarget(self, action: #selector(didTapViewButton), for: .touchUpInside)
        return button
    }()

    private lazy var unseeButton: Button = {
        let button = Button()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        button.highlightedAlpha = 0.5
        button.setImage(UIImage(named: "check-20"), for: .normal)
        button.addTarget(self, action: #selector(didTapUnseeButton), for: .touchUpInside)
        return button
    }()

    convenience init() {
        self.init(frame: .zero)

        addSubview(viewButton)
        addSubview(unseeButton)

        startListenForThemeChange()

        viewButton.snap()
        unseeButton.snap()

        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
}

extension ViewButton: ThemeChanging
{
    @objc
    func didChangeTheme() {
        unseeButton.tintColor = Theme.current.primaryBrandColor
        viewButton.tintColor = Theme.current.primaryBrandColor
        viewButton.layer.borderColor = Theme.current.primaryBrandColor.withAlphaComponent(0.3).cgColor
    }
}

extension ViewButton
{
    @objc
    private func didTapViewButton() {
        delegate?.didTapViewButton(in: self)
    }

    @objc
    private func didTapUnseeButton() {
        delegate?.didTapUnseeButton(in: self)
    }
}
