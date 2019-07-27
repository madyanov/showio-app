//
//  OverviewTableViewCell.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 30/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

final class OverviewTableViewCell: UITableViewCell
{
    var model: Show? {
        didSet { overviewText.text = model?.overview }
    }

    var isCollapsed: Bool = true {
        didSet { overviewText.isCollapsed = isCollapsed }
    }

    var onTapReadMoreButton: (() -> Void)? {
        didSet { overviewText.onTapReadMoreButton = onTapReadMoreButton }
    }

    private lazy var overviewText: CollapsedText = {
        let collapsedText = CollapsedText()
        collapsedText.translatesAutoresizingMaskIntoConstraints = false
        collapsedText.onTapReadMoreButton = onTapReadMoreButton
        return collapsedText
    }()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(overviewText)
        overviewText.snap(insets: UIEdgeInsets(dx: .standardSpacing * 3, dy: .standardSpacing * 2))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
