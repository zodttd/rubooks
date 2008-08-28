// HideableNavBar, for Books.app by Zachary Brewster-Geisz

/*

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; version 2
   of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#import <UIKit/UIHardware.h>
#import "HideableNavBar.h"
#import "FileBrowser.h"

//#include "dolog.h"
@implementation HideableNavBar

- (HideableNavBar *)initWithFrame:(struct CGRect)rect
{
	[super initWithFrame:rect];
	defaults = [BooksDefaultsController sharedBooksDefaultsController];
	// Try to infer whether the navbar is on the top or bottom of the screen.
	if (rect.origin.y == 0.0f)
		isTop = YES;
	else
		isTop = NO;
	translate =  [[UITransformAnimation alloc] initWithTarget: self];
	animator = [[UIAnimator alloc] init];
	hidden = NO;
	_textIsOnTop = NO;
	_pixOnTop = NO;
	_transView = nil;
	_extensions = nil;
	_browserArray = [[NSMutableArray alloc] initWithCapacity:3]; // eh?
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(shouldReloadTopBrowser:)
												 name:RELOADTOPBROWSER
											   object:nil];
	return self;
}

- (HideableNavBar *)initWithFrame:(struct CGRect)rect isTop:(BOOL)top
{
	[super initWithFrame:rect];
	defaults = [BooksDefaultsController sharedBooksDefaultsController];
	// If we can't infer, use this method instead.
	isTop = top;

	translate =  [[UITransformAnimation alloc] initWithTarget: self];
	animator = [[UIAnimator alloc] init];
	hidden = NO;
	_textIsOnTop = NO;
	_transView = nil;
	_extensions = nil;
	_browserArray = [[NSMutableArray alloc] initWithCapacity:3]; // eh?
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(shouldReloadTopBrowser:)
												 name:RELOADTOPBROWSER
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(shouldReloadAllBrowsers:)
												 name:RELOADALLBROWSERS
											   object:nil];
	return self;
}

- (void)setBrowserDelegate:(id)bDelegate
{
	_browserDelegate = [bDelegate retain];
}

- (void)popNavigationItem
{
	if (_textIsOnTop || _pixOnTop)
	{
		GSLog(@"Popped from text to %@\n", [[_browserArray lastObject] path]);
		//[[_browserArray lastObject] reloadData]; // to remove the "unread" dot
	}
	else
	{
		[_browserArray removeLastObject];
	}

	struct CGRect fullRect = [defaults fullScreenApplicationContentRect];
	if (!CGRectEqualToRect([[_browserArray lastObject] frame], fullRect))
	{
		GSLog(@"geometry changed creating new browser");
		FileBrowser *newBrowser = [[FileBrowser alloc] initWithFrame:fullRect];
		[newBrowser setExtensions:_extensions];
		[newBrowser setPath:[[_browserArray lastObject] path]];
		[newBrowser setDelegate:_browserDelegate];
		[_browserArray removeLastObject];
		[_browserArray addObject: newBrowser];
		[newBrowser release];  // we still have it in the array, don't worry!
	}

	[_transView transition:([self isAnimationEnabled]? 2 : 0) toView:[_browserArray lastObject]];
	[super popNavigationItem];

	if (_textIsOnTop || _pixOnTop)
	{
		_textIsOnTop = NO;
		_pixOnTop = NO;

		if ([_browserDelegate respondsToSelector:@selector(textViewDidGoAway:)])
			 [_browserDelegate textViewDidGoAway:self];
	}
	else
	{
		GSLog(@"Popped to %@\n", [[_browserArray lastObject] path]);
	}
}

- (NSString *)topBrowserPath;
{
	return [[_browserArray lastObject] path];
}

- (void)pushNavigationItem:(UINavigationItem *)item
		   withBrowserPath:(NSString *)browserPath
{
	struct CGRect fullRect = [defaults fullScreenApplicationContentRect];
	FileBrowser *newBrowser = [[FileBrowser alloc] initWithFrame:fullRect];
	[newBrowser setExtensions:_extensions];
	[newBrowser setPath:browserPath];
	[newBrowser setDelegate:_browserDelegate];
	[_browserArray addObject:newBrowser];
	[_transView transition:([self isAnimationEnabled] ? 1 : 0) toView:newBrowser];
	[newBrowser release];  // we still have it in the array, don't worry!
	GSLog(@"Pushed %@\n", browserPath);
	[super pushNavigationItem:item];
}

- (void)pushNavigationItem:(UINavigationItem *)item
				  withView:(UIView *)view
{
	[self pushNavigationItem:item withView:view reverseTransition:NO];
}

- (void)pushNavigationItem:(UINavigationItem *)item
				  withView:(UIView *)view
		 reverseTransition:(BOOL)reversed
{
	BOOL thisIsText = [view respondsToSelector:@selector(loadBookWithPath:subchapter:)]; //ugh!
	// Here, cometh funky code, in anticipation of multiple text views.
	if (_textIsOnTop && thisIsText)
	{
		[self disableAnimation];
		[super popNavigationItem];
		[self enableAnimation];
	}

	_textIsOnTop = thisIsText;
	_pixOnTop = !thisIsText;
	GSLog(@"Pushed view\n");
	int transitionType = reversed ? 2 : 1;
	[_transView transition:([self isAnimationEnabled] ? transitionType : 0) 
					toView:view];
	GSLog(@"transitioned");
	[super pushNavigationItem:item];
	GSLog(@"called super");
}

- (FileBrowser *)topBrowser
{
	return [_browserArray lastObject];
}

- (void)shouldReloadTopBrowser:(NSNotification *)notification
{
	if (isTop) // let's only do this once.
	{
		[[_browserArray lastObject] reloadData];
	}
}
- (void)shouldReloadAllBrowsers:(NSNotification *)notification
{
	if (isTop)
	{
		NSEnumerator *enumerator = [_browserArray objectEnumerator];
		id i;
		while (nil != (i = [enumerator nextObject]))
			[i reloadData];
	}
}

- (void)hide:(BOOL)forced
{
	if (!hidden) {	
		if (isTop && forced) {
			[self hideTopNavBar];
		} else if (forced) {
			[self hideBotNavBar];
		}

		if (!forced) {
			if (isTop) {
				if ([defaults navbar]) [self hideTopNavBar];
			} else {
				if ([defaults toolbar]) [self hideBotNavBar];
			}
		}
	}
}

- (void)show
{
	if (hidden)
	{
		if (isTop)
			[self showTopNavBar:YES];
		else
			[self showBotNavBar];
		hidden = NO;
	}
}

- (void)toggle
{
	if (hidden)
		[self show];
	else
		[self hide:NO];
}

- (BOOL)hidden;
{
	return hidden;
}

- (void)showTopNavBar:(BOOL)withAnimation
{
	GSLog(@"showTopNavBar");
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	//CHANGED: The "68" comes from SummerBoard--if we just use 48, 
	// the top nav bar shows under the status bar.
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y - 68.0f, hardwareRect.size.width, 48.0f)];

	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0,-68);
	if (withAnimation)
	{
		[translate setStartTransform: trans];
		[translate setEndTransform: CGAffineTransformIdentity];
		[animator addAnimation:translate withDuration:.25 start:YES];
	}
	else
		[self setFrame: CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y, hardwareRect.size.width, 48.0f)];

}

- (void)hideTopNavBar
{
	GSLog(@"hideTopNavBar");
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y, hardwareRect.size.width, 48.0f)];

	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -68.0);
	[translate setStartTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[translate setEndTransform: trans];
	[animator addAnimation:translate withDuration:.25 start:YES];
	hidden = YES;
}

- (void)showBotNavBar
{
	GSLog(@"showBotNavBar");
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height, hardwareRect.size.width, 48.0f)];
	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, 48);
	[translate setStartTransform: trans];
	[translate setEndTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[animator addAnimation:translate withDuration:.25 start:YES];

}

- (void)hideBotNavBar
{
	GSLog(@"hideBotNavBar");
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height - 48.0f, hardwareRect.size.width, 48.0f)];
	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, 48);
	[translate setStartTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[translate setEndTransform: trans];
	[animator addAnimation:translate withDuration:.25 start:YES];
	hidden = YES;
}

- (void)setTransitionView:(UITransitionView *)view
{
	_transView = [view retain];
}

- (void)setExtensions:(NSArray *)extensions
{
	_extensions = [extensions retain];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[animator release];
	[translate release];
	if (nil != _transView)
		[_transView release];
	if (nil != _extensions)
		[_extensions release];
	if (nil != _browserDelegate)
		[_browserDelegate release];
	[_browserArray release];
	[defaults release];
	[super dealloc];
}

@end
