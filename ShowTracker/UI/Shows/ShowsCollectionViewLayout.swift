//
//  ShowsCollectionViewLayout.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 30/09/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit

final class ShowsCollectionViewLayout: UICollectionViewFlowLayout
{
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath)
        -> UICollectionViewLayoutAttributes?
    {
        let layoutAttributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)?.copy()
            as? UICollectionViewLayoutAttributes
        updateLayoutAttributes(layoutAttributes)
        return layoutAttributes
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath)
        -> UICollectionViewLayoutAttributes?
    {
        let layoutAttributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)?.copy()
            as? UICollectionViewLayoutAttributes
        updateLayoutAttributes(layoutAttributes)
        return layoutAttributes
    }

    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        (context as? UICollectionViewFlowLayoutInvalidationContext)?.invalidateFlowLayoutDelegateMetrics =
            newBounds.size != collectionView?.bounds.size
        return context
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.size != collectionView?.bounds.size
    }
}

extension ShowsCollectionViewLayout
{
    private func updateLayoutAttributes(_ layoutAttributes: UICollectionViewLayoutAttributes?) {
        layoutAttributes?.alpha = 0
        layoutAttributes?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
    }
}
