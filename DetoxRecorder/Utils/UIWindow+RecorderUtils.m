//
//  UIWindow+RecorderUtils.m
//  DetoxRecorder
//
//  Created by Leo Natan (Wix) on 7/7/20.
//  Copyright © 2019-2021 Wix. All rights reserved.
//

#import "UIWindow+RecorderUtils.h"

@interface UIWindowScene ()

+ (instancetype)_keyWindowScene;
@property(readonly, nonatomic) UIWindow *_keyWindow;
- (id)_allWindowsIncludingInternalWindows:(_Bool)arg1 onlyVisibleWindows:(_Bool)arg2;

@end

@interface UIWindow (GREYExposed)

- (id)firstResponder;
+ (instancetype)keyWindow;
+ (NSArray<UIWindow*>*)allWindowsIncludingInternalWindows:(_Bool)arg1 onlyVisibleWindows:(_Bool)arg2;

@end

DTX_DIRECT_MEMBERS
@implementation UIWindow (RecorderUtils)

+ (UIWindow*)dtxrec_keyWindow
{
    UIScene *scene = [[[[UIApplication sharedApplication] connectedScenes] allObjects] firstObject];
    if([scene.delegate conformsToProtocol:@protocol(UIWindowSceneDelegate)])
    {
        return [(id <UIWindowSceneDelegate>)scene.delegate window];
    }
    return nil;
}

+ (NSArray<UIWindow *> *)dtxrec_allKeyWindowSceneWindows
{
	id scene = nil;
	return [self dtxrec_allWindowsForScene:scene];
}

+ (NSArray<UIWindow*>*)dtxrec_allWindowsForScene:(id)scene
{
	NSMutableArray<UIWindow*>* windows = [[self dtxrec_allWindows] mutableCopy];
	return windows;
}

+ (NSArray<UIWindow*>*)dtxrec_allWindows
{
	return [[UIWindow allWindowsIncludingInternalWindows:YES onlyVisibleWindows:NO] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hidden == NO"]];
}

+ (void)_dtxrec_enumerateWindows:(NSArray<UIWindow*>*)windows usingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block
{
	[windows enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		block(obj, idx, stop);
	}];
}

+ (void)dtxrec_enumerateAllWindowsUsingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block
{
	[self _dtxrec_enumerateWindows:self.dtxrec_allWindows usingBlock:block];
}

+ (void)dtxrec_enumerateKeyWindowSceneWindowsUsingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block
{
	id scene = nil;
	
	if (@available(iOS 13.0, *))
	{
		scene = UIWindowScene._keyWindowScene;
	}
	
	[self dtxrec_enumerateWindowsInScene:scene usingBlock:block];
}

+ (void)dtxrec_enumerateWindowsInScene:(id)scene usingBlock:(void (NS_NOESCAPE ^)(UIWindow* obj, NSUInteger idx, BOOL *stop))block
{
	[self _dtxrec_enumerateWindows:[self dtxrec_allWindowsForScene:scene] usingBlock:block];
}

@end
