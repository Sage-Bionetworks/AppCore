//
//  APCDataGroupsManager.m
//  APCAppCore
//
// Copyright (c) 2015, Sage Bionetworks. All rights reserved.
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

#import "APCDataGroupsManager.h"
#import "APCAppCore.h"

NSString * const APCDataGroupsStepIdentifier = @"dataGroups";

NSString * const APCDataGroupsMappingItemsKey = @"items";
NSString * const APCDataGroupsMappingRequiredKey = @"required";
NSString * const APCDataGroupsMappingProfileKey = @"profile";
NSString * const APCDataGroupsMappingSurveyKey = @"survey";
NSString * const APCDataGroupsMappingQuestionsKey = @"questions";

NSString * const APCDataGroupsMappingSurveyTitleKey = @"title";
NSString * const APCDataGroupsMappingSurveyTextKey = @"text";
NSString * const APCDataGroupsMappingSurveyOptionalKey = @"optional";
NSString * const APCDataGroupsMappingSurveyIdentifierKey = @"identifier";
NSString * const APCDataGroupsMappingSurveyQuestionTypeKey = @"type";
NSString * const APCDataGroupsMappingSurveyQuestionValueMapKey = @"valueMap";
NSString * const APCDataGroupsMappingSurveyQuestionTypeBoolean = @"boolean";
NSString * const APCDataGroupsMappingSurveyQuestionValueMapValueKey = @"value";
NSString * const APCDataGroupsMappingSurveyQuestionValueMapGroupsKey = @"groups";

@interface APCDataGroupsManager ()

@property (nonatomic, copy) NSSet *originalDataGroupsSet;
@property (nonatomic, strong) NSMutableSet *dataGroupsSet;

@property (nonatomic, readonly) NSDictionary *survey;
@property (nonatomic, readonly) NSDictionary *profile;

@end

@implementation APCDataGroupsManager

+ (NSString*)pathForDataGroupsMapping {
    return [[APCAppDelegate sharedAppDelegate] pathForResource:@"DataGroupsMapping" ofType:@"json"];
}

+ (NSDictionary*)defaultMapping {
    static NSDictionary * _dataGroupMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [self pathForDataGroupsMapping];
        NSData *json = [NSData dataWithContentsOfFile:path];
        if (json) {
            NSError *parseError;
            _dataGroupMapping = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:&parseError];
            if (parseError) {
                NSLog(@"Error parsing data group mapping: %@", parseError);
            }
        }
        
    });
    return _dataGroupMapping;
}

- (instancetype)initWithDataGroups:(NSArray *)dataGroups mapping:(NSDictionary*)mapping {
    self = [super init];
    if (self) {
        _mapping = [mapping copy] ?: [[self class] defaultMapping];
        _originalDataGroupsSet = (dataGroups.count > 0) ? [NSSet setWithArray:dataGroups] : [NSSet new];
        _dataGroupsSet = (dataGroups.count > 0) ? [NSMutableSet setWithArray:dataGroups] : [NSMutableSet new];
        _survey = _mapping[APCDataGroupsMappingSurveyKey];
        _profile = _mapping[APCDataGroupsMappingProfileKey];
    }
    return self;
}

- (NSArray *)dataGroups {
    return [self.dataGroupsSet allObjects];
}

- (BOOL)hasChanges {
    return ![self.dataGroupsSet isEqualToSet:self.originalDataGroupsSet];
}

- (BOOL)needsUserInfoDataGroups {
    if ([self.mapping[APCDataGroupsMappingRequiredKey] boolValue]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group_name IN %@", self.dataGroups];
        return [[self fiteredDataGroupsUsingPredicate:predicate] count] == 0;
    }
    return NO;
}

- (BOOL)isStudyControlGroup {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(group_name IN %@) AND (is_control_group = YES)", self.dataGroups];
    return [[self fiteredDataGroupsUsingPredicate:predicate] count] > 0;
}

- (NSArray <NSString *> * _Nullable)fiteredDataGroupsUsingPredicate:(NSPredicate *)predicate {
    return [self.mapping[APCDataGroupsMappingItemsKey] filteredArrayUsingPredicate:predicate];
}

