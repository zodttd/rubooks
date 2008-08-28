/* ChapteredHTML.m, by John A. Whitney for Books.app

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
#import <stdio.h>
#import <string.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <unistd.h>
#import <openssl/sha.h>
#import <Foundation/NSDictionary.h>
#import "ChapteredHTML.h"
#import "BooksDefaultsController.h"


#define ARRAY_SIZE(x)   (sizeof (x) / sizeof ((x)[0]))

@implementation ChapteredHTML

- (id) init
{
	_fullHTML = nil;
        chapterTitles = nil;
}

- (void) dealloc
{
	[_fullHTML release];
	[chapterTitles release];
	[super dealloc];
}

- (void) setHTML: (NSString *) html
{
	NSMutableString *filename = [[NSMutableString alloc] initWithCapacity:80];
	int              index;

	[_fullHTML release];
	_fullHTML = [html retain];
	if (html == nil)
	{
		_fullHTML = nil;

		_headerRange.location   = 0;
		_headerRange.length     = 0;
		_bodyRange.location     = 0;
		_bodyRange.length       = 0;
		_trailerRange.location  = 0;
		_trailerRange.length    = 0;

		return;
	}

	SHA1 ((const unsigned char *) [_fullHTML UTF8String],
	      (unsigned long) [_fullHTML length],
	      _fullHTMLHash);

		  filename = [[NSMutableString alloc] initWithString:[NSHomeDirectory() stringByAppendingString:@"/Library/Caches/ruBooks/"]];
	for (index = 0; index < sizeof (_fullHTMLHash); index++)
		[filename appendFormat:@"%02x", _fullHTMLHash[index]];

	[filename appendString:@".plist"];

	if (chapterTitles == nil) {chapterTitles = [[NSMutableArray alloc] init];}
	[chapterTitles removeAllObjects];


	if ([self loadFromFile:filename] == NO)
	{
	NSLog(@"Calling findSections");
		[self findSections];
	NSLog(@"Calling findChapters");	
		[self findChapters];
	NSLog(@"Calling saveToFile");	
		[self saveToFile:filename];
	}
	NSLog(@"Releasing filename");
	[filename release];
	return;
}


- (int) chapterCount
{
	return _chapterCount;
}

- (NSString *) getHTML
{
	return _fullHTML;
}

- (NSString *) getChapterHTML: (int) chapter
{
	NSMutableString *string;
	
	if (chapter >= _chapterCount)
	{
		return @"<html><body></body></html>";
	}

	string = [[NSMutableString alloc] initWithCapacity:_headerRange.length +
	                                                   _chapterRange[chapter].length +
	                                                   _trailerRange.length +
	                                                   8];
	[string setString:[_fullHTML substringWithRange:_headerRange]];
	[string appendString:[_fullHTML substringWithRange:_chapterRange[chapter]]];
	[string appendString:@"<br><br>"];
	[string appendString:[_fullHTML substringWithRange:_trailerRange]];

FILE *file = fopen ("/tmp/book.html", "w");
fprintf (file, "%s\n", [string UTF8String]);
fclose (file);
	return [string autorelease];
}

- (BOOL) loadFromFile: (NSString *) filename
{
	NSDictionary *dictionary;
	NSDictionary *chapterRanges;
	NSDictionary *titles;
	NSNumber     *start;
	NSNumber     *length;
	NSNumber     *number;
	NSString     *title;
	int           index;

	dictionary = [NSDictionary dictionaryWithContentsOfFile:filename];
	if (dictionary == nil)
		return NO;

	/* Header Range */
	start  = [dictionary objectForKey:@"headerStart"];
	length = [dictionary objectForKey:@"headerLength"];
	if (!start || !length)
		return NO;

	_headerRange.location = [start unsignedIntValue];
	_headerRange.length   = [length unsignedIntValue];

	/* Body Range */
	start  = [dictionary objectForKey:@"bodyStart"];
	length = [dictionary objectForKey:@"bodyLength"];
	if (!start || !length)
		return NO;

	_bodyRange.location = [start unsignedIntValue];
	_bodyRange.length   = [length unsignedIntValue];

	/* Trailer Range */
	start  = [dictionary objectForKey:@"trailerStart"];
	length = [dictionary objectForKey:@"trailerLength"];
	if (!start || !length)
		return NO;

	_trailerRange.location = [start unsignedIntValue];
	_trailerRange.length   = [length unsignedIntValue];

	/* Chapter Count */
	number = [dictionary objectForKey:@"chapterCount"];
	if (number == nil)
		return NO;

	_chapterCount = [number unsignedIntValue];

	chapterRanges 	= [dictionary objectForKey:@"chapterRanges"];

	if ((chapterRanges == nil) || ([chapterRanges count] != _chapterCount))
		return NO;

	for (index = 0; index < [chapterRanges count]; index++)
	{
		NSString     *chapterNum = [NSString stringWithFormat:@"%d", index];
		NSDictionary *chapter    = [chapterRanges objectForKey:chapterNum];

		if (chapter == nil)
			return NO;

		/* Trailer Range */
		start  = [chapter objectForKey:@"start"];
		length = [chapter objectForKey:@"length"];

		if (!start || !length)
			return NO;

		_chapterRange[index].location      = [start unsignedIntValue];
		_chapterRange[index].length        = [length unsignedIntValue];
	}

	titles = [dictionary objectForKey:@"chapterTitles"];
	for (index = 0; index < [titles count]; index++)
	{
		NSString     *chapterNum = [NSString stringWithFormat:@"%d", index];
		NSString *title = [titles objectForKey:chapterNum];
      		[chapterTitles addObject:title];
	}


	return YES;
}

