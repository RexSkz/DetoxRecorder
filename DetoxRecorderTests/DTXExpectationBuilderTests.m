#import <XCTest/XCTest.h>
#import "UIView+DTXAdditions.h"
#import "DTXSelectedElementController.h"
#import "DTXRecordedExpectationAction.h"
// For _DTXElementSearchController, we might need to import its .m file if methods are not in header,
// or create a special testing header. For now, let's assume we can access what we need.
// If _DTXElementSearchController is in DTXElementSearchController.m, we import that.
#import "DTXElementSearchController.h" // This should contain _DTXElementSearchController implementation.


// Forward declaration for the internal search controller class
@interface _DTXElementSearchController : UITableViewController
@property (nonatomic, strong) NSMutableArray* _searchResults; // Assuming this iVar name
@property (nonatomic, strong) NSArray* _allElements; // Assuming this iVar name
@property (nonatomic, strong) UISearchBar* _searchBar; // Assuming this iVar name
- (void)_discoverElements; // Assuming this method exists
- (void)_performSearch; // Assuming this method exists
@end


@interface DTXExpectationBuilderTests : XCTestCase
@end

@implementation DTXExpectationBuilderTests {
    UIWindow* _testWindow;
    UIViewController* _testViewController;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _testViewController = [UIViewController new];
    _testWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    _testWindow.rootViewController = _testViewController;
    [_testWindow makeKeyAndVisible];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [_testWindow setHidden:YES];
    _testWindow.rootViewController = nil;
    _testWindow = nil;
    _testViewController = nil;
    [super tearDown];
}

#pragma mark - UIView+DTXAdditions Tests

- (void)testDTXTextHelper_UILabel {
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Hello Label";
    XCTAssertEqualObjects([label dtx_text], @"Hello Label", @"dtx_text should return UILabel's text.");
}

- (void)testDTXTextHelper_UITextField {
    UITextField *textField = [[UITextField alloc] init];
    textField.text = @"Hello TextField";
    XCTAssertEqualObjects([textField dtx_text], @"Hello TextField", @"dtx_text should return UITextField's text.");
}

- (void)testDTXTextHelper_UITextView {
    UITextView *textView = [[UITextView alloc] init];
    textView.text = @"Hello TextView";
    XCTAssertEqualObjects([textView dtx_text], @"Hello TextView", @"dtx_text should return UITextView's text.");
}

- (void)testDTXTextHelper_UIButton {
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:@"Hello Button" forState:UIControlStateNormal];
    XCTAssertEqualObjects([button dtx_text], @"Hello Button", @"dtx_text should return UIButton's currentTitle.");
}

- (void)testDTXTextHelper_PlainUIView {
    UIView *view = [[UIView alloc] init];
    XCTAssertNil([view dtx_text], @"dtx_text should return nil for a plain UIView.");
}

- (void)testDTXTextHelper_UIButton_NoTitle {
    UIButton *button = [[UIButton alloc] init];
    // No title set
    XCTAssertNil([button dtx_text], @"dtx_text should return nil if button title is not set for normal state.");
}


#pragma mark - _DTXElementSearchController Tests (Initial Setup - More tests in next steps)

