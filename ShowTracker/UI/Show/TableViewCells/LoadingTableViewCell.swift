//
//  LoadingTableViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 18/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class LoadingTableViewCell: UITableViewCell
{
    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(activityIndicatorView)
        activityIndicatorView.center()

        startListenForThemeChange()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                          verticalFittingPriority: UILayoutPriority) -> CGSize
    {
        var targetSize = targetSize

        if traitCollection.verticalSizeClass == .regular {
            targetSize.height = 400
        } else {
            targetSize.height = 200
        }

        return targetSize
    }
}

extension LoadingTableViewCell: ThemeChanging
{
    @objc
    func didChangeTheme() {
        activityIndicatorView.style = Theme.current.activityIndicatorStyle
    }
}