- (void) saveToFile: (NSString *) filename
{
NSLog(@"Entering saveToFile");
	int                  index;
	NSString            *path;
	NSMutableDictionary *dictionary;
	NSMutableDictionary *chapterRanges;
	NSMutableDictionary *titles;
	NSMutableDictionary *chapter;

	for (index = [filename length] - 1; index > 1; index--)
		if ([filename characterAtIndex:index] == (unichar) '/')
			break;

//	NSLog(@"1");
	path = [filename substringToIndex:index];
	mkdir ([path cString], 0755);
//	NSLog(@"2");
	dictionary    = [[NSMutableDictionary alloc] initWithCapacity:10];
	chapterRanges = [[NSMutableDictionary alloc] initWithCapacity:10];
	titles = [[NSMutableDictionary alloc] initWithCapacity:10];

	[dictionary setObject:[NSNumber numberWithUnsignedInt:_headerRange.location]
	               forKey:@"headerStart"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_headerRange.length]
	               forKey:@"headerLength"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_bodyRange.location]
	               forKey:@"bodyStart"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_bodyRange.length]
	               forKey:@"bodyLength"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_trailerRange.location]
	               forKey:@"trailerStart"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_trailerRange.length]
	               forKey:@"trailerLength"];
	[dictionary setObject:[NSNumber numberWithUnsignedInt:_chapterCount]
	               forKey:@"chapterCount"];
//	NSLog(@"3");			   
	for (index = 0; index < _chapterCount; index++)
	{
//	NSLog(@"Setting dictionary for chapter %d",index);
		NSRange *range = &_chapterRange[index];

		chapter = [[NSMutableDictionary alloc] initWithCapacity:2];
		[chapter setObject:[NSNumber numberWithUnsignedInt:range->location]
		            forKey:@"start"];
		[chapter setObject:[NSNumber numberWithUnsignedInt:range->length]
		            forKey:@"length"];
		[chapterRanges setObject:chapter
		                  forKey:[NSString stringWithFormat:@"%d", index]];
		[chapter release];
	}
	NSLog(@"Formating titles");
	for (index = 0; index < _chapterCount; index++) {
		if (index < [chapterTitles count]) [titles setObject:[chapterTitles objectAtIndex:index] forKey:[NSString stringWithFormat:@"%d", index]];
        }

	[dictionary setObject:chapterRanges forKey:@"chapterRanges"];
	[dictionary setObject:titles forKey:@"chapterTitles"];
	[chapterRanges release];
	[titles release];
	 
	NSLog(@"Saving dictionary start");
    if ([dictionary writeToFile:filename atomically:NO] == YES)
    	NSLog (@"Wrote cachefile: %s", [filename cString]);
    else
    	NSLog (@"Unable to write cachefile: %s", [filename cString]);
	NSLog(@"Saving dictionary end");
	[dictionary release];
	NSLog(@"Leaving saveToFile");
}


