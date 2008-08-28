/// BooksDefaultsController.h
/// by Zachary Brewster-Geisz, (c) 2007
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
#import <UIKit/UIKit.h>
#import <UIKit/UIActionSheet.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "common.h"

@interface BooksDefaultsController : NSObject
{
  BOOL            _readingText;
  NSString       *_fileBeingRead;
  BOOL            _inverted;
  BOOL            _scrollKeepLine;
  BOOL            _scrollByVolumeButtons;
  BOOL            _autoSplit;
  int             _autoScrollSpeed;

  BOOL            _rotate90;
  NSString       *_browserPath;
  NSUserDefaults *_defaults;
  BOOL            _toolbarShouldUpdate;
  BOOL            _NeedRotate;
  BOOL            _inverseNavZone;
  
  BOOL	          _autoScrollEnabled;
  CGColorRef	  _textColorDay;
  CGColorRef	  _backgroundColorDay;
  CGColorRef	  _textColorNight;
  CGColorRef	  _backgroundColorNight;
  CGColorRef	  _color[4];
}

/*
 * Obsolete keys, used for conversion to newer preferences formats.
 */
#define LASTSUBCHAPTERKEY      @"lastSubchapterKey"
#define LASTSCROLLPOINTKEY     @"lastScrollPointKey"
#define PERSISTENCEKEY         @"persistenceDictionaryKey"
#define SUBCHAPTERKEY          @"subchapterDictionaryKey"
#define	AUTOHIDE               @"autohideKey"

/*
 * Application stored data
 */
#define READINGTEXTKEY         @"readingTextKey"
#define FILEBEINGREADKEY       @"fileBeingReadKey"
#define BROWSERFILESKEY        @"browserPathsKey"

/*
 * New per-book data storage
 */
#define FILESPECIFICDATAKEY    @"fileSpecificData"
#define FILESUBCHAPTERENABLE   @"enableSubchaptering"
#define FILECURRENTSUBCHAPTER  @"currentSubchapter"
#define FILELOCPERSUBCHAPTER   @"locationPerSubchapter"

/*
 * User-specified preferences
 */
#define TEXTSIZEKEY            @"textSizeKey"
#define ISINVERTEDKEY          @"isInvertedKey"
#define DOSCROLLKEEPLINEKEY    @"doScrollKeepLine"
#define DOSCROLLBYVOLUMEBUTTONS @"doScrollByVolumeButtons"
#define DOAUTOSPLITKEY         @"doAutoSplit"
#define AUTOSCROLLSPEEDKEY     @"autoScrollSpeedKey"
#define TEXTFONTKEY            @"textFontKey"
#define NAVBAR                 @"navbarKey"
#define TOOLBAR                @"toolbarKey"
#define FLIPTOOLBAR            @"flipToolbarKey"
#define CHAPTERNAV             @"chapterNavKey"
#define PAGENAV                @"pageNavKey"

#define TEXTENCODINGKEY        @"textEncodingKey"
#define SMARTCONVERSIONKEY     @"smartConversionKey"
#define RENDERTABLESKEY        @"renderTablesKey"
#define ENABLESUBCHAPTERINGKEY @"enableSubchapteringKey"
#define SCROLLSPEEDINDEXKEY    @"scrollSpeedIndexKey"
#define ISROTATE90KEY          @"isRotate90Key"
#define INVERSENAVZONEKEY      @"inverseNavZoneKey"
#define ENLARGENAVZONEKEY      @"enlargeNavZoneKey"

// TODO: STORE AS AN OBJECT
#define COLOR0RKEY @"color0rkey"
#define COLOR0GKEY @"color0gkey"
#define COLOR0BKEY @"color0bkey"
#define COLOR1RKEY @"color1rkey"
#define COLOR1GKEY @"color1gkey"
#define COLOR1BKEY @"color1bkey"
#define COLOR2RKEY @"color2rkey"
#define COLOR2GKEY @"color2gkey"
#define COLOR2BKEY @"color2bkey"

#define COLORKEY @"colorkey"

- (id) init;
- (void) updateOldPreferences;

- (NSString *)fileBeingRead;
- (void)setFileBeingRead:(NSString *)file;
- (int)textSize;
- (void)setTextSize:(int)size;
- (BOOL)inverted;
- (void)setInverted:(BOOL)isInverted;

