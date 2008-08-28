#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <Celestial/AVSystemController.h>
#import <CoreGraphics/CGFont.h>

#import "EBookView.h"
#import "BooksDefaultsController.h"
#import "palm/palmconvert.h"
#import "ChapteredHTML.h"

@interface NSObject (HeartbeatDelegate)
	- (void)heartbeatCallback:(id)ignored;
	@end


@implementation EBookView
	- (id)initWithFrame:(struct CGRect)rect
{
	CGRect lFrame = rect;
	if (rect.size.width < rect.size.height) {	lFrame.size.width = rect.size.height; }
	[super initWithFrame:lFrame];
	[super setFrame:rect];
  ebVisibleRect = lFrame;	
	//  tapinfo = [[UIViewTapInfo alloc] initWithDelegate:self view:self];
	size = 16.0f;
	fullHTML      = nil;
	chapteredHTML = [[ChapteredHTML alloc] init];
	subchapter    = 0;
	defaults      = [BooksDefaultsController sharedBooksDefaultsController]; 
	[self setAdjustForContentSizeChange:YES];
	[self setEditable:NO];
	[self setTextSize:size];
	//[self setFont:@"TimesNewRoman"];
	[self setAllowsRubberBanding:YES];
	[self setBottomBufferHeight:0.0f];
//	[self scrollToMakeCaretVisible:NO];
	[self scrollToMakeCaretVisible:YES];
	[self setScrollDecelerationFactor:0.996f];
	[self setTapDelegate:self];
	[self setScrollerIndicatorsPinToContent:NO];
	lastVisibleRect = [self visibleRect];
	[self scrollSpeedDidChange:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollSpeedDidChange:) name:CHANGEDSCROLLSPEED object:nil];

  avs = [AVSystemController sharedAVSystemController];
  [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object: avs];
  NSString *name;
  [avs getVolume:&defaultVolume forCategory: @"Audio/Video"];
  if (defaultVolume == 1.0f) { defaultVolume = 1.0f - 0.063f;}
  if (defaultVolume < 0.063f) { defaultVolume = 0.063f;}

   NSDictionary *dictionary;
   dictionary = [NSDictionary dictionaryWithContentsOfFile:@"/Applications/ruBooks.app/rubooks_additional_settings.plist"];
   if (dictionary) { _volumeButtonsScrollOneLine = [dictionary boolForKey:@"VolumeButtonsScrollOneLine"]; }
	return self;
}

- (void)heartbeatCallback:(id)unused
{
	if ((![self isScrolling]) && (![self isDecelerating]))	lastVisibleRect = [self visibleRect];
	if (_heartbeatDelegate != nil) {
		if ([_heartbeatDelegate respondsToSelector:@selector(heartbeatCallback:)]) {
			 [_heartbeatDelegate heartbeatCallback:self];
		} else {
			[NSException raise:NSInternalInconsistencyException	format:@"Delegate doesn't respond to selector"];
    }
  }
}

- (void)setHeartbeatDelegate:(id)delegate
{
	_heartbeatDelegate = delegate;
	[self startHeartbeat:@selector(heartbeatCallback:) inRunLoopMode:nil];

}

- (void)hideNavbars
{
	if (_heartbeatDelegate != nil) {
		if ([_heartbeatDelegate respondsToSelector:@selector(hideNavbars)]) {
			[_heartbeatDelegate hideNavbars];
		} else {
			[NSException raise:NSInternalInconsistencyException	format:@"Delegate doesn't respond to selector"];
}}}

/*
   - (void)drawRect:(struct CGRect)rect
   {

   if (nil != path)
   {
   NSString *coverPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cover.jpg"];
   UIImage *img = [UIImage imageAtPath:coverPath];
   if (nil != img)
   {
   [img compositeToPoint:CGPointMake(0,0) operation:1];
   }
   }

   [super drawRect:rect];
   }
   */
- (void)toggleNavbars
{
	if (_heartbeatDelegate != nil) {
		if ([_heartbeatDelegate respondsToSelector:@selector(toggleNavbars)]) {
			[_heartbeatDelegate toggleNavbars];
		} else {
			[NSException raise:NSInternalInconsistencyException	format:@"Delegate doesn't respond to selector"];
}}}

- (void)loadBookWithPath:(NSString *)thePath subchapter:(int)theSubchapter
{
	BOOL junk;
	return [self loadBookWithPath:thePath numCharacters:-1 didLoadAll:&junk subchapter:theSubchapter];
}

- (void)loadBookWithPath:(NSString *)thePath numCharacters:(int)numChars subchapter:(int)theSubchapter
{
	BOOL junk;
	return [self loadBookWithPath:thePath numCharacters:numChars didLoadAll:&junk subchapter:theSubchapter];
}

- (void)setCurrentPathWithoutLoading:(NSString *)thePath
//USE WITH CAUTION!!!!
{
  [thePath retain];
  [path release];
	path = thePath;
}

