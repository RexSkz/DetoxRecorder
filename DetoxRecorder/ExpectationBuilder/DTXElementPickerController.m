//
//  DTXElementPickerController.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/7/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXElementPickerController.h"
#import "DTXPickerTypeSelectionController.h"
#import "DTXSelectedElementController.h"

@interface DTXElementPickerController ()

@end

@implementation DTXElementPickerController

@dynamic delegate;

- (instancetype)init
{
	self = [super initWithRootViewController:[DTXPickerTypeSelectionController new]];
	
	if(self)
	{
		UINavigationBarAppearance* appearance = [UINavigationBarAppearance new];
		[appearance configureWithTransparentBackground];
		appearance.shadowColor = UIColor.clearColor;
		self.navigationBar.standardAppearance = appearance;
		self.navigationBar.scrollEdgeAppearance = appearance;
	}
	
	return self;
}

- (void)_startVisualPicker
{
	[self.delegate elementPickerControllerDidStartVisualPicker:self];
}

- (void)visualElementPickerDidSelectElement:(UIView*)element
{
	DTXSelectedElementController* selectedElementVC = [DTXSelectedElementController new];
	selectedElementVC.selectedView = element;
	[self pushViewController:selectedElementVC animated:NO];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
	return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

@end
