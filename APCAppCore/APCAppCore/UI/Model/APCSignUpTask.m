// 
//  APCSignUpTask.m 
//  APCAppCore 
// 
// Copyright (c) 2015, Apple Inc. All rights reserved. 
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2.  Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution. 
// 
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
// may be used to endorse or promote products derived from this software without 
// specific prior written permission. No license is granted to the trademarks of 
// the copyright holders even if such marks are included in this software. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
// 

#import "APCSignUpTask.h"
#import "APCUser.h"

static NSInteger const kMinimumNumberOfSteps = 3; //Gen Info + MedicalInfo + Passcode

@implementation APCSignUpTask

#pragma mark - ORKTask methods

- (ORKStep *)stepAfterStep:(ORKStep *)step withResult:(ORKTaskResult *) __unused result
{
    ORKStep *nextStep;
    
    if (!step) {
        nextStep = self.inclusionCriteriaStep;
    } else if ([step.identifier isEqualToString:self.inclusionCriteriaStep.identifier]) {
        if (self.eligible) {
            nextStep = self.eligibleStep;
        } else{
            nextStep = self.ineligibleStep;
        }
    } else if ([step.identifier isEqualToString:self.eligibleStep.identifier]) {
        self.currentStepNumber += 1;
        nextStep = self.permissionsPrimingStep;
        
    } else if ([step.identifier isEqualToString:self.permissionsPrimingStep.identifier]) {
        self.currentStepNumber += 1;
        nextStep = self.dataGroupsStep;
    }
    else if ([step.identifier isEqualToString:self.dataGroupsStep.identifier]) {
        self.currentStepNumber += 1;
        nextStep = self.generalInfoStep;
        
    } else if ([step.identifier isEqualToString:self.generalInfoStep.identifier]) {
        self.currentStepNumber += 1;
        nextStep = self.medicalInfoStep;
        
    } else if ([step.identifier isEqualToString:self.medicalInfoStep.identifier]) {
        if (self.customStepIncluded) {
            nextStep = self.customInfoStep;
        } else{
            nextStep = self.passcodeStep;
            self.user.secondaryInfoSaved = YES;
        }
        self.currentStepNumber += 1;
    } else if ([step.identifier isEqualToString:self.customInfoStep.identifier]) {
        nextStep = self.passcodeStep;
        self.user.secondaryInfoSaved = YES;
        self.currentStepNumber += 1;
    } else if ([step.identifier isEqualToString:self.passcodeStep.identifier]) {
        if (self.permissionScreenSkipped) {
            nextStep = nil;
        } else {
            nextStep = self.permissionsStep;
            self.currentStepNumber += 1;
        }
    } else if ([step.identifier isEqualToString:self.ineligibleStep.identifier]) {
        nextStep = self.shareAppStep;
        self.currentStepNumber += 1;
    }
    
    return nextStep;
}

- (ORKStep *)stepBeforeStep:(ORKStep *)step withResult:(ORKTaskResult *) __unused result
{
    ORKStep *prevStep;
    
    if ([step.identifier isEqualToString:self.inclusionCriteriaStep.identifier]) {
        prevStep = nil;
    } else if ([step.identifier isEqualToString:self.eligibleStep.identifier]) {
        prevStep = self.inclusionCriteriaStep;
    } else if ([step.identifier isEqualToString:self.ineligibleStep.identifier]) {
        prevStep = self.inclusionCriteriaStep;
    } else if ([step.identifier isEqualToString:self.permissionsPrimingStep.identifier]) {
        prevStep = self.eligibleStep;
    } else if ([step.identifier isEqualToString:self.dataGroupsStep.identifier]) {
        prevStep = self.permissionsPrimingStep;
    } else if ([step.identifier isEqualToString:self.generalInfoStep.identifier]) {
        prevStep = self.dataGroupsStep;
    } else if ([step.identifier isEqualToString:self.medicalInfoStep.identifier]) {
        prevStep = self.generalInfoStep;
        self.currentStepNumber -= 1;
    } else if ([step.identifier isEqualToString:self.customInfoStep.identifier]) {
        prevStep = self.medicalInfoStep;
        self.currentStepNumber -= 1;
    } else if ([step.identifier isEqualToString:self.passcodeStep.identifier]) {
        if (self.customStepIncluded) {
            prevStep = self.customInfoStep;
        } else {
            prevStep = self.medicalInfoStep;
        }
        self.currentStepNumber -= 1;
    } else if ([step.identifier isEqualToString:self.permissionsStep.identifier]) {
        prevStep = self.passcodeStep;
        self.currentStepNumber -= 1;
    } else if ([step.identifier isEqualToString:self.shareAppStep.identifier]) {
        if (self.eligible) {
            prevStep = self.eligibleStep;
        } else {
            prevStep = self.ineligibleStep;
        }
        self.currentStepNumber -= 1;
    }
    
    return prevStep;
}

- (NSString *)identifier
{
    return @"SignUpTask";
}

#pragma mark - Overriden Methods

- (NSInteger)numberOfSteps
{
    NSInteger count = kMinimumNumberOfSteps;
    
    if (self.customStepIncluded) {
        count += 1;
    }
    if (!self.permissionScreenSkipped) {
        count += 1;
    }
    
    return count;
}

@end
