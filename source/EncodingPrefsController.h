// EncodingPrefsController, for Books.app, by Zach Brewster-Geisz
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
#ifndef ENC_PREF_CTL_H
#define ENC_PREF_CTL_H

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


@interface EncodingPrefsController : NSObject
{
  UIPreferencesTable *encodingTable;
  BooksDefaultsController *defaults;

  NSArray *encodingNumbers, *encodingNames;

}

-(UITable *)table;
-(void)reloadData;

int unsignedCompare(id x, id y, void *context);

@end

#endif
