// EBookView, for Books.app by Zachary Brewster-Geisz
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
#import <UIKit/UIKit.h>
#import <UIKit/UITextViewLegacy.h>
//#import <UIKit/UITextTraitsClientProtocol.h>

#import <Celestial/AVSystemController.h>

//#import "UIKeyboardInputProtocol.h"
#import <UIKit/UIWebView.h>
#import <UIKit/UIViewTapInfo.h>
//#import <UIKit/NSString-UIStringDrawing.h>
#import <UIKit/UIView-Geometry.h>

#import "BooksDefaultsController.h" //sigh...
#import "NSString-BooksAppAdditions.h"
#import "HTMLFixer.h"
#import "BooksDefaultsController.h"
#import "ChapteredHTML.h"
#import "SimpleWebView.h"


@interface EBookView : UITextViewLegacy
{
  //  UIViewTapInfo *tapinfo;
  NSString                *path;
  float                   size;
  id                      _heartbeatDelegate;
  struct CGRect           lastVisibleRect;

  NSString		*_lastSearchString;
  
  @public
  ChapteredHTML	          *chapteredHTML;
  int                      subchapter;
  float					   _scrollRatio;
  
  int			_lastSearchChapter;
  int			_lastSearchPosition;
  struct CGRect           ebVisibleRect;
    
@protected
  BooksDefaultsController *defaults;

  AVSystemController *avs;
  float defaultVolume;
  float _autoScrollDelta;
  BOOL  _volumeButtonsScrollOneLine;
  
  NSString                *fullHTML;
	//what is the current orientation used in particular to find if the orientation should be changed when receiving a setOrientation message
	int _orient;
	CGAffineTransform _matrixprev;
}

- (id)initWithFrame:(struct CGRect)rect;
- (void)loadBookWithPath:(NSString *)thePath subchapter:(int) theSubchapter;
- (void)loadBookWithPath:(NSString *)thePath numCharacters:(int)numChars didLoadAll:(BOOL *)didLoadAll subchapter:(int) theSubchapter;
- (void)loadBookWithPath:(NSString *)thePath numCharacters:(int)numChars subchapter:(int) theSubchapter;
- (void)setCurrentPathWithoutLoading:(NSString *)thePath;
- (NSString *)HTMLFileWithoutImages:(NSString *)thePath;
- (NSString *)currentPath;
- (void)embiggenText;
- (void)ensmallenText;
- (void)handleDoubleTapEvent:(struct __GSEvent *)event;
- (void)handleSingleTapEvent:(struct __GSEvent *)event;
- (void)setHeartbeatDelegate:(id)delegate;
- (void)heartbeatCallback:(id)unused;
- (void)hideNavbars;
- (void)toggleNavbars;
- (void)pageDownWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar;
- (void)pageUpWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar;
- (int)textSize;
- (void)setTextSize:(int)newSize;
- (NSString *)HTMLFromTextFile:(NSString *)file;
- (NSString*)HTMLFromTextString:(NSMutableString *)originalText;

- (NSString *)HTMLFromFB2File:(NSString *)file;
- (NSString*)HTMLFromFB2String:(NSMutableString *)originalText;

- (void)invertText:(BOOL)b;
- (void)scrollSpeedDidChange:(NSNotification *)aNotification;

- (void) volumeChanged:(NSNotification *)notification;

- (int) getSubchapter;
- (int) getMaxSubchapter;
- (void) setSubchapter: (int) chapter;
- (BOOL) gotoNextSubchapter;
- (BOOL) gotoPreviousSubchapter;
-(void) redraw;
//-(void) setOrientation: (int) orientation animate:(bool)anime;
//- (void) fitRect;
//-(void) afterRotate: (NSTimer*) timer;
- (void) scrollDown: (float) delta;
- (BOOL) isAtTop;
- (BOOL) isAtBottom;
- (float)absolutePosition;
- (BOOL) find:(NSString *)string;
- (BOOL) findNext:(NSString *)string;
- (NSString *) lastSearchString;
- (SimpleWebView *) _webView;
- (CGRect) visibleRect;

@end
