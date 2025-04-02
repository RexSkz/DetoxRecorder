//
//  NSObject+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/16/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "NSObject+RecorderUtils.h"
#import "DTXFabricComponentViewUtils.h"

@implementation NSObject (RecorderUtils)

- (id)_dtx_text
{
	if([self respondsToSelector:@selector(text)])
	{
		return [(UITextView*)self text];
	}
	
	static Class RCTTextView;
    static Class RCTParagraphTextView;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		RCTTextView = NSClassFromString(@"RCTTextView");
        RCTParagraphTextView = NSClassFromString(@"RCTParagraphTextView");
	});
	if(RCTTextView != nil && [self isKindOfClass:RCTTextView])
	{
		return [(NSTextStorage*)[self valueForKey:@"textStorage"] string];
	}
    
    // Adapt to new architecture
    if(RCTParagraphTextView != nil && [self isKindOfClass:RCTParagraphTextView]) {
        return [DTXFabricComponentViewUtils textOfRCTParagraphTextView:(UIView *)self];
    }
    
	return nil;
}

- (id)_dtx_placeholder
{
	if([self respondsToSelector:@selector(placeholder)])
	{
		return [(UITextField*)self placeholder];
	}
	
	return nil;
}

- (CGRect)dtx_accessibilityFrame
{
	return self.accessibilityFrame;
}

- (NSString *)dtx_text
{
	id rv = [self _dtx_text];
	if(rv == nil || [rv isKindOfClass:NSString.class])
	{
		return rv;
	}
	
	if([rv isKindOfClass:NSAttributedString.class])
	{
		return [(NSAttributedString*)rv string];
	}
	
	//Unsupported
	return nil;
}

- (NSString *)dtx_placeholder
{
	id rv = [self _dtx_placeholder];
	if(rv == nil || [rv isKindOfClass:NSString.class])
	{
		return rv;
	}
	
	if([rv isKindOfClass:NSAttributedString.class])
	{
		return [(NSAttributedString*)rv string];
	}
	
	//Unsupported
	return nil;
}

@end
