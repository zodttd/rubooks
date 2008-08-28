#import "BooksApp.h"
#import "PreferencesController.h"
#import <UIKit/UIView-Geometry.h>
#import <CoreGraphics/CGFont.h>
//#include "dolog.h"
#include <stdio.h>

NSString *WebViewProgressEstimateChangedNotification;
@implementation AdView 
- (id)initWithFrame:(struct CGRect)frame{
	if ((self = [super initWithFrame: frame]) != nil)
	{
	  fileframe = frame;

  	scroller = [[UIScroller alloc] initWithFrame: CGRectMake(0.0f, 0.0f, fileframe.size.width, fileframe.size.height)];
  	[scroller setScrollingEnabled: NO];
  	[scroller setAdjustForContentSizeChange: YES];
  	[scroller setClipsSubviews: YES];
  	[scroller setAllowsRubberBanding: YES];
  	[scroller setDelegate: self];

  	[self addSubview: scroller];

  	web = [[UIWebDocumentView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, fileframe.size.width, fileframe.size.height)];
  	[web setTilingEnabled: YES];
  	[web setTileSize: CGSizeMake(fileframe.size.width,1000)];
  	[web setDelegate: self];
  	[web setAutoresizes: YES];
  	[web setEnabledGestures: 2];

  	mCoreWebView = [web webView];
  	[mCoreWebView setFrameLoadDelegate: self];
  	mFrame = [mCoreWebView mainFrame];

  	[mCoreWebView setPolicyDelegate: self];
  	[mCoreWebView setUIDelegate: self];
/*
  	nc = [NSNotificationCenter defaultCenter];
  	[nc addObserver:self selector:@selector(_progressChanged:) name:WebViewProgressEstimateChangedNotification object: mCoreWebView];
*/
  	[scroller addSubview: web];

  	[self loadURL: @"http://www.zodttd.com/ruBooks2.html"];
	}

	return self;
}

- (void)closeWebView
{
  [ scroller removeFromSuperview ];
}

- (void)loadWebView
{
  [self addSubview: scroller];
}

- (void)webView:(UIWebDocumentView *)sender willClickElement:(id)element {
  if ([[element localName] isEqualToString:@"img"])
  {
    do if ((element = [element parentNode]) == nil)
      return;
    while (![[element localName] isEqualToString:@"a"]);
  }
	if ( [ element respondsToSelector: @selector(absoluteLinkURL) ] ) { // check if it has the method needed to get the NSURL
		NSURL *url = [ [ element absoluteLinkURL ] retain ]; // if so, retain it.
		if( [ [ url scheme ] isEqualToString: @"http" ] || [ [ url scheme ] isEqualToString: @"https" ] || [ [ url scheme ] isEqualToString: @"ftp" ] ) { // check its scheme for http, https, ftp
			[ UIApp openURL: url ]; // open the url if it does.
		}
		[ url release ]; // clean up.
		url = nil; // tidy up.
	}
}

- (void) loadURL: (NSString*)URL
{
	if (URL == nil)
	{
		_URL = @"http://www.zodttd.com/ruBooks2.html";
	}
	else
	{
		_URL = [URL retain];
	}

	[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(loadRequest:) userInfo:nil repeats:NO];
}

- (void) loadRequest: (id)param
{
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];

	[web loadRequest: theRequest];
}

- (void) view: (id)v didDrawInRect: (CGRect)f duration: (float)d
{
	if (v == web)
	{
		[scroller setContentSize: [web bounds].size];
	}
}

- (void) view: (UIView*)v didSetFrame: (CGRect)f
{
	if (v == web)
	{
		[scroller setContentSize: CGSizeMake(f.size.width,f.size.height)];
	}
}

/*
// Receive a progress update message from the browser
- (void) _progressChanged: (NSNotification*)n
{
	if (![[n object] isLoading])
	{
		[nc removeObserver: self];
		
		[mTransView transition: 6 toView: scroller];
	}
}
*/

- (void)dealloc 
{
  [ scroller release ];
  [ web release ];
	[super dealloc];
}

@end

@implementation BooksApp
/*
   enum {
   kFACEUP = 0,
   kNORMAL = 1,	
   kUPSIDEDOWN = 2,
   kLANDL = 3,
   kLANDR = 4,
   kFACEDOWN = 6
   };
   */
- (void) applicationDidFinishLaunching: (id) unused
{
NSLog(@"Entering applicationDidFinishLaunching");

  // Only log if the log file already exists!
  if([[NSFileManager defaultManager] fileExistsAtPath:OUT_FILE]) {    
    freopen([OUT_FILE cString], "w", stdout);
    freopen([ERR_FILE cString], "w", stderr);
  }
	
	//investigate using [self setUIOrientation 3] that may alleviate for the need of a weirdly sized window
	NSString *recentFile;
	defaults = [BooksDefaultsController sharedBooksDefaultsController];
	//bcc rect to change for rotate90

	struct CGRect rect = 	[defaults fullScreenApplicationContentRect];

	doneLaunching = NO;

	transitionHasBeenCalled = NO;

	navbarsAreOn = YES;

	textViewNeedsFullText = NO;
	imageSplashed = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateToolbar:)
												 name:@"toolbarDefaultsChanged"
											   object:nil];

	window = [[UIWindow alloc] initWithContentRect: rect];
	[window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];
	struct CGSize progsize = [UIProgressIndicator defaultSizeForStyle:0];
	//Bcc: this positioning should be relative to the screen rect not to some arbitrary value
	//based on the size of the current gen iphone


	progressIndicator = [[UIProgressIndicator alloc] 
		initWithFrame:CGRectMake((rect.size.width-progsize.width)/2,
				(rect.size.height-progsize.height)/2,
				progsize.width, 
				progsize.height)];
	[progressIndicator setStyle:0];


	mainView = [[UIView alloc] initWithFrame: rect];
	[self setupNavbar];
	[self setupToolbar];

    [self showStatusBar];
	textView = [[EBookView alloc] 
		initWithFrame:
		CGRectMake(0, 0, rect.size.width, rect.size.height)];
	[self refreshTextViewFromDefaults];

	recentFile = [defaults fileBeingRead];
	readingText = [defaults readingText];


	transitionView = [[UITransitionView alloc] initWithFrame:
		CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height)];

	[window setContentView: mainView];
	//bcc rotation
	[self rotateApp];
	[mainView addSubview:transitionView];
	[mainView addSubview:navBar];
	[mainView addSubview:bottomNavBar];
	if (!readingText) 
		[bottomNavBar hide:YES];

	[textView setHeartbeatDelegate:self];

	[navBar setTransitionView:transitionView];
	[transitionView setDelegate:self];

	adView = [[AdView alloc] initWithFrame: CGRectMake(0, 48, 320, 432)];
	[mainView addSubview: adView ];
	
// TODO: INSERT START-UP LOGO HERE

//	NSString *coverart = [EBookImageView coverArtForBookPath:[defaults lastBrowserPath]];
//	imageSplashed = !(nil == coverart);
//	if (!imageSplashed)
//	{
//		coverart = [[NSBundle mainBundle] pathForResource:@"Default"
//												   ofType:@"png"];
		NSString *coverart = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"];
		[progressIndicator setStyle:![defaults inverted]];
