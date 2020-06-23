//
//  ShowTransitionAnimator.swift
//  ShowTracker
//
//  Created by Roman Madyanov on 27/10/2018.
//  Copyright © 2018 Roman Madyanov. All rights reserved.
//

import UIKit
import Toolkit

protocol ShowTransitionSubviewsAnimating
{
    var animatedSubviews: [UIView] { get set }
}

protocol ShadedAndRounded
{
    var viewWithShadow: UIView? { get }
    var viewWithRoundedCorners: UIView? { get }

    func roundCornersAndAddShadow()
    func removeRoundedCornersAndShadow()
}

extension ShadedAndRounded
{
    func roundCornersAndAddShadow() {
        if let viewWithShadow = viewWithShadow {
            viewWithShadow.layer.shadowRadius = .standardSpacing * 2
            viewWithShadow.layer.shadowOffset = .zero
            viewWithShadow.layer.shadowOpacity = 0.3
            viewWithShadow.layer.masksToBounds = false

            viewWithShadow.layer.shadowPath = UIBezierPath(roundedRect: viewWithShadow.layer.bounds,
                                                           byRoundingCorners: [.topLeft, .topRight],
                                                           cornerRadii: CGSize(width: 30, height: 30)).cgPath
        }

        if let viewWithRoundedCorners = viewWithRoundedCorners {
            viewWithRoundedCorners.layer.cornerRadius = 30
            viewWithRoundedCorners.layer.masksToBounds = true
        }
    }

    func removeRoundedCornersAndShadow() {
        viewWithShadow?.layer.shadowRadius = 0
        viewWithShadow?.layer.masksToBounds = true

        viewWithRoundedCorners?.layer.cornerRadius = 0
        viewWithRoundedCorners?.layer.masksToBounds = false
    }
}

final class ShowTransitionAnimator: NSObject
{
    var maximumRegularWidth: CGFloat = 700
    var minimumInsets = UIEdgeInsets(top: .standardSpacing * 2, left: 88, bottom: 0, right: 88)

    private var isPresentation = false
}

extension ShowTransitionAnimator: UIViewControllerAnimatedTransitioning
{
    private typealias ViewControllerAnimatingSubviews = UIViewController & ShowTransitionSubviewsAnimating

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresentation ? 0.5 : 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresentation {
            animatePresentation(using: transitionContext)
        } else {
            animateDismission(using: transitionContext)
        }
    }
}

extension ShowTransitionAnimator: UIViewControllerTransitioningDelegate
{
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        isPresentation = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresentation = false
        return self
    }

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController?
    {
        return ShowPresentationController(presentedViewController: presented,
                                          presenting: presenting,
                                          maximumRegularWidth: maximumRegularWidth,
                                          minimumInsets: minimumInsets)
    }
}

extension ShowTransitionAnimator
{
    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toView = transitionContext.view(forKey: .to),
            let toViewController = transitionContext.viewController(forKey: .to) as? ViewControllerAnimatingSubviews,
            let fromNavigationController = transitionContext.viewController(forKey: .from) as? UINavigationController,
            let fromViewController = fromNavigationController.topViewController as? ViewControllerAnimatingSubviews
        else {
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toViewController)

        containerView.addSubview(toView)
        toView.frame = finalFrame.offsetBy(dx: 0, dy: finalFrame.size.height)
        toView.layoutIfNeeded()

