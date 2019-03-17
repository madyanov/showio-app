//
//  TagsView.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 12/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import Foundation
import UIKit

class TagsView: UIView {
    var tags: [String]? {
        didSet { setNeedsLayout() }
    }

    var tagClass = TagView.self {
        didSet { setNeedsLayout() }
    }

    var spacing: CGFloat = 8 {
        didSet { setNeedsLayout() }
    }

    var maximumNumberOfRows = 2 {
        didSet { setNeedsLayout() }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: height)
    }

    private var height: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { $0.removeFromSuperview() }

        var origin = CGPoint.zero
        var row = 1

        for tag in tags ?? [] {
            let tagView = tagClass.init(title: tag)
            let size = tagView.intrinsicContentSize

            tagView.frame.size = size

            if origin.x + size.width > bounds.width {
                if row >= maximumNumberOfRows, maximumNumberOfRows > 0 {
                    break
                }

                origin.x = 0
                origin.y += size.height + spacing
                row += 1
            }

            tagView.frame.origin = origin
            origin.x += size.width + spacing

            addSubview(tagView)
            height = size.height
        }

        height += origin.y
        invalidateIntrinsicContentSize()
    }
}

class TagView: UIButton {
    var insets = UIEdgeInsets(dx: 8, dy: 4) {
        didSet { invalidateIntrinsicContentSize() }
    }

    var title: String? {
        get { return titleLabel?.text }
        set { setTitle(newValue, for: .normal) }
    }

    override var intrinsicContentSize: CGSize {
        guard let titleLabel = titleLabel else {
            return .zero
        }

        let rect = CGRect(
            origin: .zero,
            size: titleLabel.intrinsicContentSize
        ).inset(by: insets.inversed)

        return rect.size
    }

    required init(title: String) {
        super.init(frame: .zero)
        self.title = title

        titleLabel?.setTextStyle(.footnote)

        layer.borderColor = UIColor.white.withAlphaComponent(0.67).cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = intrinsicContentSize.height / 2
        layer.allowsEdgeAntialiasing = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
