//
//  DTXRNEnvironment.m
//  DetoxRecorder
//
//  Created by ivan on 2025/3/28.
//  Copyright © 2025 Wix. All rights reserved.
//

#import "DTXRNEnvironment.h"

@implementation DTXRNEnvironment

+ (BOOL)isFabricEnabled {
    static BOOL isFabricEnable;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // ExpoFabricViewObjC only exists when RCT_NEW_ARCH_ENABLED=1.
        // In this way, it is possible to determine at runtime whether Fabric is enabled,
        // and there is no need to inject the macro RCT_NEW_ARCH_ENABLED.
        isFabricEnable = (NSClassFromString(@"ExpoFabricViewObjC") != nil);
    });
    return isFabricEnable;
}

@end
