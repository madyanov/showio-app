//
//  ProgressBarView.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 30/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

final class ProgressBarView: UIView
{
    var progress: Float = 0 {
        didSet { setNeedsLayout() }
    }

    var height: CGFloat = 4 {
        didSet {
            layer.cornerRadius = cornerRadius
            filledView.layer.cornerRadius = cornerRadius
        }
    }

    var shouldRoundCorners = true {
        didSet {
            layer.cornerRadius = cornerRadius
            filledView.layer.cornerRadius = cornerRadius
        }
    }

    private lazy var filledView: GradientView = {
        let gradientView = GradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.layer.cornerRadius = cornerRadius
        gradientView.layer.masksToBounds = true
        gradientView.startPoint = CGPoint(x: 0, y: 0.5)
        gradientView.endPoint = CGPoint(x: 1, y: 0.5)
        return gradientView
    }()

    private lazy var filledViewWidthConstraint = filledView.widthAnchor.constraint(equalToConstant: 0)

    private var cornerRadius: CGFloat {
        return shouldRoundCorners ? height / 2 : 0
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: height)
    }

    convenience init() {
        self.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.1)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true

        addSubview(filledView)

        NSLayoutConstraint.activate([
            filledViewWidthConstraint,
            filledView.topAnchor.constraint(equalTo: topAnchor),
            filledView.bottomAnchor.constraint(equalTo: bottomAnchor),
            filledView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])

        startListenForThemeChange()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        filledViewWidthConstraint.constant = bounds.width * CGFloat(progress)
    }

    func setProgress(_ progress: Float, animated: Bool = false) {
        self.progress = progress

        guard animated else {
            return
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.layoutIfNeeded()
        })
    }
}

extension ProgressBarView: ThemeChanging
{
    @objc
    func didChangeTheme() {
        filledView.colors = [Theme.current.primaryBrandColor, Theme.current.secondaryBrandColor]
    }
}