- (void) findSections
{
	NSString *bodyIdentifier    = @"<body";
	NSString *trailerIdentifier = @"</body>";
		_headerRange.location   = 0;
		_headerRange.length     = 0;
		_bodyRange.location     = _headerRange.location+_headerRange.length; // 0
		_bodyRange.length       = [_fullHTML length]; // whole text
		_trailerRange.location  = _bodyRange.location+_bodyRange.length; // beyound the text
		_trailerRange.length    = [_fullHTML length]-_trailerRange.location; // 0
		
	NSRange r1 = [_fullHTML rangeOfString:bodyIdentifier options:NSCaseInsensitiveSearch];
	NSRange r2 = [_fullHTML rangeOfString:trailerIdentifier options:(NSCaseInsensitiveSearch | NSBackwardsSearch)];

	if (r1.location != NSNotFound) {
	  _bodyRange.location = r1.location;
	  _headerRange.length = r1.location;
	  _bodyRange.length = _bodyRange.length - r1.location;
	} 

	if (r2.location != NSNotFound) {
	  _trailerRange.location = (r2.location+r2.length);
	  _trailerRange.length = [_fullHTML length]-_trailerRange.location;
	  _bodyRange.length = _bodyRange.length - _trailerRange.length;
	} 

// TODO: SPECIAL CASE OF </BODY>... <BODY>
//	[self findSections2];
}