- (ORKFormStep *)surveyStep {
    
    NSArray *questions = self.survey[APCDataGroupsMappingQuestionsKey];
    if (questions.count == 0) {
        return nil;
    }

    NSString *detail = self.survey[APCDataGroupsMappingSurveyTextKey];
    BOOL useQuestionPrompt = (questions.count == 1) && (detail.length == 0);
    if (useQuestionPrompt) {
        detail = questions[0][APCDataGroupsMappingSurveyTextKey];
    }
    
    // Create the step
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APCDataGroupsStepIdentifier
                                                          title:self.survey[APCDataGroupsMappingSurveyTitleKey]
                                                           text:detail];
    step.optional = [self.survey[APCDataGroupsMappingSurveyOptionalKey] boolValue];
    
    // Add the questions from the mapping
    NSMutableArray *formItems = [NSMutableArray new];
    for (NSDictionary *question in questions) {
        
        // Get the default choices and add the skip choice if this question is optional
        NSArray *textChoices = [self choicesForQuestion:question];
        if ([question[APCDataGroupsMappingSurveyOptionalKey] boolValue]) {
            ORKTextChoice *skipChoice = [ORKTextChoice choiceWithText:NSLocalizedStringWithDefaultValue(@"APC_SKIP_CHOICE", @"APCAppCore", APCBundle(), @"Prefer not to answer", @"Choice text for skipping a question") value:@(NSNotFound)];
            textChoices = [textChoices arrayByAddingObject:skipChoice];
        }
        
        ORKAnswerFormat *format = [ORKTextChoiceAnswerFormat
                                   choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice
                                   textChoices:textChoices];
        
        NSString *text = !useQuestionPrompt ? question[APCDataGroupsMappingSurveyTextKey] : nil;
        ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:question[APCDataGroupsMappingSurveyIdentifierKey]
                                                                text:text
                                                        answerFormat:format];
        [formItems addObject:item];
    }
    step.formItems = formItems;
    
    // If there is only one question, move the language around a little bit
    
    return step;
}

- (NSArray <APCTableViewRow *> * _Nullable)surveyItems {
    
    NSArray *questions = self.profile[APCDataGroupsMappingQuestionsKey];
    if (questions.count == 0) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray new];
    for (NSDictionary *question in questions) {

        // Create the item
        APCTableViewCustomPickerItem *item = [[APCTableViewCustomPickerItem alloc] init];
        item.questionIdentifier = question[APCDataGroupsMappingSurveyIdentifierKey];
        item.reuseIdentifier = kAPCDefaultTableViewCellIdentifier;
        item.caption = question[APCDataGroupsMappingSurveyTextKey];
        item.textAlignnment = NSTextAlignmentRight;
        
        // Get the choices
        NSArray <ORKTextChoice *> *choices = [self choicesForQuestion:question];
        item.pickerData = @[[choices valueForKey:NSStringFromSelector(@selector(text))]];
        
        // Set selected rows
        id selectedValue = [self selectedValueForMap:question[APCDataGroupsMappingSurveyQuestionValueMapKey]];
        NSArray *valueOrder = [choices valueForKey:NSStringFromSelector(@selector(value))];
        NSUInteger idx = (selectedValue != nil) ? [valueOrder indexOfObject:selectedValue] : NSNotFound;
        if (idx != NSNotFound) {
            item.selectedRowIndices = @[@(idx)];
        }
        
        // Create row
        APCTableViewRow *row = [APCTableViewRow new];
        row.item = item;
        row.itemType = kAPCUserInfoItemTypeDataGroups;
        [result addObject:row];
    }
    
    return [result copy];
}

- (NSArray <ORKTextChoice *> *) choicesForQuestion:(NSDictionary *)question {
    NSString *questionType = question[APCDataGroupsMappingSurveyQuestionTypeKey];
    if ([questionType isEqualToString:APCDataGroupsMappingSurveyQuestionTypeBoolean]) {
        
        ORKTextChoice *yesChoice = [ORKTextChoice choiceWithText:NSLocalizedStringWithDefaultValue(@"YES", @"APCAppCore", APCBundle(), @"Yes", @"Yes") value:@YES];
        ORKTextChoice *noChoice = [ORKTextChoice choiceWithText:NSLocalizedStringWithDefaultValue(@"NO", @"APCAppCore", APCBundle(), @"No", @"No") value:@NO];
        
        // Use the ordering defined by the mapping
        NSArray *valueMap = question[APCDataGroupsMappingSurveyQuestionValueMapKey];
        if ([valueMap[0][APCDataGroupsMappingSurveyQuestionValueMapValueKey] boolValue]) {
            return @[yesChoice, noChoice];
        }
        else {
            return @[noChoice, yesChoice];
        }
    }
    else {
        NSAssert1(NO, @"Data groups survey question of type %@ is not handled.", questionType);
    }

    return nil;
}

