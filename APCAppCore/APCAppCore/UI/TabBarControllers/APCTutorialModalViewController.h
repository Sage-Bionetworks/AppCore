//
//  APCTutorialModalViewController.h
//  APCAppCore
//
//  Created by Everest Liu on 2/16/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

@import UIKit;

static NSString *const kActivitiesStepDetailLabelText = @"You will find your list of daily surveys and tasks on the \"Activities\" tab. New surveys and tasks will appear over the next few weeks.\n\nPlease perform these activities each day when you are at your lowest before you take your Parkinson medications, after your medications take effect, and then a third time during the day.";
static NSString *const kDashboardStepDetailLabelText = @"To see your results from surveys and tasks, check your \"Dashboard\" tab.\n\nHere you will also find a dashboard that is designed for physicians. It provides a glimpse into your activities and trends, as these may be useful insights.";

@interface APCTutorialModalViewController : UIViewController

@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(weak, nonatomic) IBOutlet UILabel *detailLabel;
@property(weak, nonatomic) IBOutlet UIButton *nextButton;
@property(weak, nonatomic) IBOutlet UIButton *skipButton;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *detailLabelTopConstraint;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *nextButtonBottomConstraint;

@end
