//
//  APCModalPresentationController.m
//  APCAppCore
//
//  Created by Everest Liu on 2/16/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APCModalPresentationController.h"

@interface APCModalPresentationController () <UIViewControllerAnimatedTransitioning>

@property(nonatomic, strong) UIView *dimmingView;
@property(nonatomic, strong) UIView *presentationView;

@end


@implementation APCModalPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController
					   presentingViewController:(UIViewController *)presentingViewController {
	self = [super initWithPresentedViewController:presentedViewController
						 presentingViewController:presentingViewController];

	if (self) {
		presentedViewController.modalPresentationStyle = UIModalPresentationCustom;
	}

	return self;
}

- (UIView *)presentedView {
	return self.presentationView;
}

- (void)presentationTransitionWillBegin {
	self.presentationView = [super presentedView];

	{
		UIView *dimmingView = [[UIView alloc] initWithFrame:self.containerView.bounds];
		dimmingView.backgroundColor = [UIColor blackColor];
		dimmingView.opaque = NO;
		dimmingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.dimmingView = dimmingView;
		[self.containerView addSubview:dimmingView];

		id <UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentingViewController.transitionCoordinator;

		self.dimmingView.alpha = 0.f;
		[transitionCoordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context) {
			self.dimmingView.alpha = 0.5f;
		}                                      completion:NULL];
	}
}

- (void)presentationTransitionDidEnd:(BOOL)completed {
	if (!completed) {
		self.presentationView = nil;
		self.dimmingView = nil;
	}
}

- (void)dismissalTransitionWillBegin {
	id <UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentingViewController.transitionCoordinator;

	[transitionCoordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context) {
		self.dimmingView.alpha = 0.f;
	}                                      completion:NULL];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed {
	if (completed) {
		self.presentationView = nil;
		self.dimmingView = nil;
	}
}

#pragma mark - Layout

- (void)containerViewWillLayoutSubviews {
	[super containerViewWillLayoutSubviews];

	self.dimmingView.frame = self.containerView.bounds;

	CGSize preferredSize = self.presentedViewController.preferredContentSize;

	self.presentedView.frame = CGRectMake(
		(self.containerView.bounds.size.width - preferredSize.width) / 2,
		(self.containerView.bounds.size.height - preferredSize.height) / 2 - 50,
		preferredSize.width,
		preferredSize.height);
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
	return [transitionContext isAnimated] ? 0.35 : 0;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
	UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
	UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];

	UIView *containerView = transitionContext.containerView;

	BOOL isPresenting = (fromViewController == self.presentingViewController);

	CGRect __unused fromViewInitialFrame = [transitionContext initialFrameForViewController:fromViewController];
	CGRect fromViewFinalFrame = [transitionContext finalFrameForViewController:fromViewController];
	CGRect toViewInitialFrame = [transitionContext initialFrameForViewController:toViewController];
	CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];

	[containerView addSubview:toView];

	if (isPresenting) {
		toViewInitialFrame.origin = CGPointMake(CGRectGetMinX(containerView.bounds), CGRectGetMaxY(containerView.bounds));
		toViewInitialFrame.size = toViewFinalFrame.size;
		toView.frame = toViewInitialFrame;
	} else {
		fromViewFinalFrame = CGRectOffset(fromView.frame, 0, CGRectGetHeight(fromView.frame));
	}

	NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];

	[UIView animateWithDuration:transitionDuration animations:^{
		if (isPresenting)
			toView.frame = toViewFinalFrame;
		else
			fromView.frame = fromViewFinalFrame;

	}                completion:^(BOOL finished) {
		BOOL wasCancelled = [transitionContext transitionWasCancelled];
		[transitionContext completeTransition:!wasCancelled];
	}];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
													  presentingViewController:(UIViewController *)presenting
														  sourceViewController:(UIViewController *)source {
	return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
																   presentingController:(UIViewController *)presenting
																	   sourceController:(UIViewController *)source {
	return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
	return self;
}

@end
