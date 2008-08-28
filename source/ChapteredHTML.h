/* ChapteredHTML.h, by John A. Whitney for Books.app

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

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <openssl/sha.h>

#define MAX_CHAPTERS  2048

@interface ChapteredHTML: NSObject
{
	NSString       *_fullHTML;
	unsigned char   _fullHTMLHash[SHA_DIGEST_LENGTH];

	NSRange         _headerRange;
	NSRange         _bodyRange;
	NSRange         _trailerRange;
	NSRange         _chapterRange[MAX_CHAPTERS];
	int             _chapterCount;
	NSMutableArray	*_chapterTitles;

 @public
	NSMutableArray	*chapterTitles;

}

- (id) init;
- (void) dealloc;

- (void) setHTML: (NSString *) html;
- (int) chapterCount;
- (NSString *) getHTML;
- (NSString *) getChapterHTML: (int) chapter;
- (NSString *) cleanChapterTitle: (NSString *) title;

- (BOOL) loadFromFile: (NSString *) filename;
- (void) saveToFile: (NSString *) filename;
- (void) findSections;
- (void) findChapters;
- (float) convertChapterPosition: (float)position inChapter:(int)chapter;
@end
