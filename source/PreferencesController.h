// PreferencesView, for Books by Chris Born
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

#ifndef _PREFS_CONTROLLER_H
#define _PREFS_CONTROLLER_H

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UISegmentedControl.h>
#import <UIKit/_UISwitchSlider.h>
#import <UIKit/UITextLabel.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIActionSheet.h>
#import <UIKit/UIAnimator.h>
#import <UIKit/UIAnimation.h>
#import <UIKit/UITransformAnimation.h>
#import <UIKit/UIViewHeartbeat.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UITextViewLegacy.h> // For testing: remove

#import "common.h"
#import "BooksApp.h"
#import "BooksDefaultsController.h"
#import "EncodingPrefsController.h"
#import "FontChoiceController.h"

// #import "ColorPicker.h"
#import "ColorPrefsController.h"

enum PreferenceAnimationType{inAnim, outAnim, none} ;
@interface PreferencesController : NSObject {
	
	UINavigationBar				*navigationBar;
	UITextViewLegacy					*textView;
	BooksDefaultsController		*defaults;
	BooksApp					*controller;
	UIActionSheet				*alertSheet;
	UIPreferencesTable			*preferencesTable;
	UITransitionView                        *transitionView;
	
	UIView						*appView;
	UIView                      *preferencesView;
	UISegmentedControl 			*fontChoiceControl;
	UISegmentedControl 			*scrollSpeedControl;
	UISegmentedControl 			*flippedToolbarControl;
	UIPreferencesTextTableCell 	*fontChoicePreferenceCell;
	UIPreferencesTextTableCell 	*fontSizePreferenceCell;
	UIPreferencesTextTableCell 	*colorChoicePreferenceCell;
    UIPreferencesTextTableCell 	*scrollSpeedPreferenceCell;
	UIPreferencesControlTableCell *invertPreferenceCell;

// COLEL
	UIPreferencesControlTableCell *scrollKeepLinePreferenceCell;
	UIPreferencesControlTableCell *scrollByVolumeButtonsPreferenceCell;
	UIPreferencesControlTableCell *autoSplitPreferenceCell;
	UIPreferencesControlTableCell *autoScrollSpeedPreferenceCell;


	UIPreferencesControlTableCell *showToolbarPreferenceCell;
	UIPreferencesControlTableCell *showNavbarPreferenceCell;
	UIPreferencesControlTableCell *chapterButtonsPreferenceCell;
	UIPreferencesControlTableCell *pageButtonsPreferenceCell;	
	UIPreferencesControlTableCell *flippedToolbarPreferenceCell;
	UIPreferencesControlTableCell *invNavZonePreferenceCell;
	UIPreferencesControlTableCell *enlargeNavZonePreferenceCell;
	UIPreferencesControlTableCell *defaultEncodingPreferenceCell;
	UIPreferencesControlTableCell *smartConversionPreferenceCell;
	UIPreferencesControlTableCell *subchapteringPreferenceCell;
	UIPreferencesControlTableCell *renderTablesPreferenceCell;
	UIPreferencesTableCell *markCurrentBookAsNewCell;
	UIPreferencesTableCell *markAllBooksAsNewCell;
	UIPreferencesTableCell *toBeAnnouncedCell;
	
	struct CGRect contentRect;

	BOOL needsInAnimation, needsOutAnimation; // here's hoping.
	UIAnimator *animator;
	UITransformAnimation *translate;
	enum PreferenceAnimationType _curAnimation;
	EncodingPrefsController *encodingPrefs;
	FontChoiceController *fontChoicePrefs;
//	ColorPicker *m_colorPicker;
	ColorPrefsController *colorPrefs;

}

- (id)initWithAppController:(BooksApp *)appController;
- (void)buildPreferenceView;
- (void)showPreferences;
- (void)hidePreferences;
- (void)createPreferenceCells;
- (void)tableRowSelected:(NSNotification *)notification;
- (void)makeEncodingPrefsPane;
- (void)makeFontPrefsPane;
- (void)makeColorPrefsPane;

#define PREFS_NEEDS_ANIMATE @"prefsNeedsAnimateNotification"

- (void)checkForAnimation:(id)unused;
- (void)shouldTransitionBackToPrefsView:(NSNotification *)aNotification;

#define RIGHTHANDED 0
#define LEFTHANDED 1

#define GEORGIA 0
#define HELVETICA 1
#define TIMES 2

- (int)currentFontIndex;
- (NSString *)fontNameForIndex:(int)index;

@end

#endif
