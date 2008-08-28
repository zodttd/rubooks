// HTMLFixer.m, for Books.app by Zachary Brewster-Geisz
/* Most of this file is now obsolete.  Don't get excited if warnings
from some of the methods appear on compile.  They're probably unused.
*/

#include "HTMLFixer.h"

@implementation HTMLFixer

+(BOOL)fileHasBeenFixedAtPath:(NSString *)path
// Returns YES if the file has already been processed by HTMLFixer.
// Returns NO if it hasn't, or there was an error reading the file.
{
    NSFileHandle *theFile = [NSFileHandle fileHandleForReadingAtPath:path];
	if (nil != theFile)
        {
            NSData *beginningData = [[theFile readDataOfLength:24] retain];
            NSString *beginningString = [[NSString alloc] initWithData:beginningData
                                                encoding:NSUTF8StringEncoding];
            if (nil != beginningString)
                {
                    BOOL ret = [[beginningString substringWithRange:NSMakeRange(0, 12)]
                                  isEqualToString:@"<!--BooksApp"];
                    [beginningString release];
                    return ret;
                }
        }
    return NO;
}

+(BOOL)writeFixedFileAtPath:(NSString *)thePath
// Fixes the given HTML file and rewrites it.  Returns YES if successful, NO otherwise.
// You should always call +fileHasBeenFixed first to see if this method is needed.
//FIXME: use the user-defined text encoding, if applicable.
{
    BooksDefaultsController *defaults = [BooksDefaultsController sharedBooksDefaultsController];
    NSMutableString *theHTML = [[NSMutableString alloc] initWithContentsOfFile:thePath
                                            encoding:NSUTF8StringEncoding
                                            error:NULL];
    BOOL ret;
/*  if (nil == theHTML)
    {
      NSLog(@"Trying UTF-8 encoding...");
      theHTML = [[NSMutableString alloc]
               initWithContentsOfFile:thePath
               encoding: NSUTF8StringEncoding
               error:NULL];
    }
*/    if (nil == theHTML)
    {
      NSLog(@"Trying ISO Latin-1 encoding...");
      theHTML = [[NSMutableString alloc]
               initWithContentsOfFile:thePath
               encoding: NSISOLatin1StringEncoding
               error:NULL];
    }
    if (nil == theHTML)
    {
      NSLog(@"Trying Mac OS Roman encoding...");
      theHTML = [[NSMutableString alloc]
               initWithContentsOfFile:thePath
               encoding: NSMacOSRomanStringEncoding
               error:NULL];
    }
    if (nil == theHTML)
    {
      NSLog(@"Trying ASCII encoding...");
      theHTML = [[NSMutableString alloc] 
               initWithContentsOfFile:thePath
               encoding: NSASCIIStringEncoding
               error:NULL];
    }
    if (nil == theHTML)  // Give up.  The webView will still display it.
        return NO;
    NSMutableString *newHTML = [NSMutableString stringWithString:[HTMLFixer fixedHTMLStringForString:theHTML filePath:thePath textSize:[defaults textSize]]];
    NSString *temp = [NSString stringWithFormat:@"<!--BooksApp modified %@ -->\n",
                        [NSCalendarDate calendarDate]];
    [newHTML insertString:temp atIndex:0];
    ret = [newHTML writeToFile:thePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    [theHTML release];
    [defaults release];
    return ret;
}

+(NSString *)fixedImageTagForString:(NSString *)aStr basePath:(NSString *)path returnImageHeight:(int *)returnHeight
// Returns an image tag for which the image has been shrunk to 300 pixels wide.
// Changes the local file URL to an absolute URL since that's what the
// UITextViewLegacy seems to like.
// Does nothing if the image is already under 300 px wide.
// Assumes a local URL as the "src" element.
{
    NSMutableString *str = [NSMutableString stringWithString:aStr];
    unsigned int len = [str length];
    NSRange range;
    NSString *tempString;
    unsigned int c = 0;
    unsigned int d = 0;
    unsigned int width = 300;
    unsigned int height = 0;
    NSString *srcString = nil;
    NSRange pathRange;
    // First step, find the "src" string.
    while (c + 4 < len)
        {
            range = NSMakeRange(c++, 4);
            tempString = [[str substringWithRange:range] lowercaseString];
            if ([tempString isEqualToString:@"src="])
                {
                    pathRange = [str quotedRangePastIndex:c];
		    if (pathRange.location == NSNotFound)
		      srcString = nil;
		    else
		      srcString = [str substringWithRange:pathRange];
		    //NSLog(@"srcString: %@", srcString);
                    //With any luck, this will be the file name.
                    break;
                }
        }
    if (srcString == nil)
        return [aStr copy];
    NSString *noPercentString = [srcString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //FIXME?  Should I worry about encodings?
    NSString *imgPath = [[path stringByAppendingPathComponent:noPercentString] stringByStandardizingPath];
    NSURL *pathURL = [NSURL fileURLWithPath:imgPath];
    NSString *absoluteURLString = [pathURL absoluteString];
    //NSLog(@"absoluteURLString: %@", absoluteURLString);
    [str replaceCharactersInRange:pathRange withString:absoluteURLString];
    //here's hopin'!
    len = [str length];

    UIImage *img = [UIImage imageAtPath:imgPath];
    if (nil != img)
        {
            CGImageRef imgRef = [img imageRef];
            height = CGImageGetHeight(imgRef);
            width = CGImageGetWidth(imgRef);
	    //NSLog(@"image's width: %d height: %d", width, height);
            if (width <= 300)
	      {
		*returnHeight = (int)height;
                return [NSString stringWithString:str];
	      }
            float aspectRatio = (float)height / (float)width;
            width = 300;
            height = (unsigned int)(300.0 * aspectRatio);
	    *returnHeight = (int)height;
        }
    // Now, find if there's a "height" tag.
    c = 0;
    while (c + 7 < len)
        {
            range = NSMakeRange(c++, 7);
            tempString = [[str substringWithRange:range] lowercaseString];
            if ([tempString isEqualToString:@"height="])
                {
		  NSLog(@"found height tag");
		  NSRange anotherRange = [str quotedRangePastIndex:c];
		  NSString *heightNumString = [NSString stringWithFormat:@"%d", (int)height];
		  if (anotherRange.location != NSNotFound)
		    [str replaceCharactersInRange:anotherRange withString:heightNumString];
		  len = [str length];

		  break;
                }
        }
    // If there's no height tag, we don't need to worry about inserting one.
    // Now, to find the width tag.
    c = 0;
    BOOL foundWidth = NO;
    while (c + 6 < len)
        {
            range = NSMakeRange(c++, 6);
            tempString = [[str substringWithRange:range] lowercaseString];
            if ([tempString isEqualToString:@"width="])
	      {
                    foundWidth = YES;
		    NSRange anotherRange = [str quotedRangePastIndex:c];
                    NSString *widthNumString = [NSString stringWithFormat:@"%d", (int)width];
		    if (anotherRange.location != NSNotFound)
		      [str replaceCharactersInRange:anotherRange withString:widthNumString];
                    len = [str length];
                    break;
                }
        }
    if (!foundWidth)
    // There was no width tag, so let's just insert one.
        {
            NSString *widthString = [NSString stringWithFormat:@" width=\"%d\" ", (int)width];
            [str insertString:widthString atIndex:4];
        }
    NSLog(@"returning str: %@", str);
    return [NSString stringWithString:str];
}

+(NSString *)fixedHTMLStringForString:(NSString *)theOldHTML filePath:(NSString *)thePath textSize:(int)size
  // Fixes all img tags within a given string
{
  BooksDefaultsController *defaults = [BooksDefaultsController sharedBooksDefaultsController];
  NSMutableString *theHTML = [NSMutableString stringWithString:theOldHTML];
  int thisImageHeight = 0;
  int height = 0;
    unsigned int c = 0;
    unsigned int len = [theHTML length];
    while (c < len)
        {
            if ([theHTML characterAtIndex:c] == (unichar)'<')
                {
                    NSString *imgString = [[theHTML substringWithRange:NSMakeRange(c+1, 3)]
                        lowercaseString];
                    if ([imgString isEqualToString:@"img"])
                        {
                            unsigned int d = c++;
                            while ((c < len) && ([theHTML characterAtIndex:c] != (unichar)'>'))
                                c++;
                            NSRange aRange = NSMakeRange(d, (c - d));
                            NSString *imageTagString = [theHTML substringWithRange: aRange];

// COLEL: DISABLED AS NOT WORKING PROPERLY WITH EMBEDED IMAGES
//                            [theHTML replaceCharactersInRange:aRange
//                                 withString:[HTMLFixer fixedImageTagForString:imageTagString
//                                                        basePath:[thePath stringByDeletingLastPathComponent]
//						       returnImageHeight:&thisImageHeight]];
                            len = [theHTML length];
			    height += thisImageHeight;
			    thisImageHeight = 0;
                        }
                }
            ++c;
        }
  NSRange fullRange = NSMakeRange(0, [theHTML length]);
  int i = [theHTML replaceOccurrencesOfString:@"@import" withString:@"!@import" options:NSLiteralSearch range:fullRange];
  //FIXME!  This will screw things up if the _readable_ text contains @import!!
  fullRange = NSMakeRange(0, [theHTML length]);
  i = [theHTML replaceOccurrencesOfString:@"style=\"width:" withString:@"style=\"wodth:" options:NSLiteralSearch range:fullRange];
  //  NSLog(@"Removed %d width style tags.\n", i);

  //Quirky dash behavior!  Possibly fixed in firmware 1.1.1
  fullRange = NSMakeRange(0, [theHTML length]);
  //  i = [theHTML replaceOccurrencesOfString:@"&mdash;" withString:@" &mdash; " options:NSLiteralSearch range:fullRange];


  if (![defaults renderTables])
    {
      fullRange = NSMakeRange(0, [theHTML length]);
      i = [theHTML replaceOccurrencesOfString:@"<table" withString:@"<pre" options:NSLiteralSearch range:fullRange];
      fullRange = NSMakeRange(0, [theHTML length]);
      i += [theHTML replaceOccurrencesOfString:@"<TABLE" withString:@"<pre" options:NSLiteralSearch range:fullRange];
      fullRange = NSMakeRange(0, [theHTML length]);
      i = [theHTML replaceOccurrencesOfString:@"</table" withString:@"</pre" options:NSLiteralSearch range:fullRange];
      fullRange = NSMakeRange(0, [theHTML length]);
      i += [theHTML replaceOccurrencesOfString:@"</TABLE" withString:@"</pre" options:NSLiteralSearch range:fullRange];
      NSLog(@"Removed %d table tags.", i);
    }

  //HERE THERE BE KLUDGES.
  //We must add enough <br />s to the bottom, to make up for the height of
  //the images, because the UITextViewLegacy doesn't take them into account.

  NSMutableString *themsTheBreaks = [[NSMutableString alloc] initWithString:@"<br /><br />\n"]; 
  // two breaks always, to fix some silly rendering bug
  for (i = 0 ; i < height; i += size) //FIXME?
    {
      [themsTheBreaks appendString:@"<br />\n"];
    }
  [themsTheBreaks appendString:@"</body>"];
  NSLog(@"themsTheBreaks: %@", themsTheBreaks);
  fullRange = NSMakeRange(0, [theHTML length]);
  i = [theHTML replaceOccurrencesOfString:@"</body>" withString:themsTheBreaks options:NSLiteralSearch range:fullRange];
  fullRange = NSMakeRange(0, [theHTML length]);
  i += [theHTML replaceOccurrencesOfString:@"</BODY>" withString:themsTheBreaks options:NSLiteralSearch range:fullRange];
  NSLog(@"Found %d body end tags.", i);

  [defaults release];        
    return [NSString stringWithString:theHTML];
}

@end
