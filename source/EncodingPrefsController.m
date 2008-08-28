// EncodingPrefsController.m, by Zachary Brewster-Geisz
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

#import "EncodingPrefsController.h"

@implementation EncodingPrefsController

-(EncodingPrefsController *)init
{
  if (self = [super init])
    {
      defaults = [BooksDefaultsController sharedBooksDefaultsController];
      NSLog(@"Creating encoding prefs!");
      struct CGRect rect = [defaults fullScreenApplicationContentRect];

      encodingTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0,0,rect.size.width, rect.size.height-48)];
      [encodingTable setDelegate:self];
      [encodingTable setDataSource:self];
      [encodingTable reloadData];

      NSMutableArray *tempEncodingNumbers = [[NSMutableArray alloc] initWithCapacity:75];
      NSMutableArray *tempEncodingNames = [[NSMutableArray alloc] initWithCapacity:75];
      const NSStringEncoding *encs = [NSString availableStringEncodings];
      while (*encs != 0)
	{
	  [tempEncodingNumbers addObject:[NSNumber numberWithUnsignedLong:*(encs++)]];
	}
	
      [tempEncodingNumbers sortUsingFunction:&unsignedCompare context:NULL];

      encodingNumbers = [[NSArray alloc] initWithArray:tempEncodingNumbers];
      [tempEncodingNumbers release];
      NSEnumerator *enumerator = [encodingNumbers objectEnumerator];
      NSNumber *i;
      while (nil != (i = [enumerator nextObject]))
	{
	  NSLog(@"\n   num: %u\nstring: %@", [i unsignedLongValue], [NSString localizedNameOfStringEncoding:[i unsignedIntValue]]);
	  [tempEncodingNames addObject:[NSString localizedNameOfStringEncoding:[i unsignedIntValue]]];
	}
      encodingNames = [[NSArray alloc] initWithArray:tempEncodingNames];
      [tempEncodingNames release];
    }
  NSLog(@"Created encoding prefs!");
  return self;
}

int unsignedCompare(id x, id y, void *context)
{
  unsigned int a = [x unsignedIntValue];
  unsigned int b = [y unsignedIntValue];
  if (a > b) return NSOrderedDescending;
  if (b > a) return NSOrderedAscending;
  if (b == a) return NSOrderedSame;
}

-(void)reloadData
{
  [encodingTable reloadData];
}

-(UITable *)table
{
  return encodingTable;
}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
  return 1;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
  return [encodingNumbers count]+1;
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
  return NSLocalizedString(@"window.encoding.subtitle",@"Available Encodings");
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
{
  return 48.0f;
}

-(void)tableRowSelected:(NSNotification *)aNotification
{
  int i = [encodingTable selectedRow] - 1; // subtract 1 for the group title
  UIPreferencesTableCell *cell = [encodingTable cellAtRow:i+1 column:0];
  NSString *title = [cell title];
  int rows = [encodingTable numberOfRows];
  int j;
  for (j = 0; j < rows; j++)
    [[encodingTable cellAtRow:j column:0] setChecked:NO];
  [cell setChecked:YES];

  if (i == 0)
    {
      [defaults setDefaultTextEncoding:AUTOMATIC_ENCODING];
    }
  else
    {
      [defaults setDefaultTextEncoding:[[encodingNumbers objectAtIndex:(i - 1)] unsignedIntValue]];
    }

  [cell setSelected:NO withFade:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:ENCODINGSELECTED object:title];
}

- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
  NSString *title;
  BOOL checked = NO;
  if (row == 0)
    {
      title = NSLocalizedString(@"preference.encoding.automatic",@"Automatic");
      checked = (AUTOMATIC_ENCODING == [defaults defaultTextEncoding]);
    }
  else
    {
      title = [encodingNames objectAtIndex:(row - 1)];
      checked = ([[encodingNumbers objectAtIndex:(row - 1)] unsignedIntValue]
		 == [defaults defaultTextEncoding]);
    }
  CGRect rect = [defaults fullScreenApplicationContentRect];
  UIPreferencesTableCell *theCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,rect.size.width,48)];
  [theCell setTitle:title];
  [theCell setChecked:checked];
  return [theCell autorelease];
}


-(void)dealloc
{
  [encodingNumbers release];
  [encodingNames release];
  [encodingTable release];
  [defaults release];
  [super dealloc];
}

@end