- (void) findChapters
{
NSLog(@"Entering findChapters");
	int      lastChapterOffset = _bodyRange.location;
	int      index;

	if (_bodyRange.length == 0)
	{
		_chapterRange[0].location = 0;
		_chapterRange[0].length   = [_fullHTML length];
		_chapterCount = 1;
		return;
	}

	index = 0;
	_chapterCount = 0;
	_chapterRange[0].location = _bodyRange.location;

NSLog(@"Starting finding chapters.. ");
	NSRange range = NSMakeRange(_bodyRange.location, _bodyRange.length);

        while ((_chapterCount < (MAX_CHAPTERS - 2)) && (index < (_bodyRange.location+_bodyRange.length))) {
		NSRange headerRange = [_fullHTML rangeOfString:@"<section>" options:nil range:range];
		if (headerRange.location == NSNotFound) break;
		index = headerRange.location;
                int offset = headerRange.location;
		_chapterCount += 1;
// NSLog(@"Found chapter # %d at %d",_chapterCount, index);
		_chapterRange[_chapterCount].location = offset;
		_chapterRange[_chapterCount - 1].length = _chapterRange[_chapterCount].location - _chapterRange[_chapterCount - 1].location;
		lastChapterOffset = offset;

// FIND TITLE FOR PREVIOUS CHAPTER
	NSMutableString *chapterText =	[NSMutableString stringWithString:[_fullHTML substringWithRange:_chapterRange[_chapterCount-1]]];
	NSRange range1 = [chapterText rangeOfString: @"<h2>" options: NSCaseInsensitiveSearch];
	NSRange range2 = [chapterText rangeOfString: @"</h2>" options: NSCaseInsensitiveSearch];
	NSRange range3 = NSMakeRange (range1.location+range1.length,range2.location-(range1.location+range1.length));

	if ((range1.location != NSNotFound) && (range2.location != NSNotFound) && (range3.length > 0)) {
		NSMutableString *chapterName =	[NSMutableString stringWithString:[chapterText substringWithRange:range3]];
		[chapterName setString:[self cleanChapterTitle:chapterName]];
	    [chapterTitles addObject:chapterName];
//		[chapterName release];
	} else {
		[chapterTitles addObject:[NSString stringWithFormat:@"** %d **",_chapterCount]]; // a number?
	}
//	[chapterText release];

		range.location = headerRange.location+headerRange.length;
		range.length = _bodyRange.length - range.location;
// NSLog(@"Completed chapter # %d",_chapterCount);	
	}


// FORCE SPLIT BY SIZE
// NB: IMAGES

          int block_size = 20000;
          int n_blocks = range.length / block_size; // MAX_CHAPTERS - 2
	  int min_size_to_split;

	  // AUTO SPLIT START *******************************
        if (([[BooksDefaultsController sharedBooksDefaultsController] autoSplit]) && (_bodyRange.location+_bodyRange.length > block_size)) {
        if (_chapterCount <= 1) {
				NSLog(@"Autosplit start");
	  _chapterCount = 0;
//	  _chapterRange[0].location = _bodyRange.location;
	  _chapterRange[0].location = 0;
	  _chapterRange[0].length = 0;
	  index = 0;
	  [chapterTitles removeAllObjects];
    	    while (index < (_bodyRange.location+_bodyRange.length-block_size)) {
    	        index = block_size*(_chapterCount+1);
 	        	range.location = index;
    	        	range.length = _bodyRange.location + _bodyRange.length - range.location;
			NSLog(@"A");
			NSLog(@"bodyRange: %d, %d",_bodyRange.location,_bodyRange.length);			
			NSLog(@"range: %d, %d",range.location,range.length);
 			NSRange headerRange = [_fullHTML rangeOfString:@"<p" options:nil range:range];
			NSLog(@"B");			
 			if (headerRange.location != NSNotFound) 
				index = headerRange.location;
// TODO: IF NOT FOUND SEARCH FOR ". " OR "./n" OR ".<" OR " ".
    	        int offset = index;
		_chapterCount += 1;
		_chapterRange[_chapterCount].location = offset;
		_chapterRange[_chapterCount - 1].length = _chapterRange[_chapterCount].location - _chapterRange[_chapterCount - 1].location;
		lastChapterOffset = offset;
		[chapterTitles addObject:[NSString stringWithFormat:@"** %d **",_chapterCount]]; 
            }
			NSLog(@"Autosplit end");
        }}
		
		// AUTO SPLIT END  *******************************
NSLog(@"Last chapter start");	
	_chapterRange[_chapterCount].length = _trailerRange.location - _chapterRange[_chapterCount].location;
	if (_chapterRange[_chapterCount].length > 0) {
		_chapterCount += 1;
		NSMutableString *chapterText =	[NSMutableString stringWithString:[_fullHTML substringWithRange:_chapterRange[_chapterCount-1]]];
		NSRange range1 = [chapterText rangeOfString: @"<h2>" options: NSCaseInsensitiveSearch];
		NSRange range2 = [chapterText rangeOfString: @"</h2>" options: NSCaseInsensitiveSearch];
		NSRange range3 = NSMakeRange (range1.location+range1.length,range2.location-(range1.location+range1.length));
		if ((range1.location != NSNotFound) && (range2.location != NSNotFound) && (range2.location>(range1.location+range1.length))) {
			NSLog(@"Range: %d, %d",range3.location,range3.length);
			NSMutableString *chapterName =	[NSMutableString stringWithString:[chapterText substringWithRange:range3]];
			[chapterName setString:[self cleanChapterTitle:chapterName]];
			[chapterTitles addObject:chapterName];
//		[chapterName release];	
		}  else {
			[chapterTitles addObject:[NSString stringWithFormat:@"** %d **",_chapterCount]];
}}
		
//	[chapterText release];
NSLog(@"Last chapter end");	

NSLog(@"Leaving findChapters");
	return;
}

- (NSString *) cleanChapterTitle: (NSString *) title {
	NSMutableString *chapterName =	[NSMutableString stringWithString:title];
	[chapterName replaceOccurrencesOfString:@"<strong>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"</strong>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"<h2>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"</h2>" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"<i>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"</i>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"<p align=justify>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"</p>" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
	[chapterName replaceOccurrencesOfString:@"  " withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [chapterName length])];
        return chapterName;
}

- (float) convertChapterPosition: (float)position inChapter:(int)chapter {
 if (_bodyRange.length == 0) return 0.0f;
 return (((position * _chapterRange[chapter].length)+_chapterRange[chapter].location) - _bodyRange.location) / _bodyRange.length;
}

@end
