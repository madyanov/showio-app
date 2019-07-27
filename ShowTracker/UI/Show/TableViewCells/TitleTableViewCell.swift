//
//  TitleTableViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 11/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class TitleTableViewCell: UITableViewCell
{
    var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setTextStyle(.title2)
        return label
    }()

    private lazy var topLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentView.addSubview(topLineView)

        titleLabel.snap(insets: UIEdgeInsets(top: .standardSpacing * 2,
                                             left: .standardSpacing * 3,
                                             bottom: .standardSpacing,
                                             right: .standardSpacing * 3))

        NSLayoutConstraint.activate([
            topLineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .standardSpacing * 3),
            topLineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topLineView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topLineView.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        startListenForThemeChange()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TitleTableViewCell: ThemeChanging
{
    @objc
    func didChangeTheme() {
        titleLabel.textColor = Theme.current.primaryForegroundColor
        topLineView.backgroundColor = Theme.current.primaryForegroundColor.withAlphaComponent(0.1)
    }
}
