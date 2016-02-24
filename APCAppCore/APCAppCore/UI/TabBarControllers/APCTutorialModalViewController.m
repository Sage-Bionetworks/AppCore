//
//  APCTutorialModalViewController.m
//  APCAppCore
//
//  Created by Everest Liu on 2/16/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APCTutorialModalViewController.h"
#import "APCAppCore.h"

static const int kModalCornerRadius = 12;
static const int kNextButtonCornerRadius = 12;
static const int kNextButtonBorderWidth = 1;
static NSString *const kNextButtonInitialText = @"Next";

static const int kModalWidth = 280;
static const int kModalHeight = 390;

static NSString *const kTutoralArrow1Name = @"tutorial_arrow_1";
static NSString *const kTutoralArrow2Name = @"tutorial_arrow_2";
static NSString *const kTabBarItemActivitiesText = @"Activities";
static NSString *const kTabBarItemDashboardText = @"Dashboard";
static NSString *const kDashboardStepNextButtonText = @"Get Started";

typedef NS_ENUM(NSInteger, OnStep) {
	thanksStep = 0,
	activitiesStep,
	dashboardStep
};

@interface APCTutorialModalViewController ()

@property(nonatomic) NSArray *textBlocks;
@property(nonatomic) UIImageView *tutorialArrow;
@property(nonatomic) UIImageView *tabBarItemView;

@end

@implementation APCTutorialModalViewController {
	OnStep currentStep;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self configureTextBlocks];

	currentStep = thanksStep;
	self.tutorialArrow = [[UIImageView alloc] init];

	self.view.layer.cornerRadius = kModalCornerRadius;

	self.nextButton.layer.cornerRadius = kNextButtonCornerRadius;
	self.nextButton.layer.borderWidth = kNextButtonBorderWidth;
	self.nextButton.layer.borderColor = [UIColor colorWithRed:0.95 green:0.31 blue:0.48 alpha:1].CGColor;
	self.nextButton.titleLabel.text = kNextButtonInitialText;

	self.tabBarItemView = [[UIImageView alloc] init];
	self.tabBarItemView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.tabBarItemView];
}

- (CGSize)preferredContentSize {
	return CGSizeMake(kModalWidth, kModalHeight);
}

#pragma mark - IBOutlets

- (IBAction)skipButtonTouched {
	self.tutorialArrow.hidden = YES;
	self.tabBarItemView.hidden = YES;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShowTutorialEnabledKey];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)nextButtonTouched {
	UITabBarController *tabBarController = (UITabBarController *) self.presentationController.presentingViewController;

	switch (currentStep) {
		case thanksStep: {
			self.titleLabel.hidden = YES;
			self.detailLabel.text = [self getTextWithKey:kTutorialTextActivites];
			self.detailLabelTopConstraint.constant = 35;

			self.tutorialArrow.image = [UIImage imageNamed:kTutoralArrow1Name
												  inBundle:[NSBundle bundleForClass:self.class]
							 compatibleWithTraitCollection:nil];


			[self setupTutorialWithTabBar:tabBarController andItemName:kTabBarItemActivitiesText];

			float scaleFactor = (tabBarController.view.bounds.size.height - CGRectGetMaxY(self.view.frame) - tabBarController.tabBar.frame.size.height - 20) / self.tutorialArrow.image.size.height;

			self.tutorialArrow.frame = CGRectMake(self.tabBarItemView.frame.origin.x + self.tabBarItemView.frame.size.width / 2,
				self.view.frame.size.height + 10,
				self.tutorialArrow.image.size.width * scaleFactor,
				self.tutorialArrow.image.size.height * scaleFactor);

			[self.view addSubview:self.tutorialArrow];

			currentStep = activitiesStep;
		}
			break;
		case activitiesStep: {
			tabBarController.selectedIndex = 1;

			self.detailLabel.text = [self getTextWithKey:kTutorialTextDashboard];
			[self.nextButton setTitle:kDashboardStepNextButtonText forState:UIControlStateNormal];
			self.skipButton.hidden = YES;
			self.nextButtonBottomConstraint.constant = 35;

			self.tutorialArrow.image = [UIImage imageNamed:kTutoralArrow2Name
												  inBundle:[NSBundle bundleForClass:self.class]
							 compatibleWithTraitCollection:nil];

			[self setupTutorialWithTabBar:tabBarController andItemName:kTabBarItemDashboardText];

			float scaleFactor = (tabBarController.view.bounds.size.height - CGRectGetMaxY(self.view.frame) - tabBarController.tabBar.frame.size.height - 20) / self.tutorialArrow.image.size.height;

			self.tutorialArrow.frame = CGRectMake(self.tabBarItemView.frame.origin.x + self.tabBarItemView.frame.size.width / 2,
				self.view.frame.size.height + 10,
				self.tutorialArrow.image.size.width * scaleFactor,
				self.tutorialArrow.image.size.height * scaleFactor);

			currentStep = dashboardStep;
		}
			break;
		case dashboardStep:
			tabBarController.selectedIndex = 0;
			self.tutorialArrow.hidden = YES;
			self.tabBarItemView.hidden = YES;
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShowTutorialEnabledKey];
			[self dismissViewControllerAnimated:YES completion:nil];
			break;
		default:
			break;
	}
}

