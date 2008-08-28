#ifndef FONT_CHOICE_CTL_H
#define FONT_CHOICE_CTL_H

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

#import "BooksDefaultsController.h"
//#import "PreferencesController.h"


@interface FontChoiceController : NSObject
{
  UIPreferencesTable *fontTable;
  BooksDefaultsController *defaults;
  NSArray *availableFonts;
}

-(UITable *)table;
-(void)reloadData;

@end

#endif