//	}

	imageView = [[EBookImageView alloc] initWithContentsOfFile:coverart withinSize:rect.size];
	if (imageView != nil) [mainView addSubview:imageView];
	[mainView addSubview:progressIndicator];
	[progressIndicator startAnimation];


// COLEL: DISABLED HUD

	 if ([defaults scrollByVolumeButtons]) [self setSystemVolumeHUDEnabled:NO];

	 _autoScrollTimer = 0;
	 [defaults setAutoScrollEnabled:NO];

	 _SBAutoDimTime = 0;
	 _SBAutoLockTime = 0;
	 
	 
	/// FIXME just a test.
	/*
	   NSStringEncoding *enclist = malloc(500*sizeof(NSStringEncoding));
	   enclist = [NSString availableStringEncodings];
	   while (*enclist != 0)
	   {
	   GSLog(@"%u, %@",*enclist, [NSString localizedNameOfStringEncoding:*(enclist++)]);
	   }
	   free(enclist);
	   */
NSLog(@"Leaving applicationDidFinishLaunching");
}


- (void)finishUpLaunch
{
NSLog(@"Entering finishUpLaunch");
	NSString *recentFile = [defaults fileBeingRead];
	
	if (imageSplashed)
	{
		[self _dumpScreenContents:nil];
	//	NSString *defaultPath = [[NSBundle mainBundle] pathForResource:@"Default"
	//															ofType:@"png"];
		NSString * lPath = [NSHomeDirectory() stringByAppendingPathComponent:LIBRARY_PATH];
		if (![[NSFileManager defaultManager] fileExistsAtPath: lPath])
			[[NSFileManager defaultManager] createDirectoryAtPath:lPath attributes:nil];
		NSString *defaultPath = [NSHomeDirectory() stringByAppendingPathComponent:DEFAULT_REAL_PATH];
		NSData *nsdat = [NSData dataWithContentsOfFile:@"/foo_0.png"];
		[nsdat writeToFile:defaultPath atomically:YES];
		imageSplashed = NO;
	}
	UINavigationItem *tempItem = [[UINavigationItem alloc] initWithTitle:@"/var"];
	[navBar pushNavigationItem:tempItem withBrowserPath:[BooksDefaultsController defaultEBookPath]];

	NSString *tempString = [defaults lastBrowserPath];
	NSMutableArray *tempArray = [[NSMutableArray alloc] init]; 

	// COLEL

	if (![tempString isEqualToString:[BooksDefaultsController defaultEBookPath]])
	{
		[tempArray addObject:[NSString stringWithString:tempString]];
		while ((![(tempString = [tempString stringByDeletingLastPathComponent])
					isEqualToString:[BooksDefaultsController defaultEBookPath]]) && 
	  (![tempString isEqualToString:@"/"])) //sanity check
		{
			[tempArray addObject:[NSString stringWithString:tempString]];
		} // while
	} // if

	
	NSEnumerator *pathEnum = [tempArray reverseObjectEnumerator];
	NSString *curPath;  
	while (nil != (curPath = [pathEnum nextObject]))
	{
		UINavigationItem *tempItem = [[UINavigationItem alloc]
			initWithTitle:[curPath lastPathComponent]];
		[navBar pushNavigationItem:tempItem withBrowserPath:curPath];
		[tempItem release];
	}

	if (readingText)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:recentFile])
		{

			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[recentFile lastPathComponent] 
				stringByDeletingPathExtension]];
			int subchapter = [defaults lastSubchapterForFile:recentFile];
			float scrollPoint = (float) [defaults lastScrollPointForFile:recentFile
															inSubchapter:subchapter];

			[navBar pushNavigationItem:tempItem withView:textView];
			[textView loadBookWithPath:recentFile subchapter:subchapter];
			textViewNeedsFullText = NO;
			[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, scrollPoint)
										 animated:NO];
			[tempItem release];
			[navBar hide:NO];
			[bottomNavBar hide:NO];
		}
		else
		{  // Recent file has been deleted!  RESET!
			readingText = NO;
			[defaults setReadingText:NO];
			[defaults setFileBeingRead:@""];
			[defaults setLastBrowserPath:[BooksDefaultsController defaultEBookPath]];
			[defaults removePerFileDataForFile:recentFile];
		}
	}

	imageSplashed = NO;
	transitionHasBeenCalled = YES;


	[tempArray release];

	[navBar enableAnimation];
	[progressIndicator stopAnimation];
	[progressIndicator removeFromSuperview];
	[imageView removeFromSuperview];
	[imageView release];
	imageView = nil;
	

NSLog(@"Leaving finishUpLaunch");
}

- (void)heartbeatCallback:(id)unused
{
	if (!doneLaunching)
	{
		[self finishUpLaunch];
		doneLaunching = YES;
	}
	if ((textViewNeedsFullText) && ![transitionView isTransitioning])
	{
		[textView loadBookWithPath:[textView currentPath] subchapter:[defaults lastSubchapterForFile:[textView currentPath]]];
		textViewNeedsFullText = NO;
		[self updateStatusBar];
	}
	if ((!transitionHasBeenCalled)/* && ![transitionView isTransitioning]*/)
	{
		if ((textView != nil) && (defaults != nil))
		{
			//[self refreshTextViewFromDefaults];
		}
	}

// MOVE TO VIEW
	if ((readingText) && ([defaults autoScrollEnabled])) {
// MOVE TO SETTINGS
		int _autoScrollDelta[10]	= {1,  1, 1, 1, 1, 1, 1, 2, 2, 2 };
		int _autoScrollThreshold[10]	= {16, 8, 6, 4, 2, 1, 0, 2, 1, 0 };
		int _autoScrollSpeed = [defaults autoScrollSpeed];
		    if (_autoScrollSpeed > 10)	_autoScrollSpeed = 10;
		    if (_autoScrollSpeed < 1)	_autoScrollSpeed = 1;

	       if (_autoScrollThreshold[_autoScrollSpeed-1] <= _autoScrollTimer++) {
                 _autoScrollTimer = 0;
 		         [textView scrollDown:_autoScrollDelta[_autoScrollSpeed-1]];
				 [self updateStatusBar];
	       }       
        }
}

- (void)hideNavbars
{
	GSLog(@"hideNavbars");
	struct CGRect rect = [defaults fullScreenApplicationContentRect];
	[textView setFrame:rect];
	[navBar hide:NO];
	[bottomNavBar hide:NO];
	[self hideSlider];
	[self showStatusBar];
}

- (void)toggleNavbars
{
	GSLog(@"toggleNavbars");
	[navBar toggle];
	[bottomNavBar toggle];
	if (nil == scrollerSlider)  {
		[self showSlider:true];
                [defaults setAutoScrollEnabled:NO];
				[self restoreLock];
        } else {
		[self hideSlider];
	}
	[self showStatusBar];
}

