#import "UIView+DTXAdditions.h"

@implementation UIView (DTXAdditions)

- (nullable NSString *)dtx_text
{
	if([self isKindOfClass:UILabel.class])
	{
		return ((UILabel*)self).text;
	}

	if([self isKindOfClass:UITextField.class])
	{
		return ((UITextField*)self).text;
	}

	if([self isKindOfClass:UITextView.class])
	{
		return ((UITextView*)self).text;
	}

	if([self isKindOfClass:UIButton.class])
	{
		return ((UIButton*)self).currentTitle;
	}

	return nil;
}

@end