#pragma mark - Utility Methods

- (void)configureTextBlocks {
	APCAppDelegate *appDelegate = ((APCAppDelegate *) [UIApplication sharedApplication].delegate);
	self.textBlocks = [appDelegate allSetTextBlocks];
}

// We have to iterate since the actual classes of the view and subview are private APIs in UIKit
- (void)setupTutorialWithTabBar:(UITabBarController *)tabBarController andItemName:(NSString *)itemName {
	for (UIView *view in tabBarController.tabBar.subviews) {
		if ([view isKindOfClass:UIControl.class]) {
			for (UIView *subview in view.subviews) {
				if ([subview isKindOfClass:UILabel.class]) {
					if ([((UILabel *) subview).text isEqualToString:itemName]) {
						UIImage *activitiesImage = [APCTutorialModalViewController imageWithView:view];
						self.tabBarItemView.image = activitiesImage;
						self.tabBarItemView.frame = [self.view convertRect:view.frame
																  fromView:tabBarController.tabBar];
						break;
					}
				}
			}
		}
	}
}

- (NSString *)getTextWithKey:(NSString *)key {
	NSString *text;

	//defaults
	if ([key isEqualToString:kTutorialTextInitial]) {
		text = NSLocalizedStringWithDefaultValue(@"This is your app to use as you choose. We will give you a quick tutorial to help you get started.", @"APCAppCore", APCBundle(), @"This is your app to use as you choose. We will give you a quick tutorial to help you get started.", nil);
	} else if ([key isEqualToString:kTutorialTextActivites]) {
		text = NSLocalizedStringWithDefaultValue(@"You will find your list of daily surveys and tasks on the \"Activities\" tab. New surveys and tasks will appear over the next few weeks.\n\nPlease perform these activities each day when you are at your lowest before you take your medications, after your medications take effect, and then a third time during the day.", @"APCAppCore", APCBundle(), @"You will find your list of daily surveys and tasks on the \"Activities\" tab. New surveys and tasks will appear over the next few weeks.\n\nPlease perform these activities each day when you are at your lowest before you take your medications, after your medications take effect, and then a third time during the day.", nil);
	} else if ([key isEqualToString:kTutorialTextDashboard]) {
		text = NSLocalizedStringWithDefaultValue(@"To see your results from surveys and tasks, check your \"Dashboard\" tab.\n\nHere you will also find a dashboard that is designed for physicians. It provides a glimpse into your activities and trends, as these may be useful insights.", @"APCAppCore", APCBundle(), @"To see your results from surveys and tasks, check your \"Dashboard\" tab.\n\nHere you will also find a dashboard that is designed for physicians. It provides a glimpse into your activities and trends, as these may be useful insights.", nil);
	}

	if (self.textBlocks) {
		for (NSDictionary *textBlock in self.textBlocks) {
			if ([key isEqualToString:kTutorialTextInitial]) {
				text = textBlock[kTutorialTextInitial];
			} else if ([key isEqualToString:kTutorialTextActivites]) {
				text = textBlock[kTutorialTextActivites];
			} else if ([key isEqualToString:kTutorialTextDashboard]) {
				text = textBlock[kTutorialTextDashboard];
			}
		}
	}

	return text;
}

+ (UIImage *)imageWithView:(UIView *)view {
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return image;
}

@end
