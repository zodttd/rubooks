/*
        By: Sean Heber  <sean@spiffytech.com>, J. Zdziarski
        iApp-a-Day - November, 2007
        BSD License
*/
#import "SimpleWebView.h"
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIView-Rendering.h>
#import <UIKit/UIView.h>


@implementation SimpleWebView


- (BOOL)respondsToSelector:(SEL)aSelector
{
  NSLog(@"WKV Request for selector: %@", NSStringFromSelector(aSelector));
  return [super respondsToSelector:aSelector];
}


 
-(void)view: (UIView*)v didSetFrame:(CGRect)f
{
    if (v == webView) {
        [ scroller setContentSize: f.size ];
    }
}



-(void)view:(id)v didDrawInRect:(CGRect)f duration:(float)d
{
    if (v == webView) {

NSLog(@"didDrawInRect: width = %d", size.width);
 
        size = [ webView bounds ].size;
        if (size.height != lastSize.height || size.width != lastSize.width) {
            lastSize = size;
            [ scroller setContentSize: size ];
        }
    }
}


- (void)gestureEnded:(struct __GSEvent *)event {
    [ webView redrawScaledDocument ];
    [ webView setNeedsDisplay ];
    [ scroller setContentSize: [ webView bounds ].size ];
}


/*
- (void)doubleTap:(struct __GSEvent *)event {
    struct timeval tv;
    tv.tv_sec = 2;
    tv.tv_usec = 0;
    select(NULL, NULL, NULL, NULL, &tv);
    [ webView redrawScaledDocument ];
    [ webView setNeedsDisplay ];
    [ scroller setContentSize: [ webView bounds ].size ];
}
*/


-(void)dealloc
{
	[ urlRequest release ];
	[ webView release ];
	[ scroller release ];
	[ super dealloc ];
}

-(id)initWithFrame: (CGRect)frame
{
    frame.origin.x = 0;
    frame.origin.y = 24;

// TODO: FIX ORIENTATION DETECTION
//    frame.size.height = 480-24;
//    frame.size.width = 320;

    [ super initWithFrame: frame ];

    NSLog(@"initWithFrame %@",frame);

    scroller = [ [ UIScroller alloc ] initWithFrame: frame ];
    [ scroller setScrollingEnabled: YES ];
    [ scroller setAdjustForContentSizeChange: YES ];
    [ scroller setClipsSubviews: YES ];
    [ scroller setAllowsRubberBanding: YES ];
    [ scroller setDelegate: self ];
    [ scroller setShowBackgroundShadow: YES ];
//    [scroller setThumbDetectionEnabled:YES];
    [ self addSubview: scroller ];

    webView = [ [ UIWebView alloc ] initWithFrame: [ scroller bounds ] ];

      [ webView setTilingEnabled: YES ];                       	
      [ webView setTileSize: frame.size ];
    

    [ webView setAutoresizes: YES];
    [ webView setDelegate: self];
    [webView setAutoresizingMask: 2];



    [ webView setEnabledGestures: 0xFF ];
//    [ webView setEnabledGestures: 2 ];

//    [ webView setSmoothsFonts: YES ];
    [ scroller addSubview: webView ];
    NSLog(@"webView: %@",webView);
    return self;
}

-(id)loadURL: (NSURL *)url
{
    NSLog(@"Loading URL...");
    CGPoint zero;
    zero.x = 0;
    zero.y = 0;
    [ scroller scrollPointVisibleAtTopLeft: zero ];
    urlRequest = [ [ NSURLRequest requestWithURL: url ] retain ];
    [ webView loadRequest: urlRequest ];
}

@end
