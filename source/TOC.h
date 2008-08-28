#ifndef _TOC_CONTROLLER_H
#define _TOC_CONTROLLER_H

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

@class BooksApp;
@interface TOCController : NSObject
{

  EBookView   *textView;
  BooksApp    *controller;
  UINavigationBar    *navigationBar;
  UIPreferencesTable *chapterTable;
  UIPreferencesTableCell *_selectedCell;
  UIView *TOCView;
  BooksDefaultsController *defaults;
  NSArray *chapters;
}

- (id)initWithAppController:(BooksApp *)appController chapHTML:(ChapteredHTML *)chapHTML;
- (UITable *)table;
- (UIView *)view;
- (void)reloadData;

@end

#endif
