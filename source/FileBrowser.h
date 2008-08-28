/* FileBrowser.h, for Books.app, originally written by Stephan White,
	modifications by Zach Brewster-Geisz and others.

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
#import <UIKit/UITableCellRemoveControl.h>
#import <CoreGraphics/CGColor.h>
#import <CoreGraphics/CGColorSpace.h>
#import "BooksDefaultsController.h"
#import "FileTable.h"
#import "EBookImageView.h"

@interface FileBrowser : UIView 
{
	NSMutableArray *_extensions;
	NSMutableArray *_files;
	FileTable *_table;
	NSString *_path;
	int _rowCount;
	id _delegate;
	BooksDefaultsController *defaults;
}

int numberCompare(id, id, void *);

- (id)initWithFrame:(CGRect)rect;
- (NSString *)path;
- (void)setPath: (NSString *)path;
- (void)reloadData;
- (void)setDelegate:(id)delegate;
- (int)numberOfRowsInTable:(UITable *)table;
- (UITableCell *)table:(UITable *)table cellForRow:(int)row column:(UITableColumn *)col;
- (void)tableRowSelected:(NSNotification *)notification;
- (NSString *)selectedFile;
- (void)setExtensions:(NSArray *)extensions;
- (void)shouldReloadThisCell:(NSNotification *)aNotification;
- (void)reloadCellForFilename:(NSString *)thePath;
- (NSString *)fileBeforeFileNamed:(NSString *)thePath;
- (NSString *)fileAfterFileNamed:(NSString *)thePath;
- (void)shouldDeleteFileFromCell:(NSNotification *)aNotification;

@end
//informal protocol declaration for _delegate
@interface NSObject (FileBrowserDelegate)
- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file;
@end
