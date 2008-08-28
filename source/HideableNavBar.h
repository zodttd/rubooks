// HideableNavBar, (c) 2007 by Zachary Brewster-Geisz
// Creates a navBar that disappears when you ask it to.
// Also features integration with FileBrowser class.

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



#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITransformAnimation.h>
#import <UIKit/UIAnimator.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UINavigationItem.h>
#import "FileBrowser.h"
#import "BooksDefaultsController.h"
#import "common.h"

@interface HideableNavBar : UINavigationBar
{
  BOOL hidden;
  BOOL isTop;
  BOOL _textIsOnTop;
  BOOL _pixOnTop;
  UITransformAnimation *translate;
  UIAnimator *animator;
  UITransitionView *_transView;
  NSMutableArray *_browserArray;
  NSArray *_extensions;
  BooksDefaultsController	*defaults;
  id _browserDelegate;
}

- (void)hideTopNavBar;
- (void)showTopNavBar:(BOOL)withAnimation;
- (void)hideBotNavBar;
- (void)showBotNavBar;

- (HideableNavBar *)initWithFrame:(struct CGRect)rect isTop:(BOOL)top;
- (void)setTransitionView:(UITransitionView *)transView;

- (void)popNavigationItem;

- (void)pushNavigationItem:(UINavigationItem *)item withBrowserPath:(NSString *)browserPath;
- (void)pushNavigationItem:(UINavigationItem *)item withView:(UIView *)view;
- (void)pushNavigationItem:(UINavigationItem *)item withView:(UIView *)view reverseTransition:(BOOL)reversed;
- (void)hide:(BOOL)forced;
- (void)show;
- (void)toggle;
- (BOOL)hidden;
- (void)setExtensions:(NSArray *)extensions;
- (void)setBrowserDelegate:(id)bDelegate;
- (FileBrowser *)topBrowser;
- (void)shouldReloadTopBrowser:(NSNotification *)notification;
- (void)shouldReloadAllBrowsers:(NSNotification *)notification;
- (NSString *)topBrowserPath;

@end
//informal protocol declaration for _browserDelegate
@interface NSObject (BrowserDelegate)

- (void)textViewDidGoAway:(id)sender;

@end