- (void)showStatusBar
{
	if (nil != statusBar)
	{
		[statusBar removeFromSuperview];
		[statusBar autorelease];
		statusBar = nil;
	}
	
	statusBar = [[UITextLabel alloc] initWithFrame:CGRectMake([defaults fullScreenApplicationContentRect].size.width-45.0f, 0.0f, 45.0f, 24.0f)];
			CGColorSpaceRef rgbColorSpace =   (CGColorSpaceRef)[(id)CGColorSpaceCreateDeviceRGB() autorelease];
			float fRgbaF[4] = {0.0f, 0.2f, 1.0f, 0.2f};
// TODO: EITHER GET CURRENT TEXT COLOR OR DAY/NIGHT MODE
				  fRgbaF[0] = [defaults color:0 component:0]; 
				  fRgbaF[1] = [defaults color:0 component:1]; 
				  fRgbaF[2] = [defaults color:0 component:2]; 
				  
			float fRgbaB[4] = {0.0f, 0.0f, 0.0f, 0.0f};
	[statusBar setText : @""];
	//[statusBar setColor : (CGColorRef)[(id)CGColorCreate(rgbColorSpace, fRgbaF) autorelease]];
	//[statusBar setBackgroundColor : (CGColorRef)[(id)CGColorCreate(rgbColorSpace, fRgbaB) autorelease]];
	[statusBar setAlpha:1];
	[mainView addSubview: statusBar];	
	[self updateStatusBar];
	NSLog(@"Leaving showStatusBar");
}

- (void) setStatusBarProgress:(int)value
{
	[statusBar setText : [NSString stringWithFormat: @"%d%%", value]];
}

- (void) updateStatusBar
{
/*	CGRect lDefRect = [defaults fullScreenApplicationContentRect];
	CGRect theWholeShebang = [[textView _webView] frame];
	CGRect visRect = [textView visibleRect];
	int endPos = (int)theWholeShebang.size.height - lDefRect.size.height;
	if (endPos == 0) return;
	
    int value = floor(100 * visRect.origin.y / endPos);
*/
  int value = floor(100*[textView absolutePosition]);
    [self setStatusBarProgress:value];
}


- (void)showSlider:(BOOL)withAnimation
{
	GSLog(@"showSlider");
	CGRect rect = CGRectMake(0, 48, [defaults fullScreenApplicationContentRect].size.width, 48);
	CGRect lDefRect = [defaults fullScreenApplicationContentRect];
	if (nil != scrollerSlider)
	{
		[scrollerSlider removeFromSuperview];
		[scrollerSlider autorelease];
		scrollerSlider = nil;
	}
	else
	{
	}
	scrollerSlider = [[UIOldSliderControl alloc] initWithFrame:rect];
	[mainView addSubview:scrollerSlider];
	CGRect theWholeShebang = [[textView _webView] frame];
	CGRect visRect = [textView visibleRect];
	//GSLog(@"visRect: x=%f, y=%f, w=%f, h=%f", visRect.origin.x, visRect.origin.y, visRect.size.width, visRect.size.height);
	//GSLog(@"theWholeShebang: x=%f, y=%f, w=%f, h=%f", theWholeShebang.origin.x, theWholeShebang.origin.y, theWholeShebang.size.width, theWholeShebang.size.height);
	int endPos = (int)theWholeShebang.size.height - lDefRect.size.height;
	[scrollerSlider setMinValue:0.0];
	[scrollerSlider setMaxValue:(float)endPos];
	[scrollerSlider setValue:visRect.origin.y];
	float backParts[4] = {0, 0, 0, .5};
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	//[scrollerSlider setBackgroundColor: CGColorCreate( colorSpace, backParts)];
	[scrollerSlider addTarget:self action:@selector(handleSlider:) forEvents:7];
	[scrollerSlider setAlpha:0];
	//  [scrollerSlider setShowValue:YES];
	UIImage *img = [UIImage applicationImageNamed:@"ReadIndicator.png"];
	[scrollerSlider setMinValueImage:img];
	[scrollerSlider setMaxValueImage:img];
	if (withAnimation)
	{
		if (animator != nil)
			[animator release];
		animator = [[UIAnimator alloc] init];
		if (alpha != nil)
			[alpha release];
		alpha = [[UIAlphaAnimation alloc] initWithTarget:scrollerSlider];
		[alpha setStartAlpha:0];
		[alpha setEndAlpha:1];
		[animator addAnimation:alpha withDuration:0.25 start:YES];
	}
	else
	{
		[scrollerSlider setAlpha:1];
	}

	//[animator autorelease];
	//[alpha autorelease];
}

- (void)hideSlider
{
	if (scrollerSlider != nil)
	{
		if (animator != nil)
			[animator release];
		animator = [[UIAnimator alloc] init];
		if (alpha != nil)
			[alpha release];
		alpha = [[UIAlphaAnimation alloc] initWithTarget:scrollerSlider];
		[alpha setStartAlpha:1];
		[alpha setEndAlpha:0];
		[animator addAnimation:alpha withDuration:0.1 start:YES];
		[scrollerSlider release];
		scrollerSlider = nil;
	}
}

- (void)handleSlider:(id)sender
{
	if (scrollerSlider != nil)
	{
		CGPoint scrollness = CGPointMake(0, [scrollerSlider value]);
		[textView scrollPointVisibleAtTopLeft:scrollness animated:NO];
	}
}

- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file 
{

NSLog(@"TEST: Entering fileBrowser.fileSelected");

	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if ([fileManager fileExistsAtPath:file isDirectory:&isDir] && isDir)
	{
		UINavigationItem *tempItem = [[UINavigationItem alloc]
			initWithTitle:[file lastPathComponent]];
		[navBar pushNavigationItem:tempItem withBrowserPath:file];
		[tempItem release];
	}
	else // not a directory
	{
		BOOL sameFile;
		NSString *ext = [[file pathExtension] lowercaseString];

// TODO: UNIFIED APPROACH TO EXTENSIONS - SEE NSString ADDITIONS

//		BOOL isPicture = ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"]);
                BOOL isPicture = NO;  

		BOOL isSafariFile = (

// TODO: MULTIMEDIA FILES
//                                     [ext isEqualToString:@"mp3"] || 
//                                     [ext isEqualToString:@"avi"] || 

                                     [ext isEqualToString:@"png"] || 
                                     [ext isEqualToString:@"jpg"] || 
                                     [ext isEqualToString:@"gif"] || 
                                     [ext isEqualToString:@"tiff"] || 
                                     [ext isEqualToString:@"bmp"] || 

                                     [ext isEqualToString:@"pdf"] || 
                                     [ext isEqualToString:@"doc"] || 
                                     [ext isEqualToString:@"ppt"] || 
                                     [ext isEqualToString:@"xls"]
                                    );
		if (isPicture)
		{
			if (nil != imageView)
				[imageView release];
			imageView = [[EBookImageView alloc] initWithContentsOfFile:file];
			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[file lastPathComponent]
				stringByDeletingPathExtension]];
			[defaults removePerFileDataForFile:file];
			[navBar pushNavigationItem:tempItem withView:imageView];
			[tempItem release];
		} else if (isSafariFile) {
// WORKING CODE

  			sc = [[SafariController alloc] initWithAppController:self file:file];
			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[file lastPathComponent]
				stringByDeletingPathExtension]];
			[navBar pushNavigationItem:tempItem withView:[sc view]];
 			[transitionView transition:1 toView:[sc view]];
//			[sc reloadData];
			[tempItem release];

/*

			if (nil != safariView)
				[safariView release];
			safariView = [[SafariView alloc] initWithContentsOfFile:fileURL];
			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[file lastPathComponent]
				stringByDeletingPathExtension]];
			[defaults removePerFileDataForFile:file]; 
			[navBar pushNavigationItem:tempItem withView:safariView]; // handle same file
			[tempItem release];
           		[safariView setNeedsDisplay];
           		[window setContentView: safariView];

*/

