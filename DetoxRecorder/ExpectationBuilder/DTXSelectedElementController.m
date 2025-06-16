//
//  DTXSelectedElementController.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/16/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXSelectedElementController.h"
#import "UIView+DTXAdditions.h" // For dtx_text
#import "DTXUIInteractionRecorder.h"
#import "UIViewController+DTXAdditions.h" // For dtx_showAlert
#import "DTXRecordedExpectationAction.h"

@interface DTXSelectedElementController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@end

static NSString* const CellIdentifier = @"MatcherCell";
NSInteger const DTXSelectedElementSectionMatchers = 0;
NSInteger const DTXSelectedElementSectionExpects = 1;

@implementation DTXSelectedElementController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Element Details";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    // Snapshot Image View
    self.snapshotImageView = [UIImageView new];
    self.snapshotImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.snapshotImageView.translatesAutoresizingMaskIntoConstraints = NO;
    if (self.selectedView) {
        // Attempt to get a snapshot. Some views might return nil or an empty image.
        UIView* snapshotHolder = [self.selectedView snapshotViewAfterScreenUpdates:YES];
        if (snapshotHolder) {
            self.snapshotImageView.image = [self _imageFromView:snapshotHolder];
        }
        // Fallback if the first snapshot is empty or failed
        if (!self.snapshotImageView.image && [self.selectedView respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
             self.snapshotImageView.image = [self _imageFromView:self.selectedView directRender:YES];
        }

        self.snapshotImageView.layer.borderColor = UIColor.separatorColor.CGColor;
        self.snapshotImageView.layer.borderWidth = 1.0;
        self.snapshotImageView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.05]; // Slight bg for empty snapshots
    }
    [self.view addSubview:self.snapshotImageView];

    // Property Labels
    self.classLabel = [self _createPropertyLabel];
    self.identifierLabel = [self _createPropertyLabel];
    self.textLabel = [self _createPropertyLabel];
    self.accessibilityLabelLabel = [self _createPropertyLabel];

    if (self.selectedView) {
        self.classLabel.text = [NSString stringWithFormat:@"Type: %@", NSStringFromClass(self.selectedView.class)];
        self.identifierLabel.text = [NSString stringWithFormat:@"Identifier: %@", self.selectedView.accessibilityIdentifier ?: @"N/A"];
        self.textLabel.text = [NSString stringWithFormat:@"Text: %@", [self.selectedView dtx_text] ?: @"N/A"];
        self.accessibilityLabelLabel.text = [NSString stringWithFormat:@"Label: %@", self.selectedView.accessibilityLabel ?: @"N/A"];
    }

    UIStackView* propertiesStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.classLabel, self.identifierLabel, self.textLabel, self.accessibilityLabelLabel]];
    propertiesStackView.axis = UILayoutConstraintAxisVertical;
    propertiesStackView.spacing = 5.0; // Increased spacing
    propertiesStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:propertiesStackView];

    // Table View
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:CellIdentifier];
    [self.view addSubview:self.tableView];

    // Auto Layout Constraints
    CGFloat snapshotSize = 120.0; // Increased snapshot size
    CGFloat padding = 16.0;

    [NSLayoutConstraint activateConstraints:@[
        [self.snapshotImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:padding],
        [self.snapshotImageView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:padding],
        [self.snapshotImageView.widthAnchor constraintEqualToConstant:snapshotSize],
        [self.snapshotImageView.heightAnchor constraintEqualToConstant:snapshotSize],

        [propertiesStackView.topAnchor constraintEqualToAnchor:self.snapshotImageView.topAnchor],
        [propertiesStackView.leadingAnchor constraintEqualToAnchor:self.snapshotImageView.trailingAnchor constant:padding],
        [propertiesStackView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-padding],
        // Allow properties to extend below snapshot if text is long, but not required to.
        [propertiesStackView.bottomAnchor constraintLessThanOrEqualToAnchor:self.tableView.topAnchor constant:-padding],


        [self.tableView.topAnchor constraintEqualToAnchor:self.snapshotImageView.bottomAnchor constant:padding + 8], // Ensure enough space
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
    // Ensure properties don't get squished if snapshot is too tall relative to them
    [propertiesStackView.bottomAnchor constraintLessThanOrEqualToAnchor:self.snapshotImageView.bottomAnchor relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityDefaultLow];

    self.availableExpects = @[];

    // Expect Parameter TextField
    self.expectParameterTextField = [UITextField new];
    self.expectParameterTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.expectParameterTextField.placeholder = @"Enter parameter";
    self.expectParameterTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.expectParameterTextField.hidden = YES;
    self.expectParameterTextField.font = [UIFont systemFontOfSize:14.0];
    self.expectParameterTextField.delegate = self;
    [self.expectParameterTextField addTarget:self action:@selector(_expectParameterTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.expectParameterTextField];

    // Buttons
    self.copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.copyButton setTitle:@"Copy to Clipboard" forState:UIControlStateNormal];
    [self.copyButton addTarget:self action:@selector(_copyExpect:) forControlEvents:UIControlEventTouchUpInside];
    self.copyButton.enabled = NO;
    self.copyButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];

    self.insertButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.insertButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.insertButton setTitle:@"Insert into Script" forState:UIControlStateNormal];
    [self.insertButton addTarget:self action:@selector(_insertExpect:) forControlEvents:UIControlEventTouchUpInside];
    self.insertButton.enabled = NO;
    self.insertButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];

    UIStackView* buttonsStackView = [[UIStackView alloc] initWithArrangedSubviews:@[self.copyButton, self.insertButton]];
    buttonsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    buttonsStackView.axis = UILayoutConstraintAxisHorizontal;
    buttonsStackView.distribution = UIStackViewDistributionFillEqually;
    buttonsStackView.spacing = 10.0;
    [self.view addSubview:buttonsStackView];

    // Adjust TableView bottom constraint and add constraints for new elements
    // Deactivate old bottom constraint for table view
    for(NSLayoutConstraint* constraint in self.view.constraints) {
        if(constraint.firstItem == self.tableView && constraint.firstAttribute == NSLayoutAttributeBottom) {
            constraint.active = NO;
            break;
        }
    }
    // Or, if you stored it as a property: self.tableViewBottomConstraint.active = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.expectParameterTextField.topAnchor constraintEqualToAnchor:self.tableView.bottomAnchor constant:padding],
        [self.expectParameterTextField.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:padding],
        [self.expectParameterTextField.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-padding],

        [buttonsStackView.topAnchor constraintEqualToAnchor:self.expectParameterTextField.bottomAnchor constant:padding],
        [buttonsStackView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:padding],
        [buttonsStackView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-padding],
        [buttonsStackView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-padding],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.expectParameterTextField.topAnchor constant:-padding] // New table view bottom
    ]];

    [self _generateMatchers];
}

