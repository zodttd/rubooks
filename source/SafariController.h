#ifndef _SAFARI_CONTROLLER_H
#define _SAFARI_CONTROLLER_H

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTableCell.h>

#import "BooksApp.h" 
#import "BooksDefaultsController.h"
//#import "PreferencesController.h"
#import "SimpleWebView.h"

@class BooksApp;
@interface SafariController : NSObject
{

  EBookView   *textView;
  BooksApp    *controller;
  UINavigationBar    *navigationBar;
  UIView *safariView;
  BooksDefaultsController *defaults;
  SimpleWebView *_webView;
  UINavigationButton *rotateButton;  
}

- (id)initWithAppController:(BooksApp *)appController file:(NSString *)file;
- (UIView *)view;
- (SimpleWebView *)getWebView;

@end

#endif