- (void)loadBookWithPath:(NSString *)thePath numCharacters:(int)numChars didLoadAll:(BOOL *)didLoadAll subchapter:(int)theSubchapter
{
  NSLog(@"Entering loadBookWithPath...");
	NSString *theHTML = nil;
	NSLog(@"path: %@", thePath);
  [thePath retain];
  [path release];
	path = thePath;
  
  if          ([[[thePath pathExtension] lowercaseString] isEqualToString:@"txt"]) {
            theHTML = [self HTMLFromTextFile:thePath];
	} else if ([[[thePath pathExtension] lowercaseString] isEqualToString:@"fb2"]) {
			theHTML = [self HTMLFromFB2File:thePath];		
	} else if ([[[thePath pathExtension] lowercaseString] isEqualToString:@"zip"]) {
		theHTML = [self HTMLFromFB2File:thePath];		
	} else if ([[[thePath pathExtension] lowercaseString] isEqualToString:@"html"] || [[[thePath pathExtension] lowercaseString] isEqualToString:@"htm"]) {
		theHTML = [self HTMLFileWithoutImages:thePath];
	} else if ([[[thePath pathExtension] lowercaseString] isEqualToString:@"pdb"]) { 
		NSString *retType = nil;
		NSMutableString *ret;
		ret = ReadPDBFile(thePath, &retType);
		if([@"txt" isEqualToString:retType]) {
			theHTML = [self HTMLFromTextString:ret];
		} else {
			theHTML = ret;
		}
	}
	  	
	if ((-1 == numChars) || (numChars >= [theHTML length]))	{
		*didLoadAll = YES;
		[fullHTML release];
		fullHTML = [theHTML retain];
		if ([defaults subchapteringEnabled] == NO) {
      NSString *tempyString = [NSString stringWithFormat:@"<span style=\"font-size:%dpx; font-family:%@;\">%@</span></body></html>", [self textSize], [defaults textFont], fullHTML];
  	  [self setContentToHTMLString:tempyString];
			subchapter = 0;
		} else {
			[chapteredHTML setHTML:theHTML];
			if (theSubchapter < [chapteredHTML chapterCount]) subchapter = theSubchapter;
			else subchapter = 0;
      NSString *tempyString = [NSString stringWithFormat:@"<span style=\"font-size:%dpx; font-family:%@;\">%@</span></body></html>", [self textSize], [defaults textFont], [chapteredHTML getChapterHTML:subchapter]];
  	  [self setContentToHTMLString:tempyString];
		}
	} else {
		  NSString *tempyString = [NSString stringWithFormat:@"<span style=\"font-size:%dpx; font-family:%@;\">%@</span></body></html>", [self textSize], [defaults textFont], [theHTML HTMLsubstringToIndex:numChars didLoadAll:didLoadAll]];
	    [self setContentToHTMLString:tempyString];
	}
	
	/* This code doesn't work.  Sorry, charlie.
	   if (1) //replace with a defaults check
	   { 
	   NSMutableString *ebookPath = [NSString  stringWithString:[BooksDefaultsController defaultEBookPath]];
	   NSString *styleSheetPath = [ebookPath stringByAppendingString:@"/style.css"];
	   if ([[NSFileManager defaultManager] fileExistsAtPath:styleSheetPath])
	   {
	   [[self _webView] setUserStyleSheetLocation:[NSURL fileURLWithPath:ebookPath]];
	   }
	//[ebookPath release];
	}
	*/
  			
	 NSLog(@"Leaving loadBookWithPath");
}

- (NSString *)HTMLFileWithoutImages:(NSString *)thePath
{
	// The name of this method is in fact misleading--in Books.app < 1.2,
	// it did in fact strip images.  Not anymore, though.

	NSStringEncoding encoding = [defaults defaultTextEncoding];
	NSMutableString *originalText;
	NSString *outputHTML;
	NSLog(@"Checking encoding...");
	if (AUTOMATIC_ENCODING == encoding)
	{
		originalText = [[NSMutableString alloc]
			initWithContentsOfFile:thePath
					  usedEncoding:&encoding
							 error:NULL];
		NSLog(@"Encoding: %d",encoding);
		if (nil == originalText)
		{
			NSLog(@"Trying UTF-8 encoding...");
			originalText = [[NSMutableString alloc]
				initWithContentsOfFile:thePath
							  encoding: NSUTF8StringEncoding
								 error:NULL];
		}

		if (nil == originalText)
		{
			//NSLog(@"Checking  WIN1251 encoding...");
			originalText = [[NSMutableString alloc]
				initWithContentsOfFile:thePath
							  encoding:NSWindowsCP1251StringEncoding error:NULL];
		}

		if (nil == originalText)
		{
			NSLog(@"Trying ISO Latin-1 encoding...");
			originalText = [[NSMutableString alloc]
				initWithContentsOfFile:thePath
							  encoding: NSISOLatin1StringEncoding
								 error:NULL];
		}
		if (nil == originalText)
		{
			NSLog(@"Trying Mac OS Roman encoding...");
			originalText = [[NSMutableString alloc]
				initWithContentsOfFile:thePath
							  encoding: NSMacOSRomanStringEncoding
								 error:NULL];
		}
		if (nil == originalText)
		{
			NSLog(@"Trying ASCII encoding...");
			originalText = [[NSMutableString alloc] 
				initWithContentsOfFile:thePath
							  encoding: NSASCIIStringEncoding
								 error:NULL];
		}
		if (nil == originalText)
		{
			originalText = [[NSMutableString alloc] initWithString:NSLocalizedString(@"message.encoding_not_recognized",@"Not Recognized Encoding")];
		}
	}
	else // if encoding is specified
	{
		originalText = [[NSMutableString alloc]
			initWithContentsOfFile:thePath
						  encoding: encoding
							 error:NULL];
		if (nil == originalText)
		{
			originalText = [[NSMutableString alloc] initWithString:NSLocalizedString(@"message.encoding_incorrect",@"Incorrect Encoding")];
		}
	} //else

	NSRange fullRange = NSMakeRange(0, [originalText length]);

	unsigned int i;
	int extraHeight = 0;
	//Make all image src URLs into absolute file URLs.
	outputHTML = [HTMLFixer fixedHTMLStringForString:originalText filePath:thePath textSize:(int)size];

	//  struct CGSize asize = [outputHTML sizeWithStyle:nil forWidth:320.0];
	//  NSLog(@"Size for text: width: %f height: %f", asize.width, asize.height);
	return outputHTML;
}