// Helper to create a view with specific properties for search tests
- (UIView *)createTestViewWithId:(NSString *)testId text:(NSString *)text label:(NSString *)label className:(NSString *)className parentView:(UIView*)parentView {
    UIView *view;
    Class viewClass = NSClassFromString(className);
    if (viewClass) {
        view = [[viewClass alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    } else {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    }

    if ([view respondsToSelector:@selector(setText:)] && text) {
        [(UILabel *)view setText:text]; // Works for UILabel, UITextField, UITextView if they are the actual class
    } else if ([view isKindOfClass:[UIButton class]] && text) {
        [(UIButton *)view setTitle:text forState:UIControlStateNormal];
    }

    view.accessibilityIdentifier = testId;
    view.accessibilityLabel = label;

    if(parentView) {
        [parentView addSubview:view];
    }

    return view;
}

// Mocking the key window and view hierarchy will be tricky.
// For now, we'll focus on testing the filtering logic of _performSearch
// by manually populating _allElements. A fuller test would involve
// mocking UIApplication.sharedApplication.keyWindow and its subviews.

- (_DTXElementSearchController*)setupSearchControllerWithElements:(NSArray<NSDictionary*>*)elements {
    _DTXElementSearchController *searchController = [[_DTXElementSearchController alloc] init];
    // To properly test viewDidLoad and other view lifecycle methods, we would need to embed it in a window.
    // For now, directly access and set properties.
    [searchController loadViewIfNeeded]; // Loads the view and outlets if any from a NIB/Storyboard, or creates a plain view.
                                        // This also calls viewDidLoad.

    // Manually create a search bar if it's not created in viewDidLoad of the actual class
    // (The actual _DTXElementSearchController creates its own searchBar in viewDidLoad)
    // searchController._searchBar = [UISearchBar new];
    // searchController._searchBar.delegate = searchController; // If the delegate methods are what we test

    searchController._allElements = elements; // Set the elements directly for white-box testing
    searchController._searchResults = [NSMutableArray array]; // Initialize search results array
    return searchController;
}


- (void)testSearchByIdentifier_ExactMatch {
    UIView* view1 = [self createTestViewWithId:@"testId1" text:nil label:nil className:@"UIView" parentView:nil];
    NSDictionary* element1Info = @{@"view": view1, @"accessibilityIdentifier": @"testId1"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[element1Info]];

    searchController._searchBar.text = @"testId1";
    searchController._searchBar.selectedScopeButtonIndex = 1; // Identifier scope
    [searchController _performSearch]; // Call the search method directly

    XCTAssertEqual(searchController._searchResults.count, 1, @"Should find one element by exact ID.");
    XCTAssertEqualObjects(searchController._searchResults.firstObject[@"view"], view1, @"Found element should be view1.");
}

- (void)testSearchByIdentifier_PartialMatch {
    UIView* view1 = [self createTestViewWithId:@"testId1" text:nil label:nil className:@"UIView" parentView:nil];
    NSDictionary* element1Info = @{@"view": view1, @"accessibilityIdentifier": @"testId1"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[element1Info]];

    searchController._searchBar.text = @"testId";
    searchController._searchBar.selectedScopeButtonIndex = 1; // Identifier scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 1, @"Should find one element by partial ID.");
}

- (void)testSearchByIdentifier_NoMatch {
    UIView* view1 = [self createTestViewWithId:@"testId1" text:nil label:nil className:@"UIView" parentView:nil];
    NSDictionary* element1Info = @{@"view": view1, @"accessibilityIdentifier": @"testId1"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[element1Info]];

    searchController._searchBar.text = @"nonExistentId";
    searchController._searchBar.selectedScopeButtonIndex = 1; // Identifier scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 0, @"Should find no elements for non-matching ID.");
}

- (void)testSearchByText_ExactMatch_Label {
    UILabel* labelView = (UILabel*)[self createTestViewWithId:nil text:@"Hello World" label:nil className:@"UILabel" parentView:nil];
    NSDictionary* elementInfo = @{@"view": labelView, @"text": @"Hello World"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[elementInfo]];

    searchController._searchBar.text = @"Hello World";
    searchController._searchBar.selectedScopeButtonIndex = 2; // Text scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 1, @"Should find one element by exact text.");
    XCTAssertEqualObjects(searchController._searchResults.firstObject[@"view"], labelView, @"Found element should be the label.");
}

- (void)testSearchByText_PartialMatch_TextField {
    UITextField* textFieldView = (UITextField*)[self createTestViewWithId:nil text:@"Sample Text" label:nil className:@"UITextField" parentView:nil];
    NSDictionary* elementInfo = @{@"view": textFieldView, @"text": @"Sample Text"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[elementInfo]];

    searchController._searchBar.text = @"Sample";
    searchController._searchBar.selectedScopeButtonIndex = 2; // Text scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 1, @"Should find one element by partial text.");
}

- (void)testSearchByText_NoMatch {
    UILabel* labelView = (UILabel*)[self createTestViewWithId:nil text:@"Hello World" label:nil className:@"UILabel" parentView:nil];
    NSDictionary* elementInfo = @{@"view": labelView, @"text": @"Hello World"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[elementInfo]];

    searchController._searchBar.text = @"NonExistent";
    searchController._searchBar.selectedScopeButtonIndex = 2; // Text scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 0, @"Should find no elements for non-matching text.");
}


- (void)testSearchByLabel_ExactMatch {
    UIView* view1 = [self createTestViewWithId:nil text:nil label:@"Accessibility Label" className:@"UIView" parentView:nil];
    NSDictionary* element1Info = @{@"view": view1, @"accessibilityLabel": @"Accessibility Label"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[element1Info]];

    searchController._searchBar.text = @"Accessibility Label";
    searchController._searchBar.selectedScopeButtonIndex = 3; // Label scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 1, @"Should find one element by exact label.");
}

- (void)testSearchByLabel_PartialMatch {
    UIView* view1 = [self createTestViewWithId:nil text:nil label:@"Accessibility Label" className:@"UIView" parentView:nil];
    NSDictionary* element1Info = @{@"view": view1, @"accessibilityLabel": @"Accessibility Label"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[element1Info]];

    searchController._searchBar.text = @"Accessibility";
    searchController._searchBar.selectedScopeButtonIndex = 3; // Label scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 1, @"Should find one element by partial label.");
}

- (void)testSearchByAny_MatchesID {
    UIView* viewWithId = [self createTestViewWithId:@"anySearchID" text:nil label:nil className:@"UIView" parentView:nil];
    NSDictionary* idInfo = @{@"view": viewWithId, @"accessibilityIdentifier": @"anySearchID"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[idInfo]];

    searchController._searchBar.text = @"anySearchID";
    searchController._searchBar.selectedScopeButtonIndex = 0; // Any scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 1, @"'Any' scope should find by ID.");
}

- (void)testSearchByAny_MatchesText {
    UILabel* viewWithText = (UILabel*)[self createTestViewWithId:nil text:@"anySearchText" label:nil className:@"UILabel" parentView:nil];
    NSDictionary* textInfo = @{@"view": viewWithText, @"text": @"anySearchText"};
   _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[textInfo]];

    searchController._searchBar.text = @"anySearchText";
    searchController._searchBar.selectedScopeButtonIndex = 0; // Any scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 1, @"'Any' scope should find by text.");
}

- (void)testSearchByAny_MatchesLabel {
    UIView* viewWithLabel = [self createTestViewWithId:nil text:nil label:@"anySearchLabel" className:@"UIView" parentView:nil];
    NSDictionary* labelInfo = @{@"view": viewWithLabel, @"accessibilityLabel": @"anySearchLabel"};
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[labelInfo]];

    searchController._searchBar.text = @"anySearchLabel";
    searchController._searchBar.selectedScopeButtonIndex = 0; // Any scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 1, @"'Any' scope should find by label.");
}