/*

			readingText = YES;
			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[file lastPathComponent]
				stringByDeletingPathExtension]];
			sameFile = [[textView currentPath] isEqualToString:file];
			[navBar pushNavigationItem:tempItem withView:safariView];
			[safariView loadBookWithPath:file subchapter:[defaults lastSubchapterForFile:file]];
			textViewNeedsFullText = NO;
			

			[tempItem release];

                        [navBar hide:NO]; // updateNavbar
*/


		} else //text or HTML file
		{
			readingText = YES;
			UINavigationItem *tempItem = [[UINavigationItem alloc]
				initWithTitle:[[file lastPathComponent]
				stringByDeletingPathExtension]];
			sameFile = [[textView currentPath] isEqualToString:file];
			[navBar pushNavigationItem:tempItem withView:textView];
			if (!sameFile)
				// Slight optimization.  If the file is already loaded,
				// don't bother reloading.
			{
				int subchapter = [defaults lastSubchapterForFile:file];
				float scrollPoint = (float) [defaults lastScrollPointForFile:file
																inSubchapter:subchapter];
				BOOL didLoadAll = NO;
				CGRect rect = [defaults fullScreenApplicationContentRect];
				int numScreens = ((int) scrollPoint / rect.size.height) + 1;  // how many screens down are we?
				int numChars = numScreens * (265000/([textView textSize]*[textView textSize]));
// COLEL TEST - FORCED FULL LOAD - LATER CHANGE ONLY FOR CHAPTERED HTML
//				[textView loadBookWithPath:file
//							 numCharacters:numChars
//								didLoadAll:&didLoadAll
//								subchapter:subchapter];
		[textView loadBookWithPath:file subchapter:[defaults lastSubchapterForFile:file]];
		textViewNeedsFullText = NO;
		
		[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, scrollPoint)
											 animated:NO];

		
		
//				textViewNeedsFullText = !didLoadAll;
			}

			[tempItem release];
		}
		if (isPicture)
		{
			[navBar show];
			[bottomNavBar hide:YES];
		}
		else
		{
			[navBar hide:NO];
			if (![defaults toolbar])
				[bottomNavBar show];
			else
				[bottomNavBar hide:NO];
		}
	}
NSLog(@"TEST: Leaving fileBrowser.fileSelected");
}

