#import "SafariController.h"
#import "BooksApp.h"

@implementation SafariController

 - (id)initWithAppController:(BooksApp *)appController file:(NSString *)file;
{
	if (self = [super init])
	{
		controller = appController;
		defaults = [BooksDefaultsController sharedBooksDefaultsController];
		struct CGRect rect = [defaults fullScreenApplicationContentRect];

		safariView = [[UIView alloc] initWithFrame:rect];

  float components[4] = { 0.5, 0.5, 0.5, 1.0 };
  //CGColorRef gray = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
  //[safariView setBackgroundColor:gray];

  
		navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, rect.size.width, 48.0f)];
		[navigationBar showLeftButton:NSLocalizedString(@"button.back",@"Back") withStyle:2 rightButton:nil withStyle:0];

// ROTATE BUTTON DISABLED FOR THE MOMENT
//	float lMargin = 45.0f;
//	[navigationBar setRightMargin:lMargin];		
//	rotateButton = [controller toolbarButtonWithName:@"rotate" rect:CGRectMake(rect.size.width-lMargin,9,30,30) selector:@selector(rotateButtonCallback:) flipped:NO];
//	[navigationBar addSubview:rotateButton];

		[navigationBar setBarStyle:0];
		[navigationBar setDelegate:self]; 
		[safariView addSubview:navigationBar];
		UINavigationItem *title = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"window.safari.title", @"Safari")];
		[navigationBar pushNavigationItem:[title autorelease]];

  NSURL *url;
	  url = [[NSURL alloc] initFileURLWithPath:file];

	  if (_webView != nil) [_webView release];
	  _webView = [[SimpleWebView alloc] initWithFrame:rect];
	  [_webView loadURL:url];
	  [safariView addSubview: _webView];
	  
	}
	return self;
}


-(UIView *)view
{
	return safariView;
}

-(void)dealloc
{
	[_webView release];
	[defaults release];
	[super dealloc];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
NSLog(@"Button pressed: %d",button);
		switch (button) 
		{
			case 1: 
                                [controller returnFromSafari];
		}
}

-(SimpleWebView *)getWebView
{
	return _webView;
}

@end
