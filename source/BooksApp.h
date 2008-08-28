// BooksApp, (c) 2007 by Zachary Brewster-Geisz

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
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
//#import <UIKit/CDStructures.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UITextViewLegacy.h>
#import <UIKit/UIView.h>
#import <UIKit/UIKeyboard.h>
//#import <UIKit/UIWebView.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UINavigationItem.h>
#import <UIKit/UINavigationButton.h>
#import <UIKit/UIFontChooser.h>
#import <UIKit/UIProgressIndicator.h>
#import <UIKit/UIOldSliderControl.h>
#import <UIKit/UIAlphaAnimation.h>
#import "EBookView.h"
#import "EBookImageView.h"
#import "FileBrowser.h"
#import "BooksDefaultsController.h"
#import "HideableNavBar.h"
#import "common.h"
#import "TOC.h"

@interface AdView : UIView
{
 	UIWebDocumentView *web;
 	UIScroller *scroller;
  UIWebDocumentView *mCoreWebView;
 	WebFrame *mFrame;
 	UITransitionView *mTransView;
 	NSNotificationCenter *nc;
 	NSString *_URL;
  CGRect fileframe;
}

- (id)initWithFrame:(struct CGRect)frame;
- (void)loadURL: (NSString*)URL;
- (void)loadRequest: (id)param;
- (void)loadWebView;
- (void)closeWebView;

@end

enum PreferenceAnimationType;
@class PreferencesController;
@class TOCController;
@class SafariController;

@interface BooksApp : UIApplication {
@public
        EBookView   *textView;
@protected
	UIWindow 	*window;
	UIView      *mainView;
	HideableNavBar  *navBar, *bottomNavBar;
	UIOldSliderControl *scrollerSlider;
	UITextLabel *statusBar;
	UITransitionView *transitionView;
	UIActionSheet *alertSheet;
	EBookImageView *imageView;
	NSString    *path;
	NSError     *error;
	BOOL        bookHasChapters;
	BOOL        readingText;
	BOOL        doneLaunching;
	BOOL        transitionHasBeenCalled;
	BOOL        textViewNeedsFullText;
	BOOL        navbarsAreOn;
	BOOL		textInverted;
	BOOL        imageSplashed;
	BOOL        rotate90;
	float       size;
	float	    _scrollRatio;
	int			_SBAutoLockTime;
	int			_SBAutoDimTime;
	

        int         _autoScrollTimer;

	BooksDefaultsController *defaults;
	UINavigationButton *minusButton;
	UINavigationButton *plusButton;
	UINavigationButton *invertButton;
	UINavigationButton *rotateButton;
	UINavigationButton *prefsButton;
	UINavigationButton *tocButton;
	UINavigationButton *downButton;
	UINavigationButton *upButton;
	UINavigationButton *rightButton;
	UINavigationButton *leftButton;
	UINavigationButton *autoScrollButton;
	UINavigationButton *searchButton; 

	
	UIProgressIndicator *progressIndicator;

	UIImage *buttonImg;
	NSString *imgPath;

	UIAnimator *animator;
	UIAlphaAnimation *alpha;
  SafariController *sc;
  AdView*  adView;
}
- (void)textViewDidGoAway:(id)sender;
- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file;

- (void) chapJump: (int) chap;


- (void)heartbeatCallback:(id)unused;
- (void)hideNavbars;
- (void)toggleNavbars;
- (void)showStatusBar;
- (void)updateStatusBar;
- (void) setStatusBarProgress:(int)value;
- (void)showSlider:(BOOL)withAnimation;
- (void)hideSlider;
- (void)handleSlider:(id)sender;
- (void)embiggenText:(UINavigationButton *)button;
- (void)ensmallenText:(UINavigationButton *)button;
- (void)invertText:(UINavigationButton *)button;
- (void)setTextInverted:(BOOL)button;
- (void)setupNavbar;
- (void)setupToolbar;
- (void)updateToolbar:(NSNotification *)notification;
- (void)updateNavbar;
- (UINavigationButton *)toolbarButtonWithName:(NSString *)name rect:(struct CGRect)rect selector:(SEL)selector flipped:(BOOL)flipped;
- (UIImage *)navBarImage:(NSString *)name flipped:(BOOL)flipped;
- (void)textViewDidGoAway:(id)sender;
- (void)showPrefs:(UINavigationButton *)button;
- (UIWindow *)appsMainWindow;
- (void)refreshTextViewFromDefaults;
- (void)refreshTextViewFromDefaultsToolbarsOnly:(BOOL)toolbarsOnly;
- (void)removeChapterIndexes;
- (void)toggleStatusBarColor;
- (NSString *)currentBrowserPath;
- (void)cleanUpBeforeQuit;
- (void)rotateApp;
- (void)rotateButtonCallback:(UINavigationButton*) button;
- (void) applicationDidFinishLaunching: (id) unused;
- (void) preferenceAnimationDidFinish;
- (void) returnFromSafari;
- (void) disableLock;
- (void) restoreLock;
- (SafariController *) getSafariController;
 
@end