- (void)textViewDidGoAway:(id)sender
{
NSLog(@"Entering textViewDidGoAway");

	//  GSLog(@"textViewDidGoAway start...");
	struct CGRect  selectionRect = [textView visibleRect];
	int            subchapter    = [textView getSubchapter];
	NSString      *filename      = [textView currentPath];

if (filename) { 
		[defaults setLastScrollPoint: (unsigned int) selectionRect.origin.y forSubchapter:subchapter forFile:filename];
		[defaults setLastSubchapter:subchapter forFile:filename];
		[[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE object:[textView currentPath]];
              }
	readingText = NO;
	[bottomNavBar hide:YES];
	if (scrollerSlider != nil) [self hideSlider];
NSLog(@"Leaving textViewDidGoAway");
	//  GSLog(@"end.\n");
}

- (void)cleanUpBeforeQuit
{
	if (!readingText ||
			(nil == [EBookImageView coverArtForBookPath:[textView currentPath]]))
	{
		NSData *defaultData;
		NSString * lPath = [NSHomeDirectory() stringByAppendingPathComponent:LIBRARY_PATH];
		if (![[NSFileManager defaultManager] fileExistsAtPath: lPath])
			[[NSFileManager defaultManager] createDirectoryAtPath:lPath attributes:nil];
		if ([defaults inverted])
		{
			defaultData = [NSData dataWithContentsOfFile:
				  [[NSBundle mainBundle] pathForResource:@"Default_dark"
												  ofType:@"png"]];
		}
		else
		{
			defaultData = [NSData dataWithContentsOfFile:
				  [[NSBundle mainBundle] pathForResource:@"Default_light"
												  ofType:@"png"]];
		}
		NSString *defaultPath = [NSHomeDirectory() stringByAppendingPathComponent:DEFAULT_REAL_PATH];
		[defaultData writeToFile:defaultPath atomically:YES];
	}
	struct CGRect  selectionRect;
	int            subchapter = [textView getSubchapter];
	NSString      *filename   = [textView currentPath];

	[defaults setFileBeingRead:filename];
	selectionRect = [textView visibleRect];
	[defaults setLastScrollPoint: (unsigned int)selectionRect.origin.y
				   forSubchapter: subchapter
						 forFile: filename];
	[defaults setLastSubchapter:subchapter forFile:filename];
	[defaults setReadingText:readingText];
	[defaults setLastBrowserPath:[navBar topBrowserPath]];
	[defaults synchronize];
}

- (void) applicationWillSuspend
{
	[self cleanUpBeforeQuit];
}

- (void)applicationWillTerminate
{
	[self cleanUpBeforeQuit];
}

- (void)embiggenText:(UINavigationButton *)button
{
	if (![button isSelected]) // mouse up events only, kids!
	{
		CGRect rect = [[textView _webView] frame];
		[textView embiggenText];
		if (scrollerSlider != nil)
		{
			float maxval = rect.size.height;
			float val = [scrollerSlider value];
			float percentage = val / maxval;
			rect = [[textView _webView] frame];
			[scrollerSlider setMaxValue:rect.size.height];
			[scrollerSlider setValue:(rect.size.height * percentage)];
		}
		[defaults setTextSize:[textView textSize]];
	}
}

- (void)ensmallenText:(UINavigationButton *)button
{
	if (![button isSelected]) // mouse up events only, kids!
	{
		CGRect rect = [[textView _webView] frame];
		[textView ensmallenText];
		if (scrollerSlider != nil)
		{
			float maxval = rect.size.height;
			float val = [scrollerSlider value];
			float percentage = val / maxval;
			rect = [[textView _webView] frame];
			[scrollerSlider setMaxValue:rect.size.height];
			//[scrollerSlider setValue:oldRect.origin.y];
			[scrollerSlider setValue:(rect.size.height * percentage)];
		}
		[defaults setTextSize:[textView textSize]];
	}
}

- (void)invertText:(UINavigationButton *)button 
{
	if (![button isSelected]) // mouse up events only, kids!
	{
		textInverted = !textInverted;
		[textView invertText:textInverted];
		[defaults setInverted:textInverted];
		[self toggleStatusBarColor];
		struct CGRect rect = [defaults fullScreenApplicationContentRect];
		[textView setFrame:rect];
	}	
}

- (void)TOC:(UINavigationButton *)button 
{
	if (![button isSelected])
	{
        	[self hideNavbars];
  		TOCController *toc = [[TOCController alloc] initWithAppController:self chapHTML:nil];
 		[transitionView transition:1 toView:[toc view]];
		[toc reloadData];
    }
}

- (void)autoScroll:(UINavigationButton *)button 
{
	if (![button isSelected])
	{  
		[defaults setAutoScrollEnabled:YES];
		[self hideNavbars];
		[self disableLock];
	}
}

- (void)searchText:(UINavigationButton *)button 
{
	if (![button isSelected])
	{  

	if (alertSheet != nil) [alertSheet dealloc];
alertSheet = [[UIActionSheet alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
[ alertSheet setTitle:@"Search" ];
[ alertSheet setDelegate: self ]; 
[ alertSheet setAlertSheetStyle: 2 ];
 NSString *previousString = @"";
  previousString = [textView lastSearchString];
//  [NSString stringWithString:[textView lastSearchString];
 [alertSheet addTextFieldWithValue: previousString label: @""];
//[[alertSheet textField] setPreferredKeyboardType: 0];
[ alertSheet addButtonWithTitle:@"Find" ];
[ alertSheet addButtonWithTitle:@"Find next" ];
[ alertSheet addButtonWithTitle:@"Cancel" ]; 
[alertSheet popupAlertAnimated: YES];
[alertSheet setTag: 1];
//[ alertSheet presentSheetInView: textView ];
		
		}
}

- (void) alertSheet: (UIActionSheet *)sheet buttonClicked: (int)button
{
	switch (button) {
		case 1: {
			NSString *value = [[sheet textFieldAtIndex: 0] text];
			[textView find:value]; // ONLY DISMISS ALERTSHEET IF RETURNS YES
			break;
		}
		case 2: {
			NSString *value = [[sheet textFieldAtIndex: 0] text];
			[textView findNext:value]; // ONLY DISMISS ALERTSHEET IF RETURNS YES
			break;
		}
	}
	[sheet dismissAnimated: YES];
	[self hideSlider];
	[self showSlider:NO];
	[scrollerSlider setNeedsDisplay];
}


- (void)pageDown:(UINavigationButton *)button 
{
	if (![button isSelected])
	{
		[textView pageDownWithTopBar:![defaults navbar]
						   bottomBar:![defaults toolbar]];
	}	
}

- (void)pageUp:(UINavigationButton *)button 
{
	if (![button isSelected])
	{
		[textView pageUpWithTopBar:![defaults navbar]
						 bottomBar:![defaults toolbar]];
	}	
}

- (void)chapForward:(UINavigationButton *)button 
{
	GSLog(@"chapForward start");
	if (![button isSelected])
	{
		if ([textView gotoNextSubchapter] == YES)
		{
			/*
			   CGRect frame    = [[textView _webView] frame];
			   CGRect viewable = [textView visibleRect];
			   float endPos    = frame.size.height - viewable.size.height;
			   [scrollerSlider setMinValue:0.0];
			   [scrollerSlider setMaxValue:endPos];
			   [scrollerSlider setValue:viewable.origin.y];
			   */ // that dance isn't needed if we just hide the slider :)
			[self hideSlider];
			[navBar hide:NO];
			[bottomNavBar hide:NO];
		}

		else
		{
			NSString *nextFile = [[navBar topBrowser] fileAfterFileNamed:[textView currentPath]];
			if ((nil != nextFile) && [nextFile isReadableTextFilePath])
			{
				[self hideSlider];
				EBookView *tempView = textView;
				struct CGRect visRect = [tempView visibleRect];
				int            subchapter = [tempView getSubchapter];
				NSString      *filename   = [tempView currentPath];

				[defaults setLastScrollPoint:(unsigned int)visRect.origin.y
							   forSubchapter:subchapter
									 forFile:filename];
				[defaults setLastSubchapter:subchapter forFile:filename];

				[[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE
																	object:[tempView currentPath]];
//				[textView autorelease];
				textView = [[EBookView alloc] initWithFrame:[tempView frame]];
				[textView setHeartbeatDelegate:self];

				UINavigationItem *tempItem = 
					[[UINavigationItem alloc] initWithTitle:
					[[nextFile lastPathComponent] 
					stringByDeletingPathExtension]];
				[navBar pushNavigationItem:tempItem withView:textView];
				[self refreshTextViewFromDefaults];

				subchapter = [defaults lastSubchapterForFile:nextFile];
				int lastPt = [defaults lastScrollPointForFile:nextFile inSubchapter:subchapter]; BOOL didLoadAll = NO; 
				CGRect rect = [defaults fullScreenApplicationContentRect];
				int numScreens = (lastPt / rect.size.height) + 1;  // how many screens down are we?  
				int numChars = numScreens * (265000/([textView textSize]*[textView textSize]));  //bcc I wonder what is 265000 but it has to be replaced
				[textView loadBookWithPath:nextFile numCharacters:numChars
								didLoadAll:&didLoadAll subchapter:subchapter];
				[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, (float) lastPt)
											 animated:NO];
				textViewNeedsFullText = !didLoadAll;
				[tempItem release];
				[tempView autorelease];
				[self updateStatusBar];
			}
		}
	}	
	[self updateStatusBar];
	GSLog(@"chapForward end");
}

- (void)chapBack:(UINavigationButton *)button 
{
	if (![button isSelected])
	{
		if ([textView gotoPreviousSubchapter] == YES)
		{
			/*
			   CGRect frame    = [[textView _webView] frame];
			   CGRect viewable = [textView visibleRect];
			   float endPos    = frame.size.height - viewable.size.height;
			   [scrollerSlider setMinValue:0.0];
			   [scrollerSlider setMaxValue:endPos];
			   [scrollerSlider setValue:viewable.origin.y];
			   */ // that dance isn't needed if we just hide the slider :)
			[self hideSlider];
			[navBar hide:NO];
			[bottomNavBar hide:NO];
		}

		else
		{
			NSString *prevFile = [[navBar topBrowser] fileBeforeFileNamed:[textView currentPath]];
			if ((nil != prevFile) && [prevFile isReadableTextFilePath])
			{
				[self hideSlider];
				EBookView *tempView = textView;
				struct CGRect visRect = [tempView visibleRect];
				int            subchapter = [tempView getSubchapter];
				NSString      *filename   = [tempView currentPath];

				[defaults setLastScrollPoint: (unsigned int) visRect.origin.y
							   forSubchapter: subchapter
									 forFile: filename];
				[defaults setLastSubchapter:subchapter forFile:filename];

				[[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE
																	object:[tempView currentPath]];
				textView = [[EBookView alloc] initWithFrame:[tempView frame]];
				[textView setHeartbeatDelegate:self];
				UINavigationItem *tempItem = 
					[[UINavigationItem alloc] initWithTitle:
					[[prevFile lastPathComponent] 
					stringByDeletingPathExtension]];

				[navBar pushNavigationItem:tempItem withView:textView reverseTransition:YES];
				[self refreshTextViewFromDefaults];
				//[progressHUD show:YES];

				subchapter = [defaults lastSubchapterForFile:prevFile];
				int lastPt = [defaults lastScrollPointForFile:prevFile
												 inSubchapter:subchapter];
				[textView loadBookWithPath:prevFile subchapter:subchapter];
				[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, (float) lastPt)
											 animated:NO];
				//[progressHUD show:NO];
				[tempItem release];
				[tempView autorelease];
			}
		}
	}	
			[self updateStatusBar];
}

- (void)chapJump:(int)chap 
{
	[transitionView transition:2 toView:textView];

if (chap >= 0) {
		[textView setSubchapter:chap];
}
		[self hideSlider];
		[navBar hide:NO];
		[bottomNavBar hide:NO];
		[self updateStatusBar];
}



// CHANGED: Moved navbar and toolbar setup here from applicationDidFinishLaunching

- (void)setupNavbar
{

	struct CGRect rect = [defaults fullScreenApplicationContentRect];
	[navBar release]; //BCC in case this is not the first time this method is called
	navBar = [[HideableNavBar alloc] initWithFrame:
		CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f)];
	[navBar setBarStyle:1];
	
	[navBar setDelegate:self];
	[navBar setBrowserDelegate:self];
	[navBar setExtensions:[NSArray arrayWithObjects:@"txt", @"htm", @"html", @"pdb", @"jpg", @"png", @"gif", @"fb2", @"zip", @"pdf", @"doc", @"ppt", @"xls" ,@"jpg",@"gif",@"bmp",@"tiff",@"png",nil]];
	[navBar hideButtons];

	[navBar disableAnimation];
	float lMargin = 45.0f;
	[navBar setRightMargin:lMargin];
	//position the prefsButton in the margin
	//for some reason cannot click on the button when it is there
	prefsButton = [self toolbarButtonWithName:@"prefs" rect:CGRectMake(rect.size.width-lMargin,9,40,30) selector:@selector(showPrefs:) flipped:NO];
	//prefsButton = [self toolbarButtonWithName:@"prefs" rect:CGRectMake(275,9,40,30) selector:@selector(showPrefs:) flipped:NO];

	[navBar addSubview:prefsButton];
	
	[ navBar showButtonsWithLeftTitle:@"Continue"
       rightTitle:nil leftBack: NO
  ];
}

- (void)navigationBar:(UINavigationBar *)navbar buttonClicked:(int)button {
  static int adViewRemoved = 0;
  if(!adViewRemoved)
  {
    adViewRemoved = 1;
    [ navBar showButtonsWithLeftTitle:nil
         rightTitle:nil leftBack: NO
    ];
    [ adView removeFromSuperview ];
    [ adView release ];
  }
}
- (void)setupToolbar
{

	struct CGRect rect = [defaults fullScreenApplicationContentRect];
	[bottomNavBar release]; //BCC in case this is not the first time this method is called
	bottomNavBar = [[HideableNavBar alloc] initWithFrame:
		CGRectMake(rect.origin.x, rect.size.height - 48.0f, 
				rect.size.width, 48.0f)];

//	[bottomNavBar setBarStyle:0];
	[bottomNavBar setBarStyle:2];	
	[bottomNavBar setDelegate:self];


// TODO: 90-degree layout, write with flipped?x:y style - but left/right flipped
                                               
	if ([defaults flipped]) {
		rotateButton = [self toolbarButtonWithName:@"rotate" rect:CGRectMake(320-5-30,9,30,30) selector:@selector(rotateButtonCallback:) flipped:NO];
		invertButton = [self toolbarButtonWithName:@"inv" rect:CGRectMake(320-45-30,9,30,30) selector:@selector(invertText:) flipped:NO];

		leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(320-195-40,9,40,30) selector:@selector(chapBack:) flipped:NO];
		autoScrollButton = [self toolbarButtonWithName:@"down" rect:CGRectMake(320-140-40,9,40,30) selector:@selector(autoScroll:) flipped:NO];
		rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(320-85-40,9,40,30) selector:@selector(chapForward:) flipped:NO];

		searchButton = [self toolbarButtonWithName:@"search" rect:CGRectMake(320-245-30,9,30,30) selector:@selector(searchText:) flipped:NO];
		tocButton = [self toolbarButtonWithName:@"toc" rect:CGRectMake(320-285-40,9,40,30) selector:@selector(TOC:) flipped:NO];

// DISABLED BUTTONS
		minusButton = [self toolbarButtonWithName:@"emsmall" rect:CGRectMake(235,9,40,30) selector:@selector(ensmallenText:) flipped:NO];
		plusButton = [self toolbarButtonWithName:@"embig" rect:CGRectMake(275,9,40,30) selector:@selector(embiggenText:) flipped:NO];
		downButton = [self toolbarButtonWithName:@"down" rect:CGRectMake(5,9,40,30) selector:@selector(pageDown:) flipped:YES];
		upButton = [self toolbarButtonWithName:@"up" rect:CGRectMake(45,9,40,30) selector:@selector(pageUp:) flipped:YES];

	} else {
		rotateButton = [self toolbarButtonWithName:@"rotate" rect:CGRectMake(5,9,30,30) selector:@selector(rotateButtonCallback:) flipped:NO];
		invertButton = [self toolbarButtonWithName:@"inv" rect:CGRectMake(45,9,30,30) selector:@selector(invertText:) flipped:NO];
		
		leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(85,9,40,30) selector:@selector(chapBack:) flipped:NO];
		autoScrollButton = [self toolbarButtonWithName:@"down" rect:CGRectMake(140,9,40,30) selector:@selector(autoScroll:) flipped:NO];
		rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(195,9,40,30) selector:@selector(chapForward:) flipped:NO];

		searchButton = [self toolbarButtonWithName:@"search" rect:CGRectMake(245,9,30,30) selector:@selector(searchText:) flipped:NO];
		tocButton = [self toolbarButtonWithName:@"toc" rect:CGRectMake(285,9,30,30) selector:@selector(TOC:) flipped:NO];

