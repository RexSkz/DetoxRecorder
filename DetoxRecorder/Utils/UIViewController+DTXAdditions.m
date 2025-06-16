#import "UIViewController+DTXAdditions.h"

@implementation UIViewController (DTXAdditions)

- (void)dtx_showAlertWithTitle:(nullable NSString *)title message:(nullable NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button title for alerts")
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil]];

    [self _dtx_presentAlertControllerOnMainThread:alertController];
}

- (void)dtx_showAlertWithTitle:(nullable NSString *)title message:(nullable NSString *)message duration:(NSTimeInterval)duration
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    // No actions for auto-dismissing alert. It will be dismissed programmatically.
    // If duration is 0 or less, behave like a standard alert with an OK button.
    if (duration <= 0) {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button title for alerts")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil]];
        [self _dtx_presentAlertControllerOnMainThread:alertController];
    } else {
        [self _dtx_presentAlertControllerOnMainThread:alertController];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Check if the alert is still presented by this view controller
            if (self.presentedViewController == alertController) {
                [alertController dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }
}

#pragma mark - Private Helper

- (void)_dtx_presentAlertControllerOnMainThread:(UIAlertController *)alertController
{
    // Ensure presentation happens on the main thread.
    // Also, ensure the view controller is in a state where it can present.
    if (!self.isViewLoaded || self.view.window == nil || self.presentedViewController != nil) {
        // If the view is not in the window hierarchy, or already presenting something,
        // log an error or find a key window's root view controller to present from.
        // For simplicity here, we'll log. A more robust solution might try to find a suitable presenter.
        NSLog(@"Warning: Attempted to present alert on UIViewController (%@) that is not in the window hierarchy or is already presenting.", self);
        // Fallback: Try to present from the key window's rootViewController if self can't.
        // This is a common pattern but use with caution as it might not always be the desired UX.
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootVC && rootVC != self && rootVC.presentedViewController == nil) {
             if ([NSThread isMainThread]) {
                [rootVC presentViewController:alertController animated:YES completion:nil];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [rootVC presentViewController:alertController animated:YES completion:nil];
                });
            }
            return;
        }
        // If rootVC also can't present, the alert might not appear.
        return;
    }

    if ([NSThread isMainThread]) {
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertController animated:YES completion:nil];
        });
    }
}

@end