- (void)testSearchEmptyResults {
    _DTXElementSearchController *searchController = [self setupSearchControllerWithElements:@[]]; // No elements

    searchController._searchBar.text = @"someText";
    searchController._searchBar.selectedScopeButtonIndex = 0; // Any scope
    [searchController _performSearch];

    XCTAssertEqual(searchController._searchResults.count, 0, @"Search should yield empty results for no elements.");
}


// More tests for _DTXElementSearchController (e.g., _discoverElements, different combinations)
// would require more involved mocking of the UIWindow and view hierarchy.

#pragma mark - DTXSelectedElementController Tests (Initial Setup)

- (DTXSelectedElementController*)setupSelectedElementControllerWithView:(UIView*)view {
    DTXSelectedElementController *controller = [DTXSelectedElementController new];
    controller.selectedView = view;
    [controller loadViewIfNeeded]; // Calls viewDidLoad
    return controller;
}

- (void)testGenerateMatchers_ById {
    UIView* testView = [UIView new];
    testView.accessibilityIdentifier = @"testId";
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testView];

    // _generateMatchers is called in viewDidLoad, which is called by setupSelectedElementControllerWithView

    BOOL found = NO;
    for (NSDictionary* matcherInfo in controller.suggestedMatchers) {
        if ([matcherInfo[@"matcherString"] isEqualToString:@"by.id('testId')"]) {
            found = YES;
            XCTAssertEqualObjects(matcherInfo[@"displayText"], @"ID: “testId”");
            break;
        }
    }
    XCTAssertTrue(found, @"Should generate by.id matcher.");
}

- (void)testGenerateMatchers_ByText {
    UILabel* testLabel = [UILabel new];
    testLabel.text = @"testText";
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testLabel];

    BOOL found = NO;
    for (NSDictionary* matcherInfo in controller.suggestedMatchers) {
        if ([matcherInfo[@"matcherString"] isEqualToString:@"by.text('testText')"]) {
            found = YES;
            XCTAssertEqualObjects(matcherInfo[@"displayText"], @"Text: “testText”");
            break;
        }
    }
    XCTAssertTrue(found, @"Should generate by.text matcher.");
}

