/*
        By: Sean Heber  <sean@spiffytech.com>
        iApp-a-Day - November, 2007
        BSD License
*/
#import <UIKit/UIKit.h>
#import <UIKit/UIScroller.h>
#import <UIKit/UIWebView.h>

@interface SimpleWebView : UIView {
    UIWebView *webView;
    UIScroller *scroller;
    NSURLRequest *urlRequest;
    CGSize lastSize, size;
}
-(id)initWithFrame: (CGRect)frame;
-(id)loadURL: (NSURL *)url;
-(void)dealloc;
@end