- (NSString *)currentPath;
{
	return path;
}

- (void)embiggenText
// "A noble spirit embiggens the smallest man." -- Jebediah Springfield
{
	if (size < 36.0f)
	{
		struct CGRect oldRect = [self visibleRect];
		struct CGRect totalRect = [[self _webView] frame];
		NSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
		float middleRect = oldRect.origin.y + (oldRect.size.height / 2);
		float scrollFactor = middleRect / totalRect.size.height;
		size += 2.0f;
		[self setTextSize:size];

		if ([defaults subchapteringEnabled] &&
				(subchapter < [chapteredHTML chapterCount]))
		{
			[self setContentToHTMLString:[chapteredHTML getChapterHTML:subchapter]];
		}
		else
			[self setContentToHTMLString:fullHTML];

		totalRect = [[self _webView] frame];
		middleRect = scrollFactor * totalRect.size.height;
		oldRect.origin.y = middleRect - (oldRect.size.height / 2);
		NSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
		[self scrollPointVisibleAtTopLeft:oldRect.origin animated:NO];
		[self setNeedsDisplay];
	}
}

- (void)ensmallenText
// "What the f--- does ensmallen mean?" -- Zach Brewster-Geisz
{
	if (size > 10.0f)
	{
		struct CGRect oldRect = [self visibleRect];
		struct CGRect totalRect = [[self _webView] frame];
		NSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
		float middleRect = oldRect.origin.y + (oldRect.size.height / 2);
		float scrollFactor = middleRect / totalRect.size.height;
		size -= 2.0f;
		[self setTextSize:size];

		if ([defaults subchapteringEnabled] &&
				(subchapter < [chapteredHTML chapterCount]))
		{
			[self setContentToHTMLString:[chapteredHTML getChapterHTML:subchapter]];
		}
		else
			[self setContentToHTMLString:fullHTML];

		totalRect = [[self _webView] frame];
		middleRect = scrollFactor * totalRect.size.height;
		oldRect.origin.y = middleRect - (oldRect.size.height / 2);
		NSLog(@"size: %f y: %f\n", size, oldRect.origin.y);
		[self scrollPointVisibleAtTopLeft:oldRect.origin animated:NO];
		[self setNeedsDisplay];
	}
}
// None of these tap methods work yet.  They may never work.

- (void)handleDoubleTapEvent:(struct __GSEvent *)event
{
	[self embiggenText];
	//[super handleDoubleTapEvent:event];
}

- (void)handleSingleTapEvent:(struct __GSEvent *)event
{
	[self ensmallenText];
	//[super handleDoubleTapEvent:event];
}
/*
   - (BOOL)bodyAlwaysFillsFrame
   {//experiment!
   return NO;
   }
   */
- (void)mouseUp:(struct __GSEvent *)event
{
	/*************
	 * NOTE: THE GSEVENTGETLOCATIONINWINDOW INVOCATION
	 * WILL NOT COMPILE UNLESS YOU HAVE PATCHED GRAPHICSSERVICES.H TO ALLOW IT!
	 * A patch is included in the svn.
	 *****************/

 	struct CGRect tapRect = GSEventGetLocationInWindow(event);
  struct CGPoint clicked = [self convertPoint:tapRect.origin fromView:nil];

// RENAME TO clickedGlobal  - for dictionary
//                clicked = [self convertPoint:clicked fromView:nil];


	struct CGRect newRect = [self visibleRect];
	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];

	int lZoneHeight = [defaults enlargeNavZone] ? 75 : 48;
	NSLog(@"zone height %d", lZoneHeight);
	struct CGRect topTapRect = CGRectMake(0, 0, newRect.size.width, lZoneHeight);
	struct CGRect botTapRect = CGRectMake(0, contentRect.size.height - lZoneHeight, contentRect.size.width, lZoneHeight);

