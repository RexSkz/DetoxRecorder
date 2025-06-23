#import "DTXRecordedExpectationAction.h"

@implementation DTXRecordedExpectationAction

- (instancetype)initWithExpectString:(NSString *)expectString
{
    self = [super init];
    if (self) {
        _expectString = [expectString copy];
    }
    return self;
}

- (NSString *)codegenSelectorName
{
    // Return the raw expect string. Detox test scripts will execute this directly.
    // This effectively makes the "selector name" the entire line of code for the expectation.
    return self.expectString;
}

- (NSString *)actionDescription
{
    // Provide a concise description for display in any UI that lists recorded actions.
    // Example: "expect(element(by.id('uniqueId'))).toBeVisible()" becomes "Expect: expect"
    // A more sophisticated split might be desirable if the expect strings become very complex.
    NSArray<NSString*>* parts = [self.expectString componentsSeparatedByString:@"("];
    if (parts.count > 0) {
        NSString* firstPart = parts.firstObject;
        // Further refine to get just "expect" or "waitFor" if they are prefixes.
        if ([firstPart hasPrefix:@"expect"] || [firstPart hasPrefix:@"waitFor"]) {
             return [NSString stringWithFormat:@"Expect: %@", firstPart];
        }
        return [NSString stringWithFormat:@"Expect: %@", self.expectString]; // Fallback to full string if not typical
    }
    return @"Expectation"; // Generic fallback
}

- (BOOL)isViewAction
{
    return NO; // Expectations are not typically view actions in the same way taps or scrolls are.
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[DTXRecordedExpectationAction class]]) {
        return NO;
    }

    // Super's isEqual might check class, if not, we should.
    // For DTXRecordedAction, it seems to be a basic NSObject isEqual or similar.
    // If super's isEqual is just pointer comparison, this is fine.
    // If super has actual logic, ensure it's called:
    // if (![super isEqual:object]) return NO;

    DTXRecordedExpectationAction *other = (DTXRecordedExpectationAction *)object;
    return [self.expectString isEqualToString:other.expectString];
}

- (NSUInteger)hash
{
    // Combine super's hash (if it has meaningful properties) with expectString's hash.
    // return super.hash ^ self.expectString.hash;
    // For now, assuming super.hash is basic NSObject hash.
    return self.expectString.hash;
}

// Since this action is generated live and its codegen is direct,
// full serialization/deserialization via `initWithDictionarySerializing`
// and `propertiesForSerialization` might not be strictly necessary for its primary function.
// If these actions were to be saved and reloaded independently of live generation,
// these methods would need to be implemented.
// For Detox generation, `codegenSelectorName` is key.

@end