// DISABLED BUTTONS
		minusButton = [self toolbarButtonWithName:@"emsmall" rect:CGRectMake(5,9,40,30) selector:@selector(ensmallenText:) flipped:NO];
		plusButton = [self toolbarButtonWithName:@"embig" rect:CGRectMake(45,9,40,30) selector:@selector(embiggenText:) flipped:NO];
		upButton = [self toolbarButtonWithName:@"up" rect:CGRectMake(235,9,40,30) selector:@selector(pageUp:) flipped:NO];
		downButton = [self toolbarButtonWithName:@"down" rect:CGRectMake(275,9,40,30) selector:@selector(pageDown:) flipped:NO];
	}

//	[bottomNavBar addSubview:minusButton];
//	[bottomNavBar addSubview:plusButton];
	[bottomNavBar addSubview:invertButton];
	[bottomNavBar addSubview:rotateButton];

	if ([defaults chapternav]) {
		[bottomNavBar addSubview:leftButton];
		[bottomNavBar addSubview:rightButton];
	}
/*
	if ([defaults pagenav]) {	
		[bottomNavBar addSubview:upButton];
		[bottomNavBar addSubview:downButton];
	}
*/
	[bottomNavBar addSubview:tocButton];
	[bottomNavBar addSubview:autoScrollButton];
	[bottomNavBar addSubview:searchButton];



}

- (UINavigationButton *)toolbarButtonWithName:(NSString *)name rect:(struct CGRect)rect selector:(SEL)selector flipped:(BOOL)flipped 
{
  
	UINavigationButton	*button = [[UINavigationButton alloc] initWithFrame:rect];

	[button setAutosizesToFit:NO];
	[button setImage:[self navBarImage:[NSString stringWithFormat:@"%@_up",name] flipped:flipped] forState:0];
	[button setImage:[self navBarImage:[NSString stringWithFormat:@"%@_down",name] flipped:flipped] forState:1];
	//[button setDrawContentsCentered:YES];
	[button addTarget:self action:selector forEvents: (255)];
//	[button setNavBarButtonStyle:0];
	[button setBarStyle:0];
	
	//[button setBackgroundImage:nil];
	//[button setPressedBackgroundImage:nil];
	[button setShowPressFeedback:YES];
	//bcc this complains about an invalid context, it seems to work fine without anyway
	//	[button drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
	[button setEnabled:YES];
	
	return button;
}