- (id)selectedValueForMap:(NSArray*)valueMap {
    if (self.dataGroups.count > 0) {
        NSSet *groupSet = [NSSet setWithArray:self.dataGroups];
        for (NSDictionary *map in valueMap) {
            NSMutableSet *mapSet = [NSMutableSet setWithArray:map[APCDataGroupsMappingSurveyQuestionValueMapGroupsKey]];
            [mapSet intersectSet:groupSet];
            if (mapSet.count > 0) {
                return map[APCDataGroupsMappingSurveyQuestionValueMapValueKey];
            }
        }
    }
    return nil;
}

- (void)setSurveyAnswerWithStepResult:(ORKStepResult *)stepResult {
    for (ORKResult *result in stepResult.results) {
        if ([result isKindOfClass:[ORKChoiceQuestionResult class]]) {
            ORKChoiceQuestionResult *choiceResult = (ORKChoiceQuestionResult *)result;

            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", APCDataGroupsMappingSurveyIdentifierKey, choiceResult.identifier];
            NSDictionary *question = [[self.survey[APCDataGroupsMappingQuestionsKey] filteredArrayUsingPredicate:predicate] firstObject];
            
            NSArray *valueMap = question[APCDataGroupsMappingSurveyQuestionValueMapKey];
            
            // Get the groups that are to be included based on the answer to this question
            NSPredicate *includePredicate = [NSPredicate predicateWithFormat:@"%K IN %@", APCDataGroupsMappingSurveyQuestionValueMapValueKey, choiceResult.choiceAnswers];
            NSArray *includeGroups = [[valueMap filteredArrayUsingPredicate:includePredicate] valueForKey:APCDataGroupsMappingSurveyQuestionValueMapGroupsKey];
            
            // Get the groups that are changing to be excluded (which are the groups mapped to
            // an aswer that was *not* selected
            NSPredicate *excludePredicate = [NSCompoundPredicate notPredicateWithSubpredicate:includePredicate];
            NSArray *excludeGroups = [[valueMap filteredArrayUsingPredicate:excludePredicate] valueForKey:APCDataGroupsMappingSurveyQuestionValueMapGroupsKey];
            
            // Remove data groups that are *not* in the selected subset
            for (NSArray *groups in excludeGroups) {
                [self.dataGroupsSet minusSet:[NSSet setWithArray:groups]];
            }
            
            // Add data groups that *are* in the selected subset
            for (NSArray *groups in includeGroups) {
                [self.dataGroupsSet unionSet:[NSSet setWithArray:groups]];
            }
        }
        else {
            NSAssert1(NO, @"Data groups survey question of class %@ is not handled.", [result class]);
        }
    }
}

- (void)setSurveyAnswerWithItem:(APCTableViewItem*)item {
    if ([item isKindOfClass:[APCTableViewCustomPickerItem class]]) {
        NSArray *selectedIndices = ((APCTableViewCustomPickerItem*)item).selectedRowIndices;
        NSAssert(selectedIndices.count <= 1, @"Data groups with multi-part picker are not implemented.");
        
        NSString *identifier = item.questionIdentifier;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", APCDataGroupsMappingSurveyIdentifierKey, identifier];
        NSDictionary *question = [[self.profile[APCDataGroupsMappingQuestionsKey] filteredArrayUsingPredicate:predicate] firstObject];
        
        // Get all the groups that are defined by this question
        NSArray *groupsMap = [question[APCDataGroupsMappingSurveyQuestionValueMapKey] valueForKey:APCDataGroupsMappingSurveyQuestionValueMapGroupsKey];
        
        // build the include and exclude sets
        NSMutableSet *excludeSet = [NSMutableSet new];
        NSMutableSet *includeSet = [NSMutableSet new];
        for (NSUInteger idx = 0; idx < groupsMap.count; idx++) {
            if ([selectedIndices containsObject:@(idx)]) {
                [includeSet addObjectsFromArray:groupsMap[idx]];
            }
            else {
                [excludeSet addObjectsFromArray:groupsMap[idx]];
            }
        }
        
        // Remove data groups that are *not* in the selected indices (and are instead associated
        // with a choice that was *not* selected)
        [self.dataGroupsSet minusSet:excludeSet];
        
        // Union data groups that *are* in the selected indices
        [self.dataGroupsSet unionSet:includeSet];
        
    }
    else {
        NSAssert1(NO, @"Data groups survey question of class %@ is not handled.", [item class]);
    }
}

@end
