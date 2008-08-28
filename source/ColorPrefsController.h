#ifndef COL_PREF_CTL_H
#define COL_PREF_CTL_H

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
#import <UIKit/UIOldSliderControl.h>

#import "BooksDefaultsController.h"
//#import "PreferencesController.h"


@interface ColorPrefsController : NSObject
{
  UIPreferencesTable *encodingTable;
  UIPreferencesTableCell *sampleCell;
  UIView *_view;
  BooksDefaultsController *defaults;
//  NSArray *encodingNumbers, *encodingNames;
  UIOldSliderControl    *colorControl[12];
}
-(void)reloadData;
-(UITable *)table;
-(UIView *)colorView;
-(void)hideColorView;
@end

#endif