- (void)testGenerateMatchers_ByLabel {
    UIView* testView = [UIView new];
    testView.accessibilityLabel = @"testAccessLabel";
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testView];

    BOOL found = NO;
    for (NSDictionary* matcherInfo in controller.suggestedMatchers) {
        if ([matcherInfo[@"matcherString"] isEqualToString:@"by.label('testAccessLabel')"]) {
            found = YES;
            XCTAssertEqualObjects(matcherInfo[@"displayText"], @"Label: “testAccessLabel”");
            break;
        }
    }
    XCTAssertTrue(found, @"Should generate by.label matcher.");
}

- (void)testGenerateMatchers_ByType {
    UILabel* testLabel = [UILabel new]; // Using UILabel to have a concrete type
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testLabel];

    NSString* expectedMatcherString = [NSString stringWithFormat:@"by.type('%@')", NSStringFromClass([UILabel class])];
    NSString* expectedDisplayText = [NSString stringWithFormat:@"Type: “%@”", NSStringFromClass([UILabel class])];

    BOOL found = NO;
    for (NSDictionary* matcherInfo in controller.suggestedMatchers) {
        if ([matcherInfo[@"matcherString"] isEqualToString:expectedMatcherString]) {
            found = YES;
            XCTAssertEqualObjects(matcherInfo[@"displayText"], expectedDisplayText);
            break;
        }
    }
    XCTAssertTrue(found, @"Should generate by.type matcher.");
}

- (void)testGenerateMatchers_MultipleProperties {
    UITextField* testField = [UITextField new];
    testField.accessibilityIdentifier = @"fieldId";
    testField.text = @"fieldText";
    testField.accessibilityLabel = @"fieldLabel";
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testField];

    XCTAssertTrue(controller.suggestedMatchers.count >= 4, @"Should have at least ID, Text, Label, and Type matchers.");
    // Check for presence of each (exact string check done in other tests)
    NSPredicate *idPred = [NSPredicate predicateWithFormat:@"matcherString CONTAINS 'by.id'"];
    NSPredicate *textPred = [NSPredicate predicateWithFormat:@"matcherString CONTAINS 'by.text'"];
    NSPredicate *labelPred = [NSPredicate predicateWithFormat:@"matcherString CONTAINS 'by.label'"];
    NSPredicate *typePred = [NSPredicate predicateWithFormat:@"matcherString CONTAINS 'by.type'"];

    XCTAssertTrue([controller.suggestedMatchers filteredArrayUsingPredicate:idPred].count == 1);
    XCTAssertTrue([controller.suggestedMatchers filteredArrayUsingPredicate:textPred].count == 1);
    XCTAssertTrue([controller.suggestedMatchers filteredArrayUsingPredicate:labelPred].count == 1);
    XCTAssertTrue([controller.suggestedMatchers filteredArrayUsingPredicate:typePred].count == 1);
}

- (void)testGenerateMatchers_NoUsefulProperties {
    UIView* testView = [UIView new]; // Plain UIView
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testView];

    // Only by.type should be generated
    BOOL byTypeFound = NO;
    BOOL otherFound = NO;
    NSString* expectedTypeMatcherString = [NSString stringWithFormat:@"by.type('%@')", NSStringFromClass([UIView class])];

    for (NSDictionary* matcherInfo in controller.suggestedMatchers) {
        if ([matcherInfo[@"matcherString"] isEqualToString:expectedTypeMatcherString]) {
            byTypeFound = YES;
        } else {
            otherFound = YES;
        }
    }
    XCTAssertTrue(byTypeFound, @"by.type should be generated for a plain view.");
    XCTAssertFalse(otherFound, @"No other matchers should be generated for a plain view with no specific properties.");
}


- (void)testMatcherSanitization_SingleQuote {
    UIView* testView = [UIView new];
    testView.accessibilityIdentifier = @"elem'nt_id";
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testView];

    BOOL found = NO;
    for (NSDictionary* matcherInfo in controller.suggestedMatchers) {
        if ([matcherInfo[@"matcherString"] isEqualToString:@"by.id('elem\\'nt_id')"]) {
            found = YES;
            break;
        }
    }
    XCTAssertTrue(found, @"Matcher string should correctly sanitize single quotes.");
}

