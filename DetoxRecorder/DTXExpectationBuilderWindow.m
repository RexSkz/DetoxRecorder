//
//  DTXViewSelectionWindow.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/6/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXExpectationBuilderWindow.h"
#import "DTXUIInteractionRecorder.h"
#import "DTXElementPickerController.h"

@interface UIWindowScene ()

+ (instancetype)_keyWindowScene;
@property (readonly, nonatomic) UIWindow *_keyWindow;

@end

@interface UIView ()

@property (nonatomic, getter=isHiddenOrHasHiddenAncestor) BOOL hiddenOrHasHiddenAncestor;

@end

@interface UIWindow ()

- (void)_makeKeyWindowIgnoringOldKeyWindow:(BOOL)arg1;

@end

@interface UIView (ViewSelection) @end
@implementation UIView (ViewSelection)

- (UIView*)_dtxrec_customPickTest:(CGPoint)point withEvent:(UIEvent*)event
{
	if(self.isHiddenOrHasHiddenAncestor == YES)
	{
		return nil;
	}
	
	if(self.alpha == 0.0)
	{
		return nil;
	}
	
	if([self pointInside:point withEvent:event] == NO)
	{
		return nil;
	}
	
	UIView* rv = self;
	
	if([rv isKindOfClass:UIControl.class] ||
	   [rv isKindOfClass:UITextView.class] ||
	   [rv isKindOfClass:NSClassFromString(@"WKWebView")] ||
	   [rv isKindOfClass:NSClassFromString(@"MKMapView")])
	{
		return rv;
	}
	
	//Front-most views get priority
	for (__kindof UIView * _Nonnull subview in self.subviews.reverseObjectEnumerator) {
		CGPoint localPoint = [self convertPoint:point toView:subview];
		UIView* candidate = [subview _dtxrec_customPickTest:localPoint withEvent:event];
		
		if(candidate == nil)
		{
			continue;
		}
		
		rv = candidate;
		break;
	}
	
	return rv;
}

@end

@interface DTXExpectationBuilderWindow () <DTXElementPickerControllerDelegate>

@end

@implementation DTXExpectationBuilderWindow
{
	DTXCaptureControlWindow* _captureControlWindow;
	BOOL _pickingVisually;
	UIVisualEffectView* _backgroundView;
	UIButton* _closeButton;
	UILabel* _visualPickingPromptLabel;
	
	DTXElementPickerController* _navigationController;
	
	BOOL _finished;
}

- (instancetype)initWithCaptureControlWindow:(DTXCaptureControlWindow*)captureControlWindow
{
	self = [super initWithFrame:captureControlWindow.screen.bounds];
	
	if(self)
	{
		_backgroundView = [[UIVisualEffectView alloc] initWithEffect:nil];
		_backgroundView.frame = self.bounds;
		_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_backgroundView];
		
		_closeButton = [UIButton buttonWithType:UIButtonTypeClose];
		_closeButton.translatesAutoresizingMaskIntoConstraints = NO;
		[_closeButton addTarget:self action:@selector(_close:) forControlEvents:UIControlEventPrimaryActionTriggered];
		[self addSubview:_closeButton];
		
//		static const CGFloat notchWidth = 209.0;
		
		[NSLayoutConstraint activateConstraints:@[
			[_closeButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:0],
			[_closeButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:30],
		]];
		
		_navigationController = [DTXElementPickerController new];
		_navigationController.delegate = self;
		self.rootViewController = _navigationController;
		
		_visualPickingPromptLabel = [UILabel new];
		_visualPickingPromptLabel.text = @"Please tap an element";
		_visualPickingPromptLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
		_visualPickingPromptLabel.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.75];
		_visualPickingPromptLabel.textColor = UIColor.whiteColor;
		_visualPickingPromptLabel.textAlignment = NSTextAlignmentCenter;
		_visualPickingPromptLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_visualPickingPromptLabel.hidden = YES;
		_visualPickingPromptLabel.layer.cornerRadius = 5.0;
		_visualPickingPromptLabel.clipsToBounds = YES;
		_visualPickingPromptLabel.userInteractionEnabled = NO;
		_visualPickingPromptLabel.alpha = 0.0; // Start fully transparent for fade-in

		// Add padding by setting attributed text (optional, but makes it look nicer)
		NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_visualPickingPromptLabel.text];
		[attributedString addAttribute:NSKernAttributeName value:@(0.3) range:NSMakeRange(0, attributedString.length)];
		_visualPickingPromptLabel.attributedText = attributedString;

		[self addSubview:_visualPickingPromptLabel];

		[NSLayoutConstraint activateConstraints:@[
			[_visualPickingPromptLabel.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:12],
			[_visualPickingPromptLabel.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-16],
			[_visualPickingPromptLabel.heightAnchor constraintGreaterThanOrEqualToConstant:26], // Min height
			[_visualPickingPromptLabel.widthAnchor constraintGreaterThanOrEqualToConstant:160] // Min width
		]];

		self.windowScene = captureControlWindow.windowScene;
		_captureControlWindow = captureControlWindow;
	}
	
	return self;
}

- (void)setAlpha:(CGFloat)alpha
{
	for (UIView* subview in self.subviews) {
		if(subview == _backgroundView || subview == _closeButton)
		{
			continue;
		}
		
		subview.alpha = alpha;
	}
}

- (void)makeKeyAndVisible
{
	[super makeKeyAndVisible];
	
	self.alpha = 0.0;
	
	[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
			_backgroundView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
		}];
		[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
			self.alpha = 1.0;
		}];
	} completion:nil];
}

- (void)_close:(UIButton*)sender
{
	_visualPickingPromptLabel.hidden = YES; // Hide immediately
	[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
			self.alpha = 0.0;
			_visualPickingPromptLabel.alpha = 0.0;
		}];
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
			_backgroundView.effect = nil;
		}];
	} completion:^(BOOL finished) {
		_visualPickingPromptLabel.hidden = YES; // Ensure hidden
		[self.delegate expectationBuilderWindowDidEnd:self];
	}];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self bringSubviewToFront:_closeButton];
}

- (void)_makeKeyWindowIgnoringOldKeyWindow:(BOOL)arg1
{
	if(_finished)
	{
		[self.appWindow makeKeyWindow];
		
		return;
	}
	
	[super _makeKeyWindowIgnoringOldKeyWindow:arg1];
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
	if(_pickingVisually)
	{
		id rv = [self.appWindow _dtxrec_customPickTest:point withEvent:event];
		
		[_navigationController visualElementPickerDidSelectElement:rv];
		
		_pickingVisually = NO;
		_visualPickingPromptLabel.hidden = YES;
		_visualPickingPromptLabel.alpha = 0.0;

		[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
			[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
				_backgroundView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
			}];
			[UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
				self.alpha = 1.0;
			}];
		} completion:nil];
		
		return self;
	}
	
	return [super hitTest:point withEvent:event];
}

- (void)elementPickerControllerDidStartVisualPicker:(DTXElementPickerController*)elementPickerController
{
	[UIView animateKeyframesWithDuration:0.25 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
			self.alpha = 0.0;
		}];
		[UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
			_backgroundView.effect = nil;
		}];
	} completion:^(BOOL finished) {
		if(finished) {
			_pickingVisually = YES;
			_visualPickingPromptLabel.hidden = NO;
			[self bringSubviewToFront:_visualPickingPromptLabel];
			[UIView animateWithDuration:0.15 animations:^{
				_visualPickingPromptLabel.alpha = 1.0;
			}];
		}
	}];
}

@end
