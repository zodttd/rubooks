// FileTable.m, by Nate True and the NES.app team, 
// with additions by Zachary Brewster-Geisz

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

#import <GraphicsServices/GraphicsServices.h>
#import "FileTable.h"

@implementation FileTable

- (int)swipe:(int)type withEvent:(struct __GSEvent *)event;
{
  if ((_allowDelete == YES) && ((4 == type) || (8 == type)))
      {
        struct CGRect tapRect = GSEventGetLocationInWindow(event);
        struct CGPoint rect = [self convertPoint:tapRect.origin fromView:nil];
        CGPoint point = CGPointMake(rect.x, rect.y - 45);
        CGPoint offset = _startOffset; 
        NSLog(@"FileTable.swipe: %d %f, %f", type, point.x, point.y);

        point.x += offset.x;
        point.y += offset.y;
        int row = [ self rowAtPoint:point ];

        [ [ self visibleCellForRow:row column:0] 
           _showDeleteOrInsertion:YES 
           withDisclosure:NO
           animated:YES 
           isDelete:YES 
           andRemoveConfirmation:NO
        ];

    }
    return [ super swipe:type withEvent:event ];
}

- (void)allowDelete:(BOOL)allow {
    _allowDelete = allow;
}

- (void)setBackgroundImageAtPath:(NSString *)path
{
  /*  if (nil != _backgroundImage)
    [_backgroundImage release];
  _backgroundImage = [[UIImage imageAtPath:path] retain];
  if (nil == _backgroundImage)
    return;
  CGImageRef ref = [_backgroundImage imageRef];
  int width = CGImageGetWidth(ref);
  int height = CGImageGetHeight(ref);
  _backgroundImageSourceRect = CGRectMake(0,0,width,height);
  float aspectRatio;
  if (width > height)
    {
      aspectRatio = (float)height / (float)width;
      float w = 320.0;
      float h = 320 * aspectRatio;
      _backgroundImageDestRect = CGRectMake(0,0,w,h);
    }
  else
    {
      aspectRatio = (float)width / (float)height;
      float w = 412 * aspectRatio;
      float h = 412;
      _backgroundImageDestRect = CGRectMake(0,0,w,h);
    }
  */
}
/*
-(void)drawRect:(struct CGRect)rect
{
  [super drawRect:rect];
  if (nil != _backgroundImage)
    {
      [_backgroundImage compositeToRect:_backgroundImageDestRect
			fromRect:_backgroundImageSourceRect
			operation:1
			fraction:0.2];
    }
}
*/
- (void)dealloc
{
  if (nil != _backgroundImage)
    [_backgroundImage release];
  [super dealloc];
}

@end

@implementation DeletableCell

- (void)removeControlWillHideRemoveConfirmation:(id)fp8
{
    [ self _showDeleteOrInsertion:NO
          withDisclosure:NO
          animated:YES
          isDelete:YES
          andRemoveConfirmation:YES
    ];
}

- (void)_willBeDeleted
{
  [[NSNotificationCenter defaultCenter] postNotificationName:SHOULDDELETEFILE object:self];
}

- (void)setTable:(FileTable *)table {
    _table = table;
}

- (void)setFiles:(NSMutableArray *)files {
    _files = files;
}

- (NSString *)path {
        return [[_path retain] autorelease];
}

- (void)setPath: (NSString *)path {
        [_path release];
        _path = [path copy];
}

@end