- (void)testMatcherSanitization_Backslash {
    UIView* testView = [UIView new];
    testView.accessibilityIdentifier = @"elem\\nt_id";
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testView];

    BOOL found = NO;
    for (NSDictionary* matcherInfo in controller.suggestedMatchers) {
        if ([matcherInfo[@"matcherString"] isEqualToString:@"by.id('elem\\\\nt_id')"]) {
            found = YES;
            break;
        }
    }
    XCTAssertTrue(found, @"Matcher string should correctly sanitize backslashes.");
}

- (void)testGenerateAvailableExpects_GenericView {
    UIView* testView = [UIView new];
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testView];
    // _generateAvailableExpects is called from tableView:didSelectRowAtIndexPath: when a matcher is selected.
    // Manually select a matcher first.
    controller.selectedMatcher = @{@"matcherString": @"by.type('UIView')", @"displayText": @"Type: UIView"};
    // Then call it directly.
    [controller _generateAvailableExpects];

    NSPredicate *visiblePred = [NSPredicate predicateWithFormat:@"expectType == 'toBeVisible'"];
    NSPredicate *existPred = [NSPredicate predicateWithFormat:@"expectType == 'toExist'"];

    XCTAssertTrue([controller.availableExpects filteredArrayUsingPredicate:visiblePred].count == 1, @"Should suggest .toBeVisible()");
    XCTAssertTrue([controller.availableExpects filteredArrayUsingPredicate:existPred].count == 1, @"Should suggest .toExist()");
}

- (void)testGenerateAvailableExpects_LabelWithText {
    UILabel* testLabel = [UILabel new];
    testLabel.text = @"Hello"; // Give it some text
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testLabel];
    controller.selectedMatcher = @{@"matcherString": @"by.type('UILabel')", @"displayText": @"Type: UILabel"};
    [controller _generateAvailableExpects];

    NSPredicate *textPred = [NSPredicate predicateWithFormat:@"expectType == 'toHaveText'"];
    XCTAssertTrue([controller.availableExpects filteredArrayUsingPredicate:textPred].count == 1, @"Should suggest .toHaveText() for UILabel.");
}

- (void)testGenerateAvailableExpects_ViewWithID {
    UIView* testView = [UIView new];
    testView.accessibilityIdentifier = @"viewId";
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:testView];
    controller.selectedMatcher = @{@"matcherString": @"by.id('viewId')", @"displayText": @"ID: viewId"};
    [controller _generateAvailableExpects];

    NSPredicate *idPred = [NSPredicate predicateWithFormat:@"expectType == 'toHaveId'"];
    XCTAssertTrue([controller.availableExpects filteredArrayUsingPredicate:idPred].count == 1, @"Should suggest .toHaveId() for view with ID.");
}


- (void)testUpdateGeneratedExpectString_NoParams {
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:[UIView new]];
    controller.selectedMatcher = @{@"matcherString": @"by.id('test_id')"};
    NSDictionary* expectInfo = @{@"expectType": @"toBeVisible", @"requiresParameter": @NO};

    [controller _updateGeneratedExpectStringWithExpect:expectInfo parameterValue:nil];

    XCTAssertEqualObjects(controller.generatedExpectString, @"expect(element(by.id('test_id'))).toBeVisible()");
}

- (void)testUpdateGeneratedExpectString_WithParams {
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:[UIView new]];
    controller.selectedMatcher = @{@"matcherString": @"by.id('test_id')"};
    NSDictionary* expectInfo = @{@"expectType": @"toHaveText", @"requiresParameter": @YES};

    [controller _updateGeneratedExpectStringWithExpect:expectInfo parameterValue:@"hello world"];

    XCTAssertEqualObjects(controller.generatedExpectString, @"expect(element(by.id('test_id'))).toHaveText('hello world')");
}

- (void)testExpectParameterSanitization_SingleQuote {
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:[UIView new]];
    controller.selectedMatcher = @{@"matcherString": @"by.id('test_id')"};
    NSDictionary* expectInfo = @{@"expectType": @"toHaveText", @"requiresParameter": @YES};

    [controller _updateGeneratedExpectStringWithExpect:expectInfo parameterValue:@"text with ' quote"];

    XCTAssertEqualObjects(controller.generatedExpectString, @"expect(element(by.id('test_id'))).toHaveText('text with \\' quote')");
}

