//
//  EpisodesCollectionViewLayout.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 19/11/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class EpisodesCollectionViewLayout: UICollectionViewFlowLayout
{
    private var attributesCache: [UICollectionViewLayoutAttributes] = []
    private var contentSize: CGSize = .zero
    private var bounds: CGRect = .zero

    override var collectionViewContentSize: CGSize {
        return contentSize
    }

    override func prepare() {
        guard
            let collectionView = collectionView,
            let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            // workaround to invalidate layout only if bounds size was changed
            collectionView.bounds.size != bounds.size
        else {
            return
        }

        bounds = collectionView.bounds
        attributesCache.removeAll(keepingCapacity: true)
        contentSize = .zero

        for index in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: index, section: 0)

            guard let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) else {
                continue
            }

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.size = size
            attributes.frame.origin.y = sectionInset.top
            attributes.frame.origin.x = sectionInset.left + CGFloat(index) * (size.width + minimumInteritemSpacing)

            contentSize.height = max(contentSize.height, attributes.size.height + sectionInset.vertical)
            contentSize.width = attributes.frame.origin.x + size.width + sectionInset.right

            attributesCache.append(attributes)
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributesCache[indexPath.item]
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesCache.filter { $0.frame.intersects(rect) }
    }

    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        (context as? UICollectionViewFlowLayoutInvalidationContext)?.invalidateFlowLayoutDelegateMetrics
            = newBounds.size != collectionView?.bounds.size
        return context
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.size != collectionView?.bounds.size
    }

    override func invalidateLayout() {
        super.invalidateLayout()
        bounds = .zero
    }
}
