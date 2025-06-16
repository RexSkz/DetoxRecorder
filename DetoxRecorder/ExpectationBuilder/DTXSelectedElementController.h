//
//  DTXSelectedElementController.h
//  DetoxRecorder
//
//  Created by Leo Natan on 12/16/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DTXSelectedElementController : UIViewController

@property (nonatomic, strong) UIView* selectedView;

@property (nonatomic, strong) UIImageView* snapshotImageView;
@property (nonatomic, strong) UILabel* classLabel;
@property (nonatomic, strong) UILabel* identifierLabel;
@property (nonatomic, strong) UILabel* textLabel;
@property (nonatomic, strong) UILabel* accessibilityLabelLabel; // Renamed to avoid conflict

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSArray<NSDictionary*>* suggestedMatchers;
@property (nonatomic, strong, nullable) NSDictionary* selectedMatcher;

@property (nonatomic, strong) NSArray<NSDictionary*>* availableExpects;
@property (nonatomic, strong, nullable) NSString* generatedExpectString;

@property (nonatomic, strong) UITextField* expectParameterTextField;
@property (nonatomic, strong) UIButton* copyButton;
@property (nonatomic, strong) UIButton* insertButton;

@end

FOUNDATION_EXPORT NSInteger const DTXSelectedElementSectionMatchers;
FOUNDATION_EXPORT NSInteger const DTXSelectedElementSectionExpects;

NS_ASSUME_NONNULL_END