- (void)testExpectParameterSanitization_Backslash {
    DTXSelectedElementController *controller = [self setupSelectedElementControllerWithView:[UIView new]];
    controller.selectedMatcher = @{@"matcherString": @"by.id('test_id')"};
    NSDictionary* expectInfo = @{@"expectType": @"toHaveText", @"requiresParameter": @YES};

    [controller _updateGeneratedExpectStringWithExpect:expectInfo parameterValue:@"text with \\ backslash"];

    XCTAssertEqualObjects(controller.generatedExpectString, @"expect(element(by.id('test_id'))).toHaveText('text with \\\\ backslash')");
}

#pragma mark - DTXRecordedExpectationAction Tests

- (void)testRecordedExpectationActionProperties {
    NSString* expectStr = @"expect(element(by.id('foo'))).toBeVisible()";
    DTXRecordedExpectationAction* action = [[DTXRecordedExpectationAction alloc] initWithExpectString:expectStr];

    XCTAssertEqualObjects(action.expectString, expectStr, @"expectString property not set correctly.");
    XCTAssertEqualObjects(action.codegenSelectorName, expectStr, @"codegenSelectorName should be the expectString.");
    XCTAssertEqualObjects(action.actionDescription, @"Expect: expect", @"actionDescription is not as expected.");
    XCTAssertFalse(action.isViewAction, @"isViewAction should be NO.");
}

- (void)testRecordedExpectationActionEquality_Equal {
    NSString* expectStr1 = @"expect(element(by.id('foo'))).toBeVisible()";
    DTXRecordedExpectationAction* action1 = [[DTXRecordedExpectationAction alloc] initWithExpectString:expectStr1];

    NSString* expectStr2 = @"expect(element(by.id('foo'))).toBeVisible()";
    DTXRecordedExpectationAction* action2 = [[DTXRecordedExpectationAction alloc] initWithExpectString:expectStr2];

    XCTAssertEqualObjects(action1, action2, @"Actions with the same expect string should be equal.");
    XCTAssertEqual(action1.hash, action2.hash, @"Hashes for equal actions should be the same.");
}

- (void)testRecordedExpectationActionEquality_NotEqual {
    NSString* expectStr1 = @"expect(element(by.id('foo'))).toBeVisible()";
    DTXRecordedExpectationAction* action1 = [[DTXRecordedExpectationAction alloc] initWithExpectString:expectStr1];

    NSString* expectStr2 = @"expect(element(by.id('bar'))).toBeVisible()";
    DTXRecordedExpectationAction* action2 = [[DTXRecordedExpectationAction alloc] initWithExpectString:expectStr2];

    XCTAssertNotEqualObjects(action1, action2, @"Actions with different expect strings should not be equal.");
}


// Helper to access internal methods/properties of _DTXElementSearchController for testing
// This would typically go into a _DTXElementSearchController+Testing.h file or similar.
// For simplicity in this single-file generation:
@interface _DTXElementSearchController (Testing)
@property (nonatomic, strong) NSMutableArray* _searchResults;
@property (nonatomic, strong) NSArray* _allElements;
@property (nonatomic, strong) UISearchBar* _searchBar;
- (void)_discoverElements;
- (void)_performSearch;
@end


// Helper to access internal methods/properties of DTXSelectedElementController for testing
@interface DTXSelectedElementController (Testing)
- (void)_generateMatchers;
- (void)_generateAvailableExpects;
- (void)_updateGeneratedExpectStringWithExpect:(NSDictionary*)selectedExpect parameterValue:(nullable NSString*)parameterValue;
@end


#pragma mark - UIViewController+DTXAdditions Tests

