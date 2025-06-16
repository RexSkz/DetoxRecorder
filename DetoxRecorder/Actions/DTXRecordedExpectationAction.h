#import "DTXRecordedAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTXRecordedExpectationAction : DTXRecordedAction

@property (nonatomic, copy, readonly) NSString *expectString;

- (instancetype)initWithExpectString:(NSString *)expectString NS_DESIGNATED_INITIALIZER;

// Override init to ensure designated initializer is used.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
