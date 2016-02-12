//
//  APCCompletedActivitiesTodayModalViewController.m
//  APCAppCore
//
//  Created by Everest Liu on 2/10/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APCCompletedActivitiesTodayModalViewController.h"
#import "APCConstants.h"

@interface APCCompletedActivitiesTodayModalViewController ()

@end

@implementation APCCompletedActivitiesTodayModalViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.layer.cornerRadius = 12;

	self.okButton.layer.cornerRadius = 12;
	self.okButton.layer.borderWidth = 1;
	self.okButton.layer.borderColor = [UIColor colorWithRed:0.95 green:0.31 blue:0.48 alpha:1].CGColor;
}

- (IBAction)okButtonTouched:(UIButton *)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:!self.doNotShowAgainButton.selected
			   forKey:kShowTodayActivitiesCompleteModalEnabledKey];

	[defaults synchronize];

	[self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)doNotShowTouched:(UIButton *)sender {
    self.doNotShowAgainButton.selected = !self.doNotShowAgainButton.selected;
}

@end