if ([defaults autoScrollEnabled]) {
 [defaults setAutoScrollEnabled:NO];
 [self toggleNavbars];
} else {

// COLEL dictionary - disable next line for selection
	if ([self isScrolling])
	{
		if (CGRectEqualToRect(lastVisibleRect, newRect))
		{
			if (CGRectContainsPoint(topTapRect, clicked))
			{
				if ([defaults inverseNavZone])
				{
					//scroll forward one screen...
					[self pageDownWithTopBar:![defaults navbar] bottomBar:NO];
				}
				else
				{
					//scroll back one screen...
					[self pageUpWithTopBar:NO bottomBar:![defaults toolbar]];
				}
			}
			else if (CGRectContainsPoint(botTapRect,clicked))
			{
				if ([defaults inverseNavZone])
				{
					//scroll back one screen...
					[self pageUpWithTopBar:NO bottomBar:![defaults toolbar]];
				}
				else
				{
					//scroll forward one screen...
					[self pageDownWithTopBar:![defaults navbar] bottomBar:NO];
				}
			}
			else 
			{  // If the old rect equals the new, then we must not be scrolling

//COLEL  dictionary

//             [self setSelectionWithPoint:clicked];
//             NSRange r = [self selectionRange];
//             r = NSMakeRange(r.location-20,20);
//             NSLog([[self HTML] substringWithRange:r]);
// -             [self setScrollingEnabled];
//             [self setSelectionRange:r];

		[self toggleNavbars];
			}
		}
		else
		{ //we are, in fact, scrolling
			[self hideNavbars];
		}
// COLEL
	}
}


	BOOL unused = [self releaseRubberBandIfNecessary];
	lastVisibleRect = [self visibleRect];
	[super mouseUp:event];
}



- (void)pageDownWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar
{

if ([self isAtBottom]) {
 if ([self gotoNextSubchapter]) return; 
}

	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];
	float  scrollness = contentRect.size.height;
	scrollness -= (((hasTopBar) ? 48 : 0) + ((hasBotBar) ? 48 : 0));
	scrollness /= (1.15f * size);
	scrollness = floor(scrollness - ([defaults scrollKeepLine]?1.0f:-0.0f));
	scrollness *= (1.15f * size);

	[self scrollByDelta:CGSizeMake(0, scrollness)	animated:YES];
	[self hideNavbars];
}

-(void)pageUpWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar
{

if ([self isAtTop]) {
 if ([self gotoPreviousSubchapter]) return; 
}

	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];
	float  scrollness = contentRect.size.height;
	scrollness -= (((hasTopBar) ? 48 : 0) + ((hasBotBar) ? 48 : 0));

	scrollness /= (_scrollRatio * size);
	scrollness = floor(scrollness - ([defaults scrollKeepLine]?1.0f:-0.0f));
	scrollness *= (_scrollRatio * size);

	// That little dance above was so we only scroll in
	// multiples of the text size.  And it doesn't even work!
	[self scrollByDelta:CGSizeMake(0, -scrollness) animated:YES];
	[self hideNavbars];
}

- (void)lineDown
{
if ([self isAtBottom]) { if ([self gotoNextSubchapter]) return; }
	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];
	float  scrollness = _scrollRatio * size;
	[self scrollByDelta:CGSizeMake(0, scrollness)	animated:YES];
	[self hideNavbars];
}

- (void)lineUp
{
if ([self isAtBottom]) { if ([self gotoNextSubchapter]) return; }
	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];
	float  scrollness = _scrollRatio * size;
	[self scrollByDelta:CGSizeMake(0, -scrollness)	animated:YES];
	[self hideNavbars];
}




- (int)textSize
// This method is needed because the toolchain doesn't
// currently handle floating-point return values in an
// ARM-friendly way.
{
	return (int)size;
}

- (void)setTextSize:(int)newSize
{
	size = (float)newSize;
  //[self setFont:[UIFont systemFontOfSize:size]];
}

- (void)scrollSpeedDidChange:(NSNotification *)aNotification
{
	switch ([defaults scrollSpeedIndex]) {
		case 0:	  [self setScrollToPointAnimationDuration:0.75];  break;
		case 1:	  [self setScrollToPointAnimationDuration:0.25];  break;
		case 2:	  [self setScrollToPointAnimationDuration:0.0];	  break;
	}
}

- (NSString *)HTMLFromTextFile:(NSString *)file
{
NSLog(@"Entering HTMLFromTextFile");
	NSStringEncoding encoding = [defaults defaultTextEncoding];
	NSString *outputHTML;
	NSMutableString *originalText;
	if (AUTOMATIC_ENCODING == encoding)
	{
		originalText = [[NSMutableString alloc] initWithContentsOfFile:file usedEncoding:&encoding error:NULL];
		if (nil == originalText) {	originalText = [[NSMutableString alloc]	initWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL]; }
		if (nil == originalText) {	originalText = [[NSMutableString alloc]	initWithContentsOfFile:file encoding:NSWindowsCP1251StringEncoding error:NULL];	}
		if (nil == originalText) {	originalText = [[NSMutableString alloc]	initWithContentsOfFile:file encoding:NSISOLatin1StringEncoding error:NULL];	}
		if (nil == originalText) {	originalText = [[NSMutableString alloc]	initWithContentsOfFile:file encoding:NSWindowsCP1252StringEncoding error:NULL];	}
		if (nil == originalText) {	originalText = [[NSMutableString alloc]	initWithContentsOfFile:file encoding:NSMacOSRomanStringEncoding error:NULL];}
		if (nil == originalText) {	originalText = [[NSMutableString alloc] initWithContentsOfFile:file encoding:NSASCIIStringEncoding error:NULL];	}
		if (nil == originalText) {	originalText = [[NSMutableString alloc] initWithString:NSLocalizedString(@"message.encoding_not_recognized",@"Not Recognized Encoding")];}
	}
	else {
		originalText = [[NSMutableString alloc]	initWithContentsOfFile:file encoding:encoding error:NULL];
		if (nil == originalText) {	originalText = [[NSMutableString alloc] initWithString:NSLocalizedString(@"message.encoding_incorrect",@"Incorrect Encoding")];	}
	}
	outputHTML = [self HTMLFromTextString:originalText];
	[originalText release];
    NSLog(@"Leaving HTMLFromTextFile");
	return outputHTML;
}