- (UIImage *)navBarImage:(NSString *)name flipped:(BOOL)flipped
{
	NSBundle *bundle = [NSBundle mainBundle];
	imgPath = [bundle pathForResource:name ofType:@"png"];
	buttonImg = [[UIImage alloc]initWithContentsOfFile:imgPath];
	if (flipped) [buttonImg setOrientation:4];
	return buttonImg;
}

- (void)updateNavbar
{
  
	CGRect rect = [defaults fullScreenApplicationContentRect];
	[navBar setFrame: 	CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48.0f)];
	float lMargin = 45.0f;
	[prefsButton setFrame:CGRectMake(rect.size.width-lMargin,9,40,30) ];
}

- (void)updateToolbar:(NSNotification *)notification
{
  
	GSLog(@"%s Got toolbar update notification.", _cmd);
	BOOL lBottomBarHidden = [bottomNavBar hidden];
	[bottomNavBar removeFromSuperview];
	[self setupToolbar];
	[mainView addSubview:bottomNavBar];
	if (lBottomBarHidden)
		[bottomNavBar hide:NO];
}

- (void)setTextInverted:(BOOL)b
{
	textInverted = b;
}

- (void)showPrefs:(UINavigationButton *)button
{
	if (![button isSelected]) // mouseUp only
	{
		GSLog(@"Showing Preferences View");
		PreferencesController *prefsController = [[PreferencesController alloc] initWithAppController:self];
		[prefsButton setEnabled:false];
		[prefsController showPreferences];
	}
}

/* 
- (void)showTOC:(UINavigationButton *)button
{
	if (![button isSelected]) // mouseUp only
	{
		GSLog(@"Showing TOC");
//		ChapterTable *chapterTable = [[ChapterTable alloc] initWithAppController:self];
		[prefsButton setEnabled:false];
		[prefsController showPreferences];
	}
}
*/


- (UIWindow *)appsMainWindow
{
	return window;
}

- (void)anotherApplicationFinishedLaunching:(struct __GSEvent *)event
{
  
	[self applicationWillSuspend];
}

- (void)refreshTextViewFromDefaults
{
	[self refreshTextViewFromDefaultsToolbarsOnly:NO];
}

- (void)refreshTextViewFromDefaultsToolbarsOnly:(BOOL)toolbarsOnly
{
NSLog(@"Entering refreshTextViewFromDefaultsToolbarsOnly");

	float scrollPercentage;
	if (!toolbarsOnly)
	{
		[textView setTextSize:[defaults textSize]];
		textInverted = [defaults inverted];
		[textView invertText:textInverted];
		struct CGRect overallRect = [[textView _webView] frame];
		//GSLog(@"overall height: %f", overallRect.size.height);
		struct CGRect visRect = [textView visibleRect];
		scrollPercentage = visRect.origin.y / overallRect.size.height;
		//GSLog(@"scroll percent: %f",scrollPercentage);
		
		CGFontRef font; 
		font = CGFontCreateWithFontName([defaults textFont]);
		if (CGFontGetUnitsPerEm(font) > 0) {
			_scrollRatio  = CGFontGetAscent(font);
			_scrollRatio -= CGFontGetDescent(font);
			_scrollRatio += CGFontGetLeading(font);			
			_scrollRatio /= CGFontGetUnitsPerEm(font);
		}
		textView->_scrollRatio = _scrollRatio; // MAKE IT A FUNCTION
		NSLog(@"scrollRation: %f ",_scrollRatio);
/*        NSLog(@"***** Leading : %d",CGFontGetLeading(CGFontCreateWithFontName([defaults textFont])));		
        NSLog(@"***** CapHeight : %d",CGFontGetCapHeight(CGFontCreateWithFontName([defaults textFont])));		
        NSLog(@"***** Ascent : %d",CGFontGetAscent(CGFontCreateWithFontName([defaults textFont])));	
        NSLog(@"***** Descent : %d",CGFontGetDescent(CGFontCreateWithFontName([defaults textFont])));			
        NSLog(@"***** XHeight : %d",CGFontGetXHeight(CGFontCreateWithFontName([defaults textFont])));
	NSLog(@"***** UnitsPerEm : %d",CGFontGetUnitsPerEm(CGFontCreateWithFontName([defaults textFont])));
*/		
		CGFontRelease(font);
		
		//[textView setTextFont:[defaults textFont]];
		

		[self toggleStatusBarColor];

	}
	if (readingText)
	{  // Let's avoid the weird toggle behavior.
		[navBar hide:NO];
		[bottomNavBar hide:NO];
		[self hideSlider];
	}
	else // not reading text
	{
		[bottomNavBar hide:YES];
	}

	if (![defaults navbar])
		[textView setMarginTop:48];
	else
		[textView setMarginTop:0];
	if (![defaults toolbar])
		[textView setBottomBufferHeight:48];
	else
		[textView setBottomBufferHeight:0];
	if (!toolbarsOnly)
	{
		struct CGRect rect = [defaults fullScreenApplicationContentRect];
		//	[textView loadBookWithPath:[textView currentPath]];
		[textView setFrame:rect];
		struct CGRect overallRect = [[textView _webView] frame];
		//GSLog(@"overall height: %f", overallRect.size.height);
		struct CGPoint thePoint = CGPointMake(0, (scrollPercentage * overallRect.size.height));
		[textView scrollPointVisibleAtTopLeft:thePoint];
	}
NSLog(@"Leaving refreshTextViewFromDefaultsToolbarsOnly");
}

- (NSString *)currentBrowserPath
{
	return [[navBar topBrowser] path];
}

- (void)toggleStatusBarColor 	// Thought this might be a nice touch
//TODO: This looks weird with the navbars down.  Perhaps we should change
//the navbars to the black type?  Or have the status bar be black only
//when the top navbar is hidden?  Also I'd prefer to have the status
//bar white when in the browser view, since the browser is white.
{
	int lOrientation = 0;
	if ([defaults isRotate90])
		lOrientation = 90;
	//GSLog(@"toggleStatusBarColor Orientation =%d", lOrientation);
	if ([defaults inverted]) {
		[self setStatusBarMode:3 orientation:lOrientation duration:0.25];
	} else {
		[self setStatusBarMode:0 orientation:lOrientation duration:0.25];
	}
}

- (void) dealloc
{
	[navBar release];
	[bottomNavBar release];
	[mainView release];
	[progressIndicator release];
	[textView release];
	if (nil != imageView)
		[imageView release];
	if (nil != scrollerSlider)
		[scrollerSlider release];
	if (nil != animator)
		[animator release];
	if (nil != statusBar)
        [statusBar release];	
	if (nil != alpha)
		[alpha release];
	[defaults release];
	[buttonImg release];
	[minusButton release];
	[plusButton release];
	[invertButton release];
	[rotateButton release];
	[super dealloc];
}

- (void) rotateButtonCallback:(UINavigationButton*) button
{
  
	if (![button isSelected]) // mouse up events only, kids!
	{
		[defaults setRotate90:![defaults isRotate90]];
		[self rotateApp];
	}	
}

