/* NSString additions for Books.app, by Zachary Brewster-Geisz

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
#import "NSString-BooksAppAdditions.h"

@implementation NSString (BooksAppAdditions)

- (BOOL)isReadableTextFilePath
{
  NSString *ext = [[self pathExtension] lowercaseString];
  
	return ([ext isEqualToString:@"txt"] || [ext isEqualToString:@"htm"] || [ext isEqualToString:@"html"] || [ext isEqualToString:@"fb2"] || [ext isEqualToString:@"zip"]); 

}

- (NSString *)HTMLsubstringToIndex:(unsigned)index
{
  BOOL junk;
  return [self HTMLsubstringToIndex:index didLoadAll:&junk];
}

- (NSString *)HTMLsubstringToIndex:(unsigned)index
			didLoadAll:(BOOL *)didLoadAll
  // Returns an HTML string containing "index" number of PRINTING characters.
  // Does not add any closing tags to the HTML, just stops.
{
  unsigned len = [self length];
  unsigned numPrintingChars = 0;
  unsigned i;
  BOOL insideMarkup = NO;
  if (len < index)
    {
      *didLoadAll = YES;
      return [self copy];
    }
  for (i = 0; i < len; i++)
    {
      unichar c = [self characterAtIndex:i];
	if (c == (unichar)'<')
	  insideMarkup = YES;
	else if (c == (unichar)'>')
	  insideMarkup = NO;
	else
	  {
	    if ((!insideMarkup) && (c != (unichar)'\n') && (c != (unichar)'\t'))
	      {
		numPrintingChars++;
		if (numPrintingChars >= index)
		  {
		    *didLoadAll = NO;
		    return [self substringToIndex:i];
		  }
	      }
	  }
    }
  // If we get here, then we've exhausted the string.
  *didLoadAll = YES;
  return [self copy];
}

- (NSRange)quotedRangePastIndex:(unsigned int)index
  // Returns a range of text between double-quotes, past an index.
  // Does not include the quotes in the range.
{
  unsigned int i, j;
  NSRange theRange;
  unsigned int len = [self length];

  for (i = index; i < len; i++)
    if ([self characterAtIndex:i] == (unichar)'"')
      {
	j = i+1;
	break;
      }
  
  for (i = j; i < len; i++)
    if ([self characterAtIndex:i] == (unichar)'"')
      {
	theRange = NSMakeRange(j, i - j);
	return theRange;
      }

  theRange = NSMakeRange(NSNotFound, 0);
  return theRange;
}


@end