- (NSString*)HTMLFromTextString:(NSMutableString *)originalText 
{
	NSString *header = @"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 3.2//EN\">\n<html>\n\n<head>\n<title></title>\n</head>\n\n<body>\n<p>\n";
	NSString *outputHTML;
	NSRange fullRange = NSMakeRange(0, [originalText length]);

	unsigned int i,j;
	j=0;
	i = [originalText replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:fullRange];
	j += i;
	fullRange = NSMakeRange(0, [originalText length]);
	i = [originalText replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:fullRange];
	j += i;
	fullRange = NSMakeRange(0, [originalText length]);
	i = [originalText replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:fullRange];
	j += i;
	fullRange = NSMakeRange(0, [originalText length]);
	i = [originalText replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSLiteralSearch range:fullRange];
	j += i;
	fullRange = NSMakeRange(0, [originalText length]);
	if ([defaults smartConversion])	{
		i = [originalText replaceOccurrencesOfString:@"\n\n" withString:@"</p>\n<p>" options:NSLiteralSearch range:fullRange];
		j += i;
		fullRange = NSMakeRange(0, [originalText length]);
		i = [originalText replaceOccurrencesOfString:@"\r\r" withString:@"</p>\n<p>" options:NSLiteralSearch range:fullRange];
		j += i;
		i = [originalText replaceOccurrencesOfString:@"\n  " withString:@"</p>\n<p>" options:NSLiteralSearch range:fullRange];
		j += i;
		fullRange = NSMakeRange(0, [originalText length]);
		i = [originalText replaceOccurrencesOfString:@"\n\t" withString:@"</p>\n<p>" options:NSLiteralSearch range:fullRange];
		j += i;
	} else	{
		fullRange = NSMakeRange(0, [originalText length]);
		i = [originalText replaceOccurrencesOfString:@"\n" withString:@"<br />\n" options:NSLiteralSearch range:fullRange];
		fullRange = NSMakeRange(0, [originalText length]);
		i = [originalText replaceOccurrencesOfString:@"\r" withString:@"<br />\n" options:NSLiteralSearch range:fullRange];
		j += i;
	}
	fullRange = NSMakeRange(0, [originalText length]);
	i = [originalText replaceOccurrencesOfString:@"  " withString:@"&nbsp; " options:NSLiteralSearch range:fullRange];
	j += i;
	fullRange = NSMakeRange(0, [originalText length]);
	outputHTML = [NSString stringWithFormat:@"%@%@\n</p><br /><br />\n</body>\n</html>\n", header, originalText];
	return outputHTML;  
}

- (NSString *)HTMLFromFB2File:(NSString *)file
{
	NSStringEncoding encoding = [defaults defaultTextEncoding];
	NSString *outputHTML;
	NSMutableString *originalText;
	unsigned int i;
	NSString *originalFile = [file copy];
        NSString *tempDir = [NSTemporaryDirectory() stringByAppendingString:@"/ruBooks"]; 
NSLog(@"Entering HTMLFromFB2File");
 if ([[[originalFile pathExtension] lowercaseString] isEqualToString:@"zip"]) {
	NSLog(@"Entering unzip"); 	
	NSString *cmd = @"/usr/bin/unzip -o \"";
	cmd = [cmd stringByAppendingString:file];
	cmd = [cmd stringByAppendingString:@"\" -d "];
	cmd = [cmd stringByAppendingString:tempDir];
	system([cmd UTF8String]);
	NSLog(@"Leaving unzip");
// FOR SOME REASON enumeratorAtPath AND directoryContentsAtPath MAY RETURN DIFFERENT SET OF FILES
	NSArray *fileArray = [[NSFileManager defaultManager] directoryContentsAtPath:tempDir];
	if ([fileArray count] > 0) {
		file = [[tempDir stringByAppendingString:@"/"] stringByAppendingString:[fileArray objectAtIndex:0]];
	} else { return NSLocalizedString(@"message.failed_unzip",@"Failed to unpack the archive"); }
	file = [NSString stringWithUTF8String:[file UTF8String]];
 } 

NSLog(@"Reading %@",file);

// DEFAULT ObjC READ FUNCTIONS FAILED ON SOME FILES WITH CYRILLICAL NAMES
        char *cFile;
	long  lFileLen;

	FILE *src = fopen([file UTF8String], "rb");
        fseek(src, 0L, SEEK_END);
        lFileLen = ftell(src);
	rewind(src);
	cFile = calloc(lFileLen + 1, sizeof(char));
	fread(cFile, lFileLen, 1, src);
	fclose(src);

	NSString *text;

	NSLog(@"Encoding:");
	if (AUTOMATIC_ENCODING == encoding) {
		text = [NSString stringWithCString:cFile encoding:NSWindowsCP1251StringEncoding];
                 if (nil == text) { text = [NSString stringWithCString:cFile encoding:NSUTF8StringEncoding]; }
                 if (nil == text) { text = [NSString stringWithCString:cFile encoding:NSISOLatin1StringEncoding]; }
                 if (nil == text) { text = [NSString stringWithCString:cFile encoding:NSWindowsCP1252StringEncoding]; }
                 if (nil == text) { text = [NSString stringWithCString:cFile encoding:NSMacOSRomanStringEncoding]; }
                 if (nil == text) { text = [NSString stringWithCString:cFile encoding:NSASCIIStringEncoding]; }
                 if (nil == text) { text = NSLocalizedString(@"message.encoding_not_recognized",@"Not Recognized Encoding"); }
	} else {
	NSLog(@"non-automatic encoding");
        text = [NSString stringWithCString:cFile encoding:encoding];
                 if (nil == text) { text = NSLocalizedString(@"message.encoding_incorrent",@"Incorrent Encoding"); }
	}
	free(cFile);
	originalText = [[NSMutableString alloc]	initWithString:text];
//	[text release];
	outputHTML = [self HTMLFromFB2String:originalText];
	[originalText release];
if ([[[originalFile pathExtension] lowercaseString] isEqualToString:@"zip"]) {
	NSString *cmd = @"rm -rf ";
        cmd = [cmd stringByAppendingString:tempDir];
	system([cmd UTF8String]);
	file = [originalFile copy];
}
	NSLog(@"Leaving HTMLFromFB2File");
	return outputHTML;
}