- (void)testShowAlert_PresentsAlertController {
    XCTestExpectation* expectation = [self expectationWithDescription:@"Alert presentation expectation"];

    [_testViewController dtx_showAlertWithTitle:@"Test Title" message:@"Test Message"];

    // Give a short delay for the presentation to occur
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNotNil(self->_testViewController.presentedViewController, @"Should present a view controller.");
        XCTAssertTrue([self->_testViewController.presentedViewController isKindOfClass:[UIAlertController class]], @"Presented view controller should be a UIAlertController.");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowAlert_CorrectTitleAndMessage {
    XCTestExpectation* expectation = [self expectationWithDescription:@"Alert content expectation"];
    [_testViewController dtx_showAlertWithTitle:@"Test Title" message:@"Test Message"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController* alert = (UIAlertController*)self->_testViewController.presentedViewController;
        XCTAssertTrue([alert.title isEqualToString:@"Test Title"], @"Alert title is incorrect.");
        XCTAssertTrue([alert.message isEqualToString:@"Test Message"], @"Alert message is incorrect.");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowAlert_HasOKAction {
    XCTestExpectation* expectation = [self expectationWithDescription:@"Alert OK action expectation"];
    [_testViewController dtx_showAlertWithTitle:@"Test Title" message:@"Test Message"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController* alert = (UIAlertController*)self->_testViewController.presentedViewController;
        XCTAssertEqual(alert.actions.count, 1, @"Alert should have one action.");
        XCTAssertEqualObjects(alert.actions.firstObject.title, NSLocalizedString(@"OK", nil), @"Action title should be OK.");
        XCTAssertEqual(alert.actions.firstObject.style, UIAlertActionStyleDefault, @"Action style should be Default.");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowAlertWithDuration_PresentsAlertController {
    XCTestExpectation* expectation = [self expectationWithDescription:@"Alert with duration presentation expectation"];
    [_testViewController dtx_showAlertWithTitle:@"Test Title" message:@"Test Message" duration:0.1];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ // Shorter delay to check before auto-dismiss
        XCTAssertNotNil(self->_testViewController.presentedViewController, @"Should present a view controller.");
        XCTAssertTrue([self->_testViewController.presentedViewController isKindOfClass:[UIAlertController class]], @"Presented view controller should be a UIAlertController.");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowAlertWithDuration_CorrectTitleAndMessage {
     XCTestExpectation* expectation = [self expectationWithDescription:@"Alert with duration content expectation"];
    [_testViewController dtx_showAlertWithTitle:@"Duration Title" message:@"Duration Message" duration:0.2];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController* alert = (UIAlertController*)self->_testViewController.presentedViewController;
        XCTAssertTrue([alert.title isEqualToString:@"Duration Title"], @"Alert title is incorrect.");
        XCTAssertTrue([alert.message isEqualToString:@"Duration Message"], @"Alert message is incorrect.");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowAlertWithDuration_NoExplicitOKActionForAutoDismiss_PositiveDuration {
    XCTestExpectation* expectation = [self expectationWithDescription:@"Alert no OK action for positive duration"];
    [_testViewController dtx_showAlertWithTitle:@"Test Title" message:@"Test Message" duration:0.1];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController* alert = (UIAlertController*)self->_testViewController.presentedViewController;
        XCTAssertEqual(alert.actions.count, 0, @"Alert with positive duration should have no explicit actions for auto-dismissal.");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowAlertWithDuration_BehavesAsStandardAlertForZeroDuration {
    XCTestExpectation* expectation = [self expectationWithDescription:@"Alert behaves as standard for zero duration"];
    [_testViewController dtx_showAlertWithTitle:@"Zero Duration" message:@"Test" duration:0.0];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController* alert = (UIAlertController*)self->_testViewController.presentedViewController;
        XCTAssertEqual(alert.actions.count, 1, @"Alert with zero duration should have one OK action.");
        XCTAssertEqualObjects(alert.actions.firstObject.title, NSLocalizedString(@"OK", nil));
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowAlertWithDuration_AttemptsDismissal {
    XCTestExpectation* expectation = [self expectationWithDescription:@"Alert auto-dismissal expectation"];

    [_testViewController dtx_showAlertWithTitle:@"Auto Dismiss" message:@"Test" duration:0.1];

    // Check that it's initially presented
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNotNil(self->_testViewController.presentedViewController, @"Alert should be presented initially.");
    });

    // Wait for longer than the duration
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNil(self->_testViewController.presentedViewController, @"Alert should be dismissed after its duration.");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testShowAlert_CalledFromBackgroundThread {
    XCTestExpectation* expectation = [self expectationWithDescription:@"Alert presentation from background thread"];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        [self->_testViewController dtx_showAlertWithTitle:@"Background Thread Test" message:@"Message"];
    });

    // Check on the main thread after a delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertNotNil(self->_testViewController.presentedViewController, @"Should present an alert even when called from background thread.");
        XCTAssertTrue([self->_testViewController.presentedViewController isKindOfClass:[UIAlertController class]], @"Presented VC should be UIAlertController.");
        // Cleanup presented alert for next tests if any
        [self->_testViewController.presentedViewController dismissViewControllerAnimated:NO completion:^{
            [expectation fulfill];
        }];
    });

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}


@end