- (void)rotateApp
{
	GSLog(@"rotateApp");
	CGSize lContentSize = [textView contentSize];	
	//GSLog(@"contentSize:w=%f, h=%f", lContentSize.width, lContentSize.height);
	//GSLog(@"rotateApp");
	CGRect rect = [defaults fullScreenApplicationContentRect];
	CGAffineTransform lTransform = CGAffineTransformMakeTranslation(0,0);
	//UIAnimator *anim = [[UIAnimator alloc] init];
	[self toggleStatusBarColor];
	if ([defaults isRotate90])
	{
		int degree = 90;
		CGAffineTransform lTransform2  = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
		//BCC: translate to have the center of rotation (top left corner) in the middle of the view
		lTransform = CGAffineTransformTranslate(lTransform, -1*rect.size.width/2, -1*rect.size.height/2);
		//BCC: perform the actual rotation
		//lTransform = CGAffineTransformRotate(lTransform, M_PI/2);
		lTransform = CGAffineTransformConcat(lTransform2, lTransform);
		//BCC: translate back so the bottom right corner of the view is at the bottom left of the phone
		//lTransform = CGAffineTransformTranslate(lTransform, lCurrentRect.size.height - lCurrentRect.size.width/2, lCurrentRect.size.height/2 - lCurrentRect.size.width);
		//BCC: translate back so the top left corner of the view is at the top right of the phone
		lTransform = CGAffineTransformTranslate(lTransform, rect.size.width/2, -rect.size.height/2);
	} else
	{
	}
	struct CGAffineTransform lMatrixprev = [window transform];
	//GSLog(@"prev matrix: a=%f, b=%f, c=%f, d=%f, tx=%f, ty=%f", lMatrixprev.a, lMatrixprev.b, lMatrixprev.c, lMatrixprev.d, lMatrixprev.tx, lMatrixprev.ty);
	//GSLog(@"new matrix: a=%f, b=%f, c=%f, d=%f, tx=%f, ty=%f", lTransform.a, lTransform.b, lTransform.c, lTransform.d, lTransform.tx, lTransform.ty);
	//GSLog(@"rect: x=%f, y=%f, w=%f, h=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

	if (! CGAffineTransformEqualToTransform(lTransform,lMatrixprev))
	{
		//remember the previous position
		struct CGRect overallRect = [[textView _webView] frame];
		//GSLog(@"overall height: %f", overallRect.size.height);
		struct CGRect visRect = [textView visibleRect];
		float scrollPercentage = visRect.origin.y / overallRect.size.height;
		if ([defaults isRotate90])
		{
			[window setFrame: rect];
			[window setBounds: rect];
			[mainView setFrame: rect];
			[mainView setBounds: rect];
		}






		[transitionView setFrame: rect];
		[textView setFrame: rect];
		[self refreshTextViewFromDefaults];
		[textView setHeartbeatDelegate:self];
		int            subchapter = [textView getSubchapter];
		NSString      *recentFile   = [textView currentPath];


		overallRect = [[textView _webView] frame];
//		GSLog(@"new overall height: %f", overallRect.size.height);
		float scrollPoint = (float) scrollPercentage * overallRect.size.height;
		[textView loadBookWithPath:recentFile subchapter:subchapter];
		textViewNeedsFullText = NO;
		[textView scrollPointVisibleAtTopLeft:CGPointMake (0.0f, scrollPoint)
									 animated:NO];

		[window setTransform: lTransform];

		if (![defaults isRotate90])
		{
			rect.origin.y+=20; //to take into account the status bar
			[window setFrame: rect];
		}
		[self updateToolbar: 0];
		[self updateNavbar];

		//[navBar showTopNavBar:NO];
		//[navBar show];
		[bottomNavBar hide:NO];
	//	GSLog(@"showing the slider");
		[self hideSlider];
	}
//	

	//BCC: animate this
	/*	
		UITransformAnimation *scaleAnim = [[UITransformAnimation alloc] initWithTarget: window];
		struct CGAffineTransform lMatrixprev = [window transform];
		[scaleAnim setStartTransform: lMatrixprev];
		[scaleAnim setEndTransform: lTransform];
		[anim addAnimation:scaleAnim withDuration:5.0f start:YES]; 
		[anim autorelease];	//should we do this, it continues to leave for the duration of the animation
		*/
}
- (void) preferenceAnimationDidFinish
{
	[prefsButton setEnabled:true];
}

- (void) removeChapterIndexes {
	NSString *file;
	NSMutableString *chapterIndexesPath = [[NSMutableString alloc] initWithCapacity:80];
  	chapterIndexesPath = [[NSMutableString alloc] initWithString:[NSHomeDirectory() stringByAppendingString:@"/Library/Caches/ruBooks"]];
        
	NSDirectoryEnumerator *dirEnum =  [[NSFileManager defaultManager] enumeratorAtPath:chapterIndexesPath];
	while (file = [dirEnum nextObject]) {
   	 	[[NSFileManager defaultManager] removeFileAtPath: [chapterIndexesPath stringByAppendingPathComponent:file] handler: nil];
	}

}

- (void) returnFromSafari {
	[navBar popNavigationItem];
	[navBar show];
}

 

 - (void) disableLock {
   
 // TODO: get current user
   NSString *key = @"SBAutoLockTime";
   NSString *key2 = @"SBAutoDimTime";
//   NSString *sbPath = @"/private/var/mobile/Library/Preferences/com.apple.springboard.plist";
   NSString *sbPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.apple.springboard.plist"];
   NSLog(sbPath);
    id plist = [NSMutableDictionary dictionaryWithContentsOfFile:sbPath];

 if (_SBAutoLockTime != 0) return;
 if (_SBAutoDimTime != 0) return;
 	
   NSNumber *result = [plist objectForKey:key];
   NSNumber *result2 = [plist objectForKey:key2];  
   
  if ([result intValue] <= 0) return;
  if ([result2 intValue] <= 0) return;
  
  _SBAutoLockTime = [result intValue];
  _SBAutoDimTime  = [result2 intValue];
    
   NSNumber *value = [NSNumber numberWithInt:-1];
  [plist setObject:value forKey:key];
  [plist setObject:value forKey:key2];
    
  [plist writeToFile:sbPath atomically:YES];
   chown([sbPath UTF8String], 501, 501);
   GSSendAppPreferencesChanged(CFSTR("com.apple.springboard"), key);
   GSSendAppPreferencesChanged(CFSTR("com.apple.springboard"), key2);
 }

 - (void) restoreLock {
   
  if (_SBAutoLockTime == 0) return;
  if (_SBAutoDimTime  == 0) return;
  
   NSString *key = @"SBAutoLockTime";
   NSString *key2 = @"SBAutoDimTime";
   NSString *sbPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.apple.springboard.plist"];
    id plist = [NSMutableDictionary dictionaryWithContentsOfFile:sbPath];
   NSNumber *value = [NSNumber numberWithInt:_SBAutoLockTime];
   NSNumber *value2 = [NSNumber numberWithInt:_SBAutoDimTime];
  [plist setObject:value forKey:key];
  [plist setObject:value2 forKey:key2];
    
  [plist writeToFile:sbPath atomically:YES];
   chown([sbPath UTF8String], 501, 501);
   GSSendAppPreferencesChanged(CFSTR("com.apple.springboard"), key);
   GSSendAppPreferencesChanged(CFSTR("com.apple.springboard"), key2);
 
  _SBAutoLockTime = 0;
  _SBAutoDimTime = 0;
  
}

- (SafariController *)getSafariController {
  return sc;
}

@end


 	