- (NSString*)HTMLFromFB2String:(NSMutableString *)originalText 
{
NSLog(@"Entering HTMLFromFB2String");
	NSString *header = @"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 3.2//EN\">\n<html>\n\n<head>\n<title></title>\n</head>\n\n<body>\n<p>\n";
	NSString *outputHTML;

// SOME MAL-FORMED FB2 MAY CONTAIN <H2> TAGS THAT WOULD CRASH BOOKS
	[originalText replaceOccurrencesOfString:@"<h2" withString:@"<h3" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
	[originalText replaceOccurrencesOfString:@"</h2>" withString:@"</h3>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];

NSLog(@"Tags");	
	[originalText replaceOccurrencesOfString:@"subtitle>" withString:@"b><br>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
	[originalText replaceOccurrencesOfString:@"title>" withString:@"h2>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];

	[originalText replaceOccurrencesOfString:@"<p>" withString:@"<p align=justify>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
	[originalText replaceOccurrencesOfString:@"emphasis>" withString:@"i>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];

//	[originalText replaceOccurrencesOfString:@"<epigraph>" withString:@"<p align=right>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
//	[originalText replaceOccurrencesOfString:@"</epigraph>" withString:@"</p>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];

// VERSES
	[originalText replaceOccurrencesOfString:@"</v>" withString:@"<br>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
	[originalText replaceOccurrencesOfString:@"</stanza>" withString:@"<br>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];

// IMAGES
NSLog(@"Images");
        NSRange range, start, end;
        NSString *imageString;
        range = NSMakeRange(0, [originalText length]);
        start = [originalText rangeOfString:@"<binary" options:NSLiteralSearch range:range];
        end = [originalText rangeOfString:@"</binary>" options:NSLiteralSearch range:range];
// TODO: OTHER IMAGES
        if (start.length && end.length) {
           unsigned int length = end.location - start.location + end.length;
           imageString = [originalText substringWithRange:NSMakeRange(start.location, length)];
           [originalText deleteCharactersInRange:NSMakeRange(start.location, length)];
           [originalText insertString:imageString atIndex:0];
        }
	// [imageString release];
                                                                       
// REMOVE NEW LINE AROUND BINARY DATA
	[originalText replaceOccurrencesOfString:@"\r\n/9j/" withString:@"/9j/" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
	[originalText replaceOccurrencesOfString:@">/9j/" withString:@"><img src='data:image/jpeg;base64,/9j/" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
	[originalText replaceOccurrencesOfString:@">iVBORw0" withString:@"><img src='data:image/png;base64,iVBORw0" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
	[originalText replaceOccurrencesOfString:@"</binary>" withString:@"' width=280>" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];

/*  TODO: OPTION TO HIDE IMAGES
	[originalText replaceOccurrencesOfString:@"<binary" withString:@"<!-- <" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
	[originalText replaceOccurrencesOfString:@"</binary>" withString:@" -->" options:NSLiteralSearch range:NSMakeRange(0, [originalText length])];
*/
  
NSLog(@"Finalization");	
	outputHTML = [NSString stringWithFormat:@"%@%@\n</p><br /><br />\n</body>\n</html>\n", header, originalText];
	NSLog(@"Leaving HTMLFromFB2String");
	return outputHTML;  
}

- (float)nsStringToFloat:(NSString *)s defaultValue:(float )defaultValue
{
 float result = defaultValue;
 if ([s length] > 0) result = [s floatValue];
 NSLog(@"Result: %f",result);
 return result;
}

- (void)invertText:(BOOL)b
{
NSLog(@"Entering invertText");

                                                    
// MOVE TO INITIALIZATION

float backgroundColorNight[4]	= {0, 0, 0, 1};
float textColorNight[4] 	= {1, 1, 1, 1};
float backgroundColorDay[4]	= {1, 1, 1, 1};
float textColorDay[4]		= {0, 0, 0, 1};
 int i;
 for (i=0;i<3;i++) {
   textColorDay[i] = [defaults color:0 component:i];
   backgroundColorDay[i] = [defaults color:1 component:i];
   textColorNight[i] = [defaults color:2 component:i];
   backgroundColorNight[i] = [defaults color:3 component:i];
 }

 // ********************************
 /*   NSString *filename = @"/Applications/ruBooks.app/rubooks_additional_settings.plist";
	NSDictionary *dictionary;
	NSString *backgroundFile;
	dictionary = [NSDictionary dictionaryWithContentsOfFile:filename];
	if (dictionary) {
		backgroundFile = [dictionary valueForKey:(b?@"background_file.night":@"background_file.day")];
		[dictionary release];
	}
	
		UIImage *image;
		image = [UIImage applicationImageNamed:@"/Applications/ruBooks.app/icon.png"];
		[image drawAsPatternInRect:[defaults fullScreenApplicationContentRect]];
		[self setAlpha:1];
*/
// ********************************	
	
 
	if (b)
	{
		// makes the the view white text on black
		//CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		//[self setBackgroundColor: CGColorCreate( colorSpace, backgroundColorNight)];
		//[self setTextColor: CGColorCreate( colorSpace, textColorNight)];
		[self setScrollerIndicatorStyle:2];
		
	} else {
		//CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		//[self setBackgroundColor: CGColorCreate( colorSpace, backgroundColorDay)];
		//[self setTextColor: CGColorCreate( colorSpace, textColorDay)];
		[self setScrollerIndicatorStyle:0];
	}


	// This "setHTML" invocation is a kludge;
	// for some reason the display doesn't update correctly
	// without it, and we can't yet figure out how to fix it.
	struct CGRect oldRect = [self visibleRect];

        [defaults subchapteringEnabled];
	[chapteredHTML chapterCount];
	if ([defaults subchapteringEnabled] &&
			(subchapter < [chapteredHTML chapterCount]))
	{
		[self setContentToHTMLString:[chapteredHTML getChapterHTML:subchapter]];
	}
	else
		[self setContentToHTMLString:fullHTML];
	[self scrollPointVisibleAtTopLeft:oldRect.origin];
	[self setNeedsDisplay];
NSLog(@"Leaving invertText");
}


- (void)dealloc
{
	//[tapinfo release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[path release];
	[chapteredHTML release];
	[fullHTML release];
	[defaults release];
	[super dealloc];
}

- (int) getSubchapter
{
	return subchapter;
}

- (int) getMaxSubchapter
{
	int maxSubchapter = 1;

	if ([defaults subchapteringEnabled] == YES)
		maxSubchapter = [chapteredHTML chapterCount];

	return maxSubchapter;
}

- (void) setSubchapter: (int) newSubchapter
{
	CGPoint origin = { 0, 0 };

	if ([defaults subchapteringEnabled] &&
			(subchapter < [chapteredHTML chapterCount]))
	{
		[self setContentToHTMLString:[chapteredHTML getChapterHTML:newSubchapter]];
		subchapter = newSubchapter;
	}
	else
		[self setContentToHTMLString:fullHTML];

	[self scrollPointVisibleAtTopLeft:origin];
	[self setNeedsDisplay];

}

- (BOOL) gotoNextSubchapter
{
	CGPoint origin = { 0, 0 };

	if ([defaults subchapteringEnabled] == NO)
		return NO;

	if ((subchapter + 1) >= [chapteredHTML chapterCount])
		return NO;

	[defaults setLastScrollPoint: [self visibleRect].origin.y
				   forSubchapter: subchapter
						 forFile: path];

	[self setContentToHTMLString:[chapteredHTML getChapterHTML:++subchapter]];

//	origin.y = [defaults lastScrollPointForFile:path inSubchapter:subchapter];
        origin.y = 0; // ALWAYS GO TO THE TOP OF THE PAGE

	[self scrollPointVisibleAtTopLeft:origin];
	[self setNeedsDisplay];
	return YES;
}

- (BOOL) gotoPreviousSubchapter
{
	CGPoint origin = { 0, 0 };

	if ([defaults subchapteringEnabled] == NO)
		return NO;

	if (subchapter == 0)
		return NO;

	[defaults setLastScrollPoint: [self visibleRect].origin.y
				   forSubchapter: subchapter
						 forFile: path];

	[self setContentToHTMLString:[chapteredHTML getChapterHTML:--subchapter]];
	struct CGRect textRect = [[self _webView] frame];

//	origin.y = [defaults lastScrollPointForFile:path inSubchapter:subchapter];
	origin.y = textRect.origin.y + textRect.size.height - [self visibleRect].size.height;


	[self scrollPointVisibleAtTopLeft:origin];
	[self setNeedsDisplay];
	return YES;
}


-(void) redraw
{
	if ([defaults subchapteringEnabled] &&
			(subchapter < [chapteredHTML chapterCount]))
	{
		[self setContentToHTMLString:[chapteredHTML getChapterHTML:subchapter]];
	}
	else
		[self setContentToHTMLString:fullHTML];
	CGRect lWebViewFrame = [[self _webView] frame];
	CGRect lFrame = [self frame];
	NSLog(@"lWebViewFrame :  x=%f, y=%f, w=%f, h=%f", lWebViewFrame.origin.x, lWebViewFrame.origin.y, lWebViewFrame.size.width, lWebViewFrame.size.height);
	NSLog(@"lFrame : x=%f, y=%f, w=%f, h=%f", lFrame.origin.x, lFrame.origin.y, lFrame.size.width, lFrame.size.height);
	[[self _webView]setFrame: [self frame]];
	[self setNeedsDisplay];
}


- (void)volumeChanged:(NSNotification *)notification
{
// if ([[UIApplication sharedApplication] isSuspended]) return;
 if (![defaults scrollByVolumeButtons]) return;
 if (![defaults readingText]) return;

	struct CGRect newRect = [self visibleRect];
	struct CGRect contentRect = [defaults fullScreenApplicationContentRect];
	if (CGRectEqualToRect(lastVisibleRect, newRect))
{


 float volume;
 NSString *audioDeviceName;
 [avs getActiveCategoryVolume: &volume andName: &audioDeviceName];
 NSLog(@"Volume %f",volume);
 if (volume != defaultVolume) {
 
    BOOL scrollUp = NO;
	if (volume > defaultVolume) scrollUp = YES;
	if ([defaults inverseNavZone]) scrollUp = !scrollUp;

 
/*  if ([defaults autoScrollEnabled]) {
    int currentSpeed = [defaults autoScrollSpeed];
    if ((scrollUp)  && (currentSpeed < 10 ))  { [defaults setAutoScrollSpeed:(currentSpeed + 1)]; }
    if ((!scrollUp) && (currentSpeed > 1 ))  { [defaults setAutoScrollSpeed:(currentSpeed - 1)]; }
    [avs setActiveCategoryVolumeTo: defaultVolume];
  return;
 }	
 */

   if (_volumeButtonsScrollOneLine) {
        if (scrollUp) { [self lineUp];} else {[self lineDown];}
   } else 
   if (scrollUp) {
	[self pageUpWithTopBar:NO bottomBar:![defaults toolbar]];
   } else {
	[self pageDownWithTopBar:![defaults navbar] bottomBar:NO];
   }
   [avs setActiveCategoryVolumeTo: defaultVolume];
 }
}
	BOOL unused = [self releaseRubberBandIfNecessary];
	lastVisibleRect = [self visibleRect];
}

- (void)scrollDown:(float)delta
{
		[self scrollByDelta:CGSizeMake(0, delta) animated:NO];
		[self displayScrollerIndicators];
}


- (BOOL)isAtTop
{
	struct CGRect rect = [self visibleRect];
	if ((rect.origin.y) <= 0) { 
             return YES;
        } else {
             return NO;
        } 
}

- (BOOL)isAtBottom
{
	struct CGRect rect = [self visibleRect];
	struct CGRect textRect = [[self _webView] frame];
	if ((rect.origin.y+rect.size.height) >= (textRect.origin.y+textRect.size.height)) { 
             return YES;
        } else {
             return NO;
        } 
}

- (float)absolutePosition
{
	CGRect lDefRect = [defaults fullScreenApplicationContentRect];
	CGRect theWholeShebang = [[self _webView] frame];
	CGRect visRect = [self visibleRect];
	int endPos = (int)theWholeShebang.size.height - lDefRect.size.height;
	if (endPos == 0) return 0.0f;
    return [chapteredHTML convertChapterPosition:(visRect.origin.y / endPos) inChapter:subchapter];
}

- (BOOL) find:(NSString *)string {
 _lastSearchPosition = 0;
 _lastSearchChapter = 0;
 return [self findNext:string];
}

- (BOOL) findNext:(NSString *)string;
{
 if ([string length] == 0) return NO;
 if (_lastSearchChapter >= [self getMaxSubchapter]) return NO;
 
		if (_lastSearchString != nil) [_lastSearchString release];
		_lastSearchString = [NSString stringWithString:string];
		[_lastSearchString retain];
		NSString *searchText = [chapteredHTML getChapterHTML:_lastSearchChapter];
		
// reset on load
//  setlastscrollpoint
//	[defaults setLastScrollPoint: [self visibleRect].origin.y   forSubchapter: subchapter forFile: path];
		
		if (subchapter != _lastSearchChapter) {
			if ([searchText rangeOfString:string options:NSCaseInsensitiveSearch].location==NSNotFound) { // PRE-CHECK
				_lastSearchChapter++;
				return [self findNext:string];				
			}
			[self setSubchapter:_lastSearchChapter];
			_lastSearchPosition = 0;
		}
		
		searchText = [self text];
		NSRange searchRange = NSMakeRange(_lastSearchPosition, [searchText length]-_lastSearchPosition);
		NSRange range = [searchText rangeOfString:string options:NSCaseInsensitiveSearch range:searchRange];
		if (range.location == NSNotFound) {
			_lastSearchChapter++;
			return [self findNext:string];
		}
		_lastSearchPosition =  range.location+range.length;
//		NSLog(@"Found range: %d, %d", range.location, range.length);
		CGRect r = [self rectForSelection:range];
			   r.origin.y -= 96.0f;
		[self scrollPointVisibleAtTopLeft:r.origin animated:YES];
		[self setNeedsDisplay];
//		NSLog(@"Selection rect:  (%f,%f) - (%f,%f) ",r.origin.x,r.origin.y,r.size.width,r.size.height);
 return YES;
}

- (NSString *) lastSearchString
{
 return _lastSearchString;
}

- (SimpleWebView *) _webView
{
 return [[UIApp getSafariController] getWebView];
}

- (CGRect) visibleRect
{
  return ebVisibleRect;
}

@end
