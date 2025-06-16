#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (DTXAdditions)

- (void)dtx_showAlertWithTitle:(nullable NSString *)title message:(nullable NSString *)message;
// Overload for alert with a specific duration before auto-dismissal (optional)
- (void)dtx_showAlertWithTitle:(nullable NSString *)title message:(nullable NSString *)message duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
