// EBookImageView.m, for Books.app by Zachary Brewster-Geisz

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

#import "EBookImageView.h"
#import "BooksDefaultsController.h"

@implementation EBookImageView

-(EBookImageView *)initWithContentsOfFile:(NSString *)file
{
  struct CGRect rect = [[BooksDefaultsController sharedBooksDefaultsController] fullScreenApplicationContentRect];
  rect.origin.x = rect.origin.y = 0;
  self = [super initWithFrame:rect];
  [self setAllowsFourWayRubberBanding:YES];
  float components[4] = { 0.5, 0.5, 0.5, 1.0 };
  //CGColorRef gray = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
  //[self setBackgroundColor:gray];
  UIImage *img = [UIImage imageAtPath:file];
  CGImageRef imgRef = [img imageRef];
  unsigned int width = CGImageGetWidth(imgRef);
  unsigned int height = CGImageGetHeight(imgRef);
  if ((height != 0) && (width != 0))
    {
      float aspectRatio = (float)width / (float)height;
      if ((width < rect.size.width) && (height < (rect.size.height - 48)))
	{  // Let's be nice, and make the small images big!
	  if (height > width)
	    {
	      height = (unsigned int)(rect.size.height - 48);
	      width = (unsigned int)(height * aspectRatio);
	    }
	  else
	    {
	      width = (unsigned int)rect.size.width;
	      height = (unsigned int)(width / aspectRatio);
	    }
	}
      [self setContentSize:CGSizeMake(width,height + 48)];
      _imgView = [[UIImageView alloc] initWithImage:img];
      //_imgView = [[UIWebView alloc] init];
      //Let's be super-nice and center the image if applicable!
      int x = 0;
      if (width < rect.size.width)
	x = (int)(rect.size.width - width) / 2;
      int y = 0;
      if (height < (rect.size.height - 48))
	y = (int)(rect.size.height - 48 - height) / 2;
      [_imgView setFrame:CGRectMake(x, y + 48, width, height)];
      //      [_imgView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:file]]];
      //      [_imgView setEnabledGestures:255];
      [self addSubview:_imgView];
      [[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE
					    object:file];
    }
  return self;

}

-(EBookImageView *)initWithContentsOfFile:(NSString *)file withinSize:(struct CGSize)size
{
  struct CGRect rect = [[BooksDefaultsController sharedBooksDefaultsController] fullScreenApplicationContentRect];
  rect.origin.y = rect.origin.x = 0;
  self = [super initWithFrame:rect];
  [self setAllowsFourWayRubberBanding:YES];
  float components[4] = { 0.5, 0.5, 0.5, 1.0 };
  //CGColorRef gray = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
  //[self setBackgroundColor:gray];
  UIImage *img = [UIImage imageAtPath:file];
  CGImageRef imgRef = [img imageRef];
  unsigned int width = CGImageGetWidth(imgRef);
  unsigned int height = CGImageGetHeight(imgRef);
  if ((height != 0) && (width != 0))
    {
      float aspectRatio = (float)width / (float)height;
      if (aspectRatio < (size.width/size.height))
	{
	  height = (unsigned int)size.height;
	  width = (unsigned int)(height * aspectRatio);
	}
      else
	{
	  width = (unsigned int)size.width;
	  height = (unsigned int)(width / aspectRatio);
	}
      [self setContentSize:CGSizeMake(width, height)];
      _imgView = [[UIImageView alloc] initWithImage:img];
      //_imgView = [[UIWebView alloc] init];
      //Let's be super-nice and center the image if applicable!
      int x = 0;
      if (width < rect.size.width)
	x = (int)(rect.size.width - width) / 2;
      int y = 0;
      if (height < (rect.size.height))
	y = (int)(rect.size.height - height) / 2;
      [_imgView setFrame:CGRectMake(x, y, width, height)];
      //      [_imgView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:file]]];
      //      [_imgView setEnabledGestures:255];
      [self addSubview:_imgView];
    }
  return self;

}

- (void)dealloc
{
  [_imgView release];
  [super dealloc];
}

+(NSString *)coverArtForBookPath:(NSString *)path
{
  BOOL isDir;
  NSFileManager *defaultM = [NSFileManager defaultManager];
  BOOL fileExists = [defaultM fileExistsAtPath:path isDirectory:&isDir];
  NSString *basePath;

// TODO: replace with proper paths 
  if (isDir) { 
         basePath = path;
//  	 basePath = [path stringByDeletingLastPathComponent];
   	if ([defaultM fileExistsAtPath:[basePath stringByAppendingPathComponent:@"cover.jpg"]])
   		 return [basePath stringByAppendingPathComponent:@"cover.jpg"];
 	if ([defaultM fileExistsAtPath:[basePath stringByAppendingPathComponent:@"cover.png"]])
    		return [basePath stringByAppendingPathComponent:@"cover.png"];
  	if ([defaultM fileExistsAtPath:[basePath stringByAppendingPathComponent:@"cover.gif"]])
    		return [basePath stringByAppendingPathComponent:@"cover.gif"];
    		return @"/Applications/ruBooks.app/folder.png"; 
  }

  if ([[[path pathExtension] lowercaseString] isEqualToString:@"zip"]) return @"/Applications/ruBooks.app/zip.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"html"]) return @"/Applications/ruBooks.app/html.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"htm"]) return @"/Applications/ruBooks.app/html.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"fb2"]) return @"/Applications/ruBooks.app/fb2.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"doc"]) return @"/Applications/ruBooks.app/doc.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"xls"]) return @"/Applications/ruBooks.app/excel.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"txt"]) return @"/Applications/ruBooks.app/text.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"pdf"]) return @"/Applications/ruBooks.app/pdf.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"ppt"]) return @"/Applications/ruBooks.app/powerpoint.png";

  if ([[[path pathExtension] lowercaseString] isEqualToString:@"gif"]) return @"/Applications/ruBooks.app/gif.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"jpg"]) return @"/Applications/ruBooks.app/jpg.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"tiff"]) return @"/Applications/ruBooks.app/tiff.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"bmp"]) return @"/Applications/ruBooks.app/bmp.png";
  if ([[[path pathExtension] lowercaseString] isEqualToString:@"png"]) return @"/Applications/ruBooks.app/png.png";

  return nil;
}



@end
