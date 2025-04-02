//
//  DTXFabricComponentViewUtils.m
//  DetoxRecorder
//
//  Created by ivan on 2025/4/1.
//  Copyright © 2025 Wix. All rights reserved.
//

#import "DTXFabricComponentViewUtils.h"

@implementation DTXFabricComponentViewUtils

+ (nullable NSString *)textOfRCTParagraphTextView:(nonnull UIView *)textView {
    static Class RCTParagraphComponentView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RCTParagraphComponentView = NSClassFromString(@"RCTParagraphComponentView");
    });
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    UIView *componentView = [textView superview];
    if ([componentView isKindOfClass:RCTParagraphComponentView]) {
        if ([componentView respondsToSelector:@selector(attributedText)]) {
            NSAttributedString *attrString = [componentView performSelector:@selector(attributedText)];
            return attrString.string;
        }
    }
#pragma clang diagnostic pop
    
    return nil;
}

@end
