//
//  DTXElementSearchController.m
//  DetoxRecorder
//
//  Created by Leo Natan on 12/15/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXElementSearchController.h"
#import "UIView+DTXAdditions.h"
#import "DTXSelectedElementController.h"

@interface UIViewController ()

- (void)_dismissPresentation:(id)sender;

@end

@interface _DTXElementSearchController : UITableViewController @end

@interface _DTXElementSearchController () <UISearchControllerDelegate, UISearchBarDelegate>
{
	UISearchBar* _searchBar;
	NSMutableArray* _searchResults;
	NSArray* _allElements;
}

@end

@implementation _DTXElementSearchController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_searchResults = [NSMutableArray new];
	self.title = @"Search";
	
	_searchBar = [UISearchBar new];
	_searchBar.scopeButtonTitles = @[@"Any", @"Identifier", @"Text", @"Label"];
	_searchBar.showsScopeBar = YES;
	_searchBar.showsCancelButton = YES;
	_searchBar.searchBarStyle = UISearchBarStyleMinimal;
	_searchBar.placeholder = @"Search";
	_searchBar.delegate = self;
	[_searchBar setValue:@NO forKey:@"autoDisableCancelButton"];
	
	self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	self.tableView.hidden = YES;
	
	self.navigationItem.titleView = _searchBar;
}

- (void)_discoverElements
{
	NSMutableArray* elements = [NSMutableArray new];

	UIWindow* keyWindow = UIApplication.sharedApplication.keyWindow;
	NSMutableArray<UIView*>* viewsToProcess = [NSMutableArray arrayWithObject:keyWindow];

	while(viewsToProcess.count > 0)
	{
		UIView* currentView = viewsToProcess.firstObject;
		[viewsToProcess removeObjectAtIndex:0];

		NSString* accessibilityIdentifier = currentView.accessibilityIdentifier;
		NSString* text = currentView.dtx_text;
		NSString* accessibilityLabel = currentView.accessibilityLabel;

		if(accessibilityIdentifier.length > 0 || text.length > 0 || accessibilityLabel.length > 0)
		{
			NSMutableDictionary* elementInfo = [NSMutableDictionary new];
			elementInfo[@"view"] = currentView;
			if(accessibilityIdentifier.length > 0)
			{
				elementInfo[@"accessibilityIdentifier"] = accessibilityIdentifier;
			}
			if(text.length > 0)
			{
				elementInfo[@"text"] = text;
			}
			if(accessibilityLabel.length > 0)
			{
				elementInfo[@"accessibilityLabel"] = accessibilityLabel;
			}
			[elements addObject:elementInfo.copy];
		}

		[viewsToProcess addObjectsFromArray:currentView.subviews];
	}

	_allElements = elements.copy;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self _discoverElements];
	[_searchBar becomeFirstResponder];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
	return UIBarPositionTopAttached;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self.navigationController _dismissPresentation:nil];
}

- (void)_performSearch
{
	NSString* searchText = _searchBar.text;
	NSInteger selectedScope = _searchBar.selectedScopeButtonIndex;

	[_searchResults removeAllObjects];

	if(searchText.length == 0)
	{
		self.tableView.hidden = YES;
		[self.tableView reloadData];
		return;
	}

	for (NSDictionary* elementInfo in _allElements)
	{
		NSString* accessibilityIdentifier = elementInfo[@"accessibilityIdentifier"];
		NSString* text = elementInfo[@"text"];
		NSString* accessibilityLabel = elementInfo[@"accessibilityLabel"];

		BOOL match = NO;

		switch (selectedScope)
		{
			case 0: // Any
				if ([accessibilityIdentifier localizedCaseInsensitiveContainsString:searchText] ||
					[text localizedCaseInsensitiveContainsString:searchText] ||
					[accessibilityLabel localizedCaseInsensitiveContainsString:searchText])
				{
					match = YES;
				}
				break;
			case 1: // Identifier
				if ([accessibilityIdentifier localizedCaseInsensitiveContainsString:searchText])
				{
					match = YES;
				}
				break;
			case 2: // Text
				if ([text localizedCaseInsensitiveContainsString:searchText])
				{
					match = YES;
				}
				break;
			case 3: // Label
				if ([accessibilityLabel localizedCaseInsensitiveContainsString:searchText])
				{
					match = YES;
				}
				break;
		}

		if(match)
		{
			[_searchResults addObject:elementInfo];
		}
	}

	[self.tableView reloadData];
	self.tableView.hidden = _searchResults.count == 0;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[self _performSearch];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[self _performSearch];
	[_searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	[self _performSearch];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString* const CellIdentifier = @"ElementCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if(cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}
	
	NSDictionary* elementInfo = _searchResults[indexPath.row];
	UIView* view = elementInfo[@"view"];

	cell.textLabel.text = NSStringFromClass(view.class);
	cell.detailTextLabel.text = elementInfo[@"accessibilityIdentifier"];

	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* elementInfo = _searchResults[indexPath.row];
	UIView* selectedView = elementInfo[@"view"];

	DTXSelectedElementController* selectedElementController = [DTXSelectedElementController new];
	selectedElementController.selectedView = selectedView;
	
	[self.navigationController pushViewController:selectedElementController animated:YES];
}

@end

@interface DTXElementSearchController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate>

@end

@implementation DTXElementSearchController

- (instancetype)init
{
	self = [super initWithRootViewController:[_DTXElementSearchController new]];
	
	if(self)
	{
		UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_dismissPresentation:)];
		tgr.delegate = self;
		[self.view addGestureRecognizer:tgr];
		
		self.modalPresentationStyle = UIModalPresentationCustom;
		self.transitioningDelegate = self;
//		self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		
		self.navigationBarHidden = YES;
	}
	
	return self;
}

- (void)_dismissPresentation:(UITapGestureRecognizer*)sender
{
	if(self.navigationController)
	{
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	}
	else
	{
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
	return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
	return self;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
	return transitionContext.isAnimated ? 0.5 : 0.0;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	UIViewController* from = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
 	UIViewController* to = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	
	if(to == self)
	{
		to.view.backgroundColor = UIColor.clearColor;
		[transitionContext.containerView addSubview:to.view];
		[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0.0 options:0 animations:^{
			to.view.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.15];
			[self setNavigationBarHidden:NO animated:YES];
		} completion:^(BOOL finished) {
			[transitionContext completeTransition:finished];
		}];
	}
	else
	{
		[self.topViewController.view setHidden:YES];
		
		[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:500 initialSpringVelocity:0.0 options:0 animations:^{
			from.view.backgroundColor = UIColor.clearColor;
			[self setNavigationBarHidden:YES animated:YES];
		} completion:^(BOOL finished) {
			[from.view removeFromSuperview];
			[self.topViewController.view setHidden:NO];
			[transitionContext completeTransition:finished];
		}];
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if([touch.view isDescendantOfView:self.topViewController.view])
	{
		return NO;
	}
	
	return YES;
}

@end