- (BOOL)scrollKeepLine;
- (BOOL)scrollByVolumeButtons;
- (BOOL)autoSplit;
- (int)autoScrollSpeed;

- (void)setScrollKeepLine:(BOOL)doScrollKeepLine;
- (void)setScrollByVolumeButtons:(BOOL)doScrollByVolumeButtons;
- (void)setAutoSplit:(BOOL)doAutoSplit;
- (void)setAutoScrollSpeed:(int)autoScrollSpeed;

- (BOOL)subchapteringEnabled;
- (void)setSubchapteringEnabled:(BOOL)isEnabled;
- (BOOL)readingText;
- (void)setReadingText:(BOOL)readingText;
- (NSString *)lastBrowserPath;
- (void)setLastBrowserPath:(NSString *)browserPath;
- (BOOL)navbar;
- (void)setNavbar:(BOOL)isNavbar;
- (BOOL)toolbar;
- (void)setToolbar:(BOOL)isToolbar;
- (BOOL)flipped;
- (void)setFlipped:(BOOL)isFlipped;
- (BOOL)inverseNavZone;
- (void)setInverseNavZone:(BOOL)Inversed;
- (BOOL)enlargeNavZone;
- (void)setEnlargeNavZone:(BOOL)Enlarge;
- (BOOL)isRotate90;
- (void)setRotate90:(BOOL)isRotate90;
- (NSString *)textFont;
- (void)setTextFont:(NSString *)font;
- (BOOL)chapternav;
- (void)setChapternav:(BOOL)isChpaternav;
- (BOOL)pagenav;
- (void)setPagenav:(BOOL)isPagenav;
- (unsigned int)defaultTextEncoding;
- (void)setDefaultTextEncoding:(unsigned int)enc;
- (BOOL)smartConversion;
- (void)setSmartConversion:(BOOL)sc;
- (BOOL)renderTables;
- (void)setRenderTables:(BOOL)rt;
- (int)scrollSpeedIndex;
- (void)setScrollSpeedIndex:(int)index;

- (void)setAutoScrollEnabled:(BOOL)au;
- (BOOL)autoScrollEnabled;


// - (void)setColor:(CGColorRef)color index:(int)index;
// - (CGColorRef)color:(int)index;
- (void)setColor:(float)color index:(int)index component:(int)component;
- (float)color:(int)index component:(int)component;


- (BOOL)synchronize;

- (BOOL) dataExistsForFile: (NSString *) filename;
- (BOOL) subchapteringEnabledForFile: (NSString *) filename;
- (void) setSubchapteringEnabled: (BOOL) enabled
                         forFile: (NSString *) filename;
- (unsigned int) lastSubchapterForFile: (NSString *) filename;
- (void) setLastSubchapter: (unsigned int) subchapter
                   forFile: (NSString *) filename;
- (unsigned int) lastScrollPointForFile: (NSString *) filename
                           inSubchapter: (unsigned int) subchapter;
- (void) setLastScrollPoint: (unsigned int) scrollPoint
              forSubchapter: (unsigned int) subchapter
                    forFile: (NSString *) filename;
- (void) removePerFileDataForFile: (NSString *) file;
- (void) removePerFileDataForDirectory: (NSString *) directory;
- (void) removePerFileData;
/**
 * retrieve the rectangle for the application taking into account the rotation preference.
 * This will always have 0,0 as the origin (contrarily to the case of the UIHardware version).
 *
 */
- (struct CGRect) fullScreenApplicationContentRect;
/**
 * retrieve the apps default location for EBooks.
 * Note that this is not the location stored in prefs but the default.  This is needed as opposed to the previous
 * approach of the macro EBOOK_PATH as between 1.1.2 and 1.1.3 there is a change in user and therefore location for this
 * default path
 *
 */
+ (NSString*) defaultEBookPath;
/**
 * singleton factory method
 */
+ (BooksDefaultsController*)sharedBooksDefaultsController;
/**
 * delegate method for the alert sheet.
 */
- (void)alertSheet:(UIActionSheet *)sheet buttonClicked:(int)button; 
@end