        let snapshots = initializeAnimatedSnapshots(containerView: containerView,
                                                    fromViewController: fromViewController,
                                                    toViewController: toViewController)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [],
            animations: {
                toView.frame = finalFrame
                self.animateSnapshots(snapshots, containerView: containerView, toViewController: toViewController)
            },
            completion: { _ in
                self.cleanupSnapshots(snapshots, toViewController: toViewController) { finished in
                    transitionContext.completeTransition(finished)
                }
            }
        )
    }

    private func animateDismission(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromView = transitionContext.view(forKey: .from),
            let fromViewController = transitionContext.viewController(forKey: .from)
                as? ViewControllerAnimatingSubviews,
            let toNavigationController = transitionContext.viewController(forKey: .to) as? UINavigationController,
            let toViewController = toNavigationController.topViewController as? ViewControllerAnimatingSubviews
        else {
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: fromViewController)
        fromView.frame = finalFrame

        let snapshots = initializeAnimatedSnapshots(containerView: containerView,
                                                    fromViewController: fromViewController,
                                                    toViewController: toViewController)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromView.frame = finalFrame.offsetBy(dx: 0, dy: finalFrame.size.height)
            self.animateSnapshots(snapshots, containerView: containerView, toViewController: toViewController)
        }, completion: { _ in
            self.cleanupSnapshots(snapshots, toViewController: toViewController) { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(finished)
            }
        })
    }

    private func initializeAnimatedSnapshots(containerView: UIView,
                                             fromViewController: ShowTransitionSubviewsAnimating,
                                             toViewController: ShowTransitionSubviewsAnimating) -> [UIView]
    {
        fromViewController.animatedSubviews.forEach { $0.alpha = 1 }
        toViewController.animatedSubviews.forEach { $0.alpha = 1 }

        guard !toViewController.animatedSubviews.isEmpty else {
            return []
        }

        let snapshots = fromViewController.animatedSubviews.compactMap { subview -> UIView? in
            let snapshot = subview.snapshotView(afterScreenUpdates: false)
            snapshot?.frame = containerView.convert(subview.frame, from: subview.superview)
            return snapshot
        }

        guard !snapshots.isEmpty else {
            return []
        }

        snapshots.forEach { containerView.addSubview($0) }
        fromViewController.animatedSubviews.forEach { $0.alpha = 0 }
        toViewController.animatedSubviews.forEach { $0.alpha = 0 }
        return snapshots
    }

    private func animateSnapshots(_ snapshots: [UIView],
                                  containerView: UIView,
                                  toViewController: ShowTransitionSubviewsAnimating)
    {
        zip(snapshots, toViewController.animatedSubviews).forEach { snapshot, subview in
            snapshot.frame = containerView.convert(subview.frame, from: subview.superview)
        }
    }

    private func cleanupSnapshots(_ snapshots: [UIView],
                                  toViewController: ShowTransitionSubviewsAnimating,
                                  completion: ((Bool) -> Void)? = nil)
    {
        toViewController.animatedSubviews.forEach { $0.alpha = 1 }
        snapshots.forEach { $0.alpha = 1 }

        UIView.animate(withDuration: 0.3, animations: {
            snapshots.forEach { $0.alpha = 0 }
        }, completion: { finished in
            snapshots.forEach { $0.removeFromSuperview() }
            completion?(finished)
        })
    }
}

private final class ShowPresentationController: UIPresentationController {
    private var maximumRegularWidth: CGFloat
    private var minimumInsets: UIEdgeInsets

    private lazy var blurredOverlayView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: nil)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        return visualEffectView
    }()

    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame = super.frameOfPresentedViewInContainerView

        if traitCollection.horizontalSizeClass == .regular {
            let width = min(maximumRegularWidth, frame.size.width - minimumInsets.horizontal)
            frame.origin.x = (frame.size.width - width) / 2
            frame.origin.y = presentingViewController.topLayoutGuide.length + minimumInsets.top
            frame.size.width = width
            frame.size.height -= frame.origin.y
        }

        return frame
    }

    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         maximumRegularWidth: CGFloat,
         minimumInsets: UIEdgeInsets)
    {
        self.maximumRegularWidth = maximumRegularWidth
        self.minimumInsets = minimumInsets

        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        blurredOverlayView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func presentationTransitionWillBegin() {
        containerView?.addSubview(blurredOverlayView)
        blurredOverlayView.snap()

        let blurEffect = UIBlurEffect(style: Theme.current.blurStyle)

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurredOverlayView.effect = blurEffect
        })
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            blurredOverlayView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurredOverlayView.effect = nil
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            blurredOverlayView.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView

        if traitCollection.horizontalSizeClass == .regular {
            roundCornersAndAddShadow()
        } else {
            removeRoundedCornersAndShadow()
        }
    }
}

extension ShowPresentationController
{
    private func roundCornersAndAddShadow() {
        if let viewController = presentedViewController as? ShadedAndRounded {
            viewController.roundCornersAndAddShadow()
        }
    }

    private func removeRoundedCornersAndShadow() {
        if let viewController = presentedViewController as? ShadedAndRounded {
            viewController.removeRoundedCornersAndShadow()
        }
    }

    @objc
    private func didTap() {
        presentingViewController.dismiss(animated: true)
    }
}