- (UILabel*)_createPropertyLabel {
    UILabel* label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:14.5]; // Slightly larger font
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    return label;
}

// Helper to render view to image, with an option for direct rendering
- (UIImage *)_imageFromView:(UIView *)view directRender:(BOOL)directRender {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (directRender && [view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    } else {
        [view.layer renderInContext:context];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// Simplified _imageFromView, prefers layer rendering for snapshots from snapshotViewAfterScreenUpdates:
- (UIImage *)_imageFromView:(UIView *)view {
    return [self _imageFromView:view directRender:NO];
}


- (void)_generateMatchers {
    NSMutableArray* matchers = [NSMutableArray new];

    if (!self.selectedView) {
        self.suggestedMatchers = @[];
        [self.tableView reloadData];
        return;
    }

    // Helper to sanitize strings for matcher
    NSCharacterSet *charsToEscape = [NSCharacterSet characterSetWithCharactersInString:@"'\\"];
    NSString* (^sanitize)(NSString*) = ^NSString*(NSString* input) {
        NSMutableString *sanitized = [input mutableCopy];
        NSRange searchRange = NSMakeRange(0, sanitized.length);
        NSRange foundRange;
        while ((foundRange = [sanitized rangeOfCharacterFromSet:charsToEscape options:0 range:searchRange]).location != NSNotFound) {
            NSString *charFound = [sanitized substringWithRange:foundRange];
            NSString *replacement = [charFound isEqualToString:@"'"] ? @"\\'" : @"\\\\";
            [sanitized replaceCharactersInRange:foundRange withString:replacement];
            searchRange = NSMakeRange(foundRange.location + replacement.length, sanitized.length - (foundRange.location + replacement.length));
        }
        return [sanitized copy];
    };

    // by.id
    NSString* accessibilityIdentifier = self.selectedView.accessibilityIdentifier;
    if (accessibilityIdentifier && accessibilityIdentifier.length > 0) {
        NSString* sanitizedId = sanitize(accessibilityIdentifier);
        [matchers addObject:@{
            @"matcherString": [NSString stringWithFormat:@"by.id('%@')", sanitizedId],
            @"displayText": [NSString stringWithFormat:@"ID: “%@”", accessibilityIdentifier] // Display original
        }];
    }

    // by.text
    NSString* text = [self.selectedView dtx_text];
    if (text && text.length > 0) {
        NSString* sanitizedText = sanitize(text);
        [matchers addObject:@{
            @"matcherString": [NSString stringWithFormat:@"by.text('%@')", sanitizedText],
            @"displayText": [NSString stringWithFormat:@"Text: “%@”", text] // Display original
        }];
    }

    // by.label
    NSString* accessibilityLabel = self.selectedView.accessibilityLabel;
    if (accessibilityLabel && accessibilityLabel.length > 0) {
        NSString* sanitizedLabel = sanitize(accessibilityLabel);
        [matchers addObject:@{
            @"matcherString": [NSString stringWithFormat:@"by.label('%@')", sanitizedLabel],
            @"displayText": [NSString stringWithFormat:@"Label: “%@”", accessibilityLabel] // Display original
        }];
    }

    // by.type
    NSString* className = NSStringFromClass(self.selectedView.class);
    if (className && className.length > 0) {
        // Type usually doesn't need sanitization like user content, but good practice if it could have special chars
        [matchers addObject:@{
            @"matcherString": [NSString stringWithFormat:@"by.type('%@')", className],
            @"displayText": [NSString stringWithFormat:@"Type: “%@”", className]
        }];
    }

    self.suggestedMatchers = [matchers copy];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // Matchers and Expects
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == DTXSelectedElementSectionMatchers) {
        return @"Suggested Matchers";
    } else if (section == DTXSelectedElementSectionExpects) {
        return self.selectedMatcher ? @"Available Asserts" : nil; // Only show if a matcher is selected
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == DTXSelectedElementSectionMatchers) {
        return self.suggestedMatchers.count;
    } else if (section == DTXSelectedElementSectionExpects) {
        return self.selectedMatcher ? self.availableExpects.count : 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSString* displayText = @"";
    BOOL isSelected = NO;

    if (indexPath.section == DTXSelectedElementSectionMatchers) {
        NSDictionary* matcherInfo = self.suggestedMatchers[indexPath.row];
        displayText = matcherInfo[@"displayText"];
        if(self.selectedMatcher && [self.selectedMatcher[@"matcherString"] isEqualToString:matcherInfo[@"matcherString"]]) {
            isSelected = YES;
        }
    } else if (indexPath.section == DTXSelectedElementSectionExpects) {
        NSDictionary* expectInfo = self.availableExpects[indexPath.row];
        displayText = expectInfo[@"displayText"];
        // Potentially highlight selected expect if we store that
    }

    cell.textLabel.text = displayText;
    cell.textLabel.font = [UIFont monospacedSystemFontOfSize:14.0 weight:UIFontWeightRegular];
    cell.textLabel.numberOfLines = 0;
    cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == DTXSelectedElementSectionMatchers) {
        self.selectedMatcher = self.suggestedMatchers[indexPath.row];
        self.generatedExpectString = nil;
        self.expectParameterTextField.text = @"";
        self.expectParameterTextField.hidden = YES;
        self.copyButton.enabled = NO;
        self.insertButton.enabled = NO;

        [self _generateAvailableExpects]; // This will reload section 1 (Expects)
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:DTXSelectedElementSectionMatchers] withRowAnimation:UITableViewRowAnimationNone]; // For checkmark
    } else if (indexPath.section == DTXSelectedElementSectionExpects) {
        NSDictionary* selectedExpect = self.availableExpects[indexPath.row];
        [self _updateGeneratedExpectStringWithExpect:selectedExpect parameterValue:self.expectParameterTextField.text];

        BOOL requiresParameter = [selectedExpect[@"requiresParameter"] boolValue];
        if (requiresParameter) {
            self.expectParameterTextField.hidden = NO;
            self.expectParameterTextField.placeholder = selectedExpect[@"parameterHint"] ?: @"Enter parameter";
            [self.expectParameterTextField becomeFirstResponder];
        } else {
            self.expectParameterTextField.hidden = YES;
        }
        // Highlight selected expect? (Requires storing selected expect)
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:DTXSelectedElementSectionExpects] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Private Methods

- (void)_expectParameterTextFieldChanged:(UITextField *)textField {
    // Find the currently selected expect to pass to _updateGeneratedExpectString
    // This assumes we have a way to know which expect is "active" or was last selected.
    // For now, let's find it by checking which one would need a parameter if the text field is visible.
    // This is a bit indirect. A better way would be to store the selectedExpect.
    NSDictionary* currentExpect = nil;
    if(!self.expectParameterTextField.isHidden) {
        for(NSDictionary* expectInfo in self.availableExpects) {
            if([expectInfo[@"requiresParameter"] boolValue]) {
                // This is a simplification. If multiple expects require parameters,
                // we'd need to store the explicitly selected one.
                // For now, assume the one that made the field visible is the one.
                 currentExpect = expectInfo; // Or retrieve stored selected expect
                 break;
            }
        }
    }
     if (currentExpect) { // Only update if we have an active expect that might use this parameter
        [self _updateGeneratedExpectStringWithExpect:currentExpect parameterValue:textField.text];
    }
}

- (void)_generateAvailableExpects {
    NSMutableArray* expects = [NSMutableArray new];

    // Common expects
    [expects addObject:@{@"expectType": @"toBeVisible", @"displayText": @".toBeVisible()", @"requiresParameter": @NO}];
    [expects addObject:@{@"expectType": @"toExist", @"displayText": @".toExist()", @"requiresParameter": @NO}];
    // Add more common expects here based on Detox documentation...

    if (self.selectedView) {
        // For text-based elements
        if ([self.selectedView.dtx_text length] > 0 || [self.selectedView isKindOfClass:UITextField.class] || [self.selectedView isKindOfClass:UITextView.class] || [self.selectedView isKindOfClass:UILabel.class]) {
            [expects addObject:@{@"expectType": @"toHaveText", @"displayText": @".toHaveText(text)", @"requiresParameter": @YES, @"parameterHint": @"Expected text"}];
        }
        // For elements with accessibility identifiers
        if ([self.selectedView.accessibilityIdentifier length] > 0) {
             [expects addObject:@{@"expectType": @"toHaveId", @"displayText": @".toHaveId(id)", @"requiresParameter": @YES, @"parameterHint": @"Expected ID"}];
        }
        // For accessibility values
        if ([self.selectedView.accessibilityValue length] > 0) {
             [expects addObject:@{@"expectType": @"toHaveValue", @"displayText": @".toHaveValue(value)", @"requiresParameter": @YES, @"parameterHint": @"Expected value"}];
        }
    }

    self.availableExpects = [expects copy];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:DTXSelectedElementSectionExpects] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)_updateGeneratedExpectStringWithExpect:(NSDictionary*)selectedExpect parameterValue:(nullable NSString*)parameterValue {
    if (!self.selectedMatcher || !selectedExpect) {
        self.generatedExpectString = nil;
        self.copyButton.enabled = NO;
        self.insertButton.enabled = NO;
        return;
    }

    NSString* matcherString = self.selectedMatcher[@"matcherString"];
    NSString* expectType = selectedExpect[@"expectType"];
    BOOL requiresParameter = [selectedExpect[@"requiresParameter"] boolValue];

    NSMutableString* finalExpect = [NSMutableString stringWithFormat:@"expect(element(%@)).%@", matcherString, expectType];

    if (requiresParameter) {
        NSString* sanitizedParameter = @"";
        if (parameterValue && parameterValue.length > 0) {
            // Re-use sanitization logic from _generateMatchers
            NSCharacterSet *charsToEscape = [NSCharacterSet characterSetWithCharactersInString:@"'\\"];
            NSMutableString *sanitized = [parameterValue mutableCopy];
            NSRange searchRange = NSMakeRange(0, sanitized.length);
            NSRange foundRange;
            while ((foundRange = [sanitized rangeOfCharacterFromSet:charsToEscape options:0 range:searchRange]).location != NSNotFound) {
                NSString *charFound = [sanitized substringWithRange:foundRange];
                NSString *replacement = [charFound isEqualToString:@"'"] ? @"\\'" : @"\\\\";
                [sanitized replaceCharactersInRange:foundRange withString:replacement];
                searchRange = NSMakeRange(foundRange.location + replacement.length, sanitized.length - (foundRange.location + replacement.length));
            }
            sanitizedParameter = [sanitized copy];
        }
        [finalExpect appendFormat:@"('%@')", sanitizedParameter];
    } else {
         [finalExpect appendString:@"()"]; // For expects like .toExist(), .toBeVisible()
    }

    self.generatedExpectString = [finalExpect copy];

    // TODO: Update a preview label here to show self.generatedExpectString
    NSLog(@"Generated Expect: %@", self.generatedExpectString);

    BOOL canInteract = (self.generatedExpectString.length > 0);
    if(requiresParameter && (!parameterValue || parameterValue.length == 0)) {
        canInteract = NO; // Disable if parameter is required but empty
    }
    self.copyButton.enabled = canInteract;
    self.insertButton.enabled = canInteract;
}

- (void)_copyExpect:(UIButton*)sender {
    if (self.generatedExpectString && self.generatedExpectString.length > 0) {
        UIPasteboard.generalPasteboard.string = self.generatedExpectString;
        [self dtx_showAlertWithTitle:@"Copied!" message:[NSString stringWithFormat:@"\"%@\" copied to clipboard.", self.generatedExpectString] duration:1.5];
    }
}

- (void)_insertExpect:(UIButton*)sender {
    if (self.generatedExpectString && self.generatedExpectString.length > 0) {
        DTXRecordedExpectationAction* expectationAction = [[DTXRecordedExpectationAction alloc] initWithExpectString:self.generatedExpectString];
        DTXUIInteractionRecorder* recorder = [DTXUIInteractionRecorder sharedRecorder];
        [recorder recordAction:expectationAction];

        [self dtx_showAlertWithTitle:@"Success" message:@"Expectation inserted into script."];
        // Consider dismissing the controller or providing a "Done" button.
        // For now, user can manually go back or add more.
    } else {
        [self dtx_showAlertWithTitle:@"Error" message:@"No valid expectation to insert."];
    }
}

@end
