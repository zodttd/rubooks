#import "ColorPrefsController.h"
#import <ApplicationServices/ApplicationServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>


@implementation ColorPrefsController

-(ColorPrefsController *)init
{
  if (self = [super init])
    {
      defaults = [BooksDefaultsController sharedBooksDefaultsController];
	  
      struct CGRect rect = [defaults fullScreenApplicationContentRect];

	  sampleCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,rect.size.width, 20)];
	    [sampleCell setValue:@"           Night           "];
		[sampleCell setTitle:@"            Day            "];
		
      encodingTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0,20,rect.size.width, rect.size.height-48-20)];
      [encodingTable setDelegate:self];
      [encodingTable setDataSource:self];
	  [ encodingTable reloadData];
	  int i,j;
	  for (i = 0;i<4;i++) {
	   for (j = 0;j<3;j++) {
		colorControl[i*3+j] = [ [ UIOldSliderControl alloc ] initWithFrame:CGRectMake(50.0f, 5.0f, 240.0f, 38.0f) ];
		[ colorControl[i*3+j] setMinValue: 0.0 ];
		[ colorControl[i*3+j] setMaxValue: 1.0 ];
		[ colorControl[i*3+j] setShowValue: YES];
		[colorControl[i*3+j] addTarget:self action:@selector(handleSlider:) forEvents:7];
		[colorControl[i*3+j] addTarget:self action:@selector(handleSlider:) forEvents:2];
		[ colorControl[i*3+j] setValue: [defaults color:i component:j]];
	}}
		[self handleSlider:nil];
		_view =[[UIView alloc] initWithFrame:CGRectMake(0,0,rect.size.width, rect.size.height-48)];
		[_view addSubview:sampleCell];	  
		[_view addSubview:encodingTable];
		return self;
	}
}

-(void)reloadData
{
  [encodingTable reloadData];
}

-(UITable *)table
{
  return encodingTable;
}

-(UIView *)colorView
{
  return _view;
}



- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
  return 4;
}


- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
	return 3;
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
    switch (group) {
		case(0): return NSLocalizedString(@"preference.colors.section.text_day",@""); break;
		case(1): return NSLocalizedString(@"preference.colors.section.background_day",@""); break;
		case(2): return NSLocalizedString(@"preference.colors.section.text_night",@""); break;
		case(3): return NSLocalizedString(@"preference.colors.section.background_night",@""); break;
	}
  
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
{
  return 48.0f;
}


- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
 					CGRect rect = [defaults fullScreenApplicationContentRect];
					UIPreferencesTableCell *theCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,rect.size.width,48)];
 if (row == 0) [ theCell setTitle:@"R" ];
 if (row == 1) [ theCell setTitle:@"G" ];
 if (row == 2) [ theCell setTitle:@"B" ];
                    [ theCell addSubview: colorControl[(group)*3+row] ];
					[ theCell setShowSelection: NO ];
					[ theCell setEnabled: YES ];
					return [theCell autorelease];
}

- (void) handleSlider: (id) sender
{
#if 0
// UIPreferencesTableCell *theCell = [[self table] cellAtRow:1 column:0];
 CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
 int j;
 float color[4] = {1,1,1,1};
 //[sampleCell setBackgroundColor:CGColorCreate(colorSpace,color)];
	   for (j = 0;j<3;j++) {  color[j] = [colorControl[0*3+j] value]; }
		[[sampleCell titleTextLabel] setColor:CGColorCreate(colorSpace,color)];
		
	  // for (j = 0;j<3;j++) {  color[j] = [colorControl[1*3+j] value]; }
		//[[sampleCell titleTextLabel] setBackgroundColor:CGColorCreate(colorSpace,color)];
		
	   for (j = 0;j<3;j++) {  color[j] = [colorControl[2*3+j] value]; }
		[[sampleCell valueTextLabel] setColor:CGColorCreate(colorSpace,color)];
		
	  // for (j = 0;j<3;j++) {  color[j] = [colorControl[3*3+j] value]; }
		//[[sampleCell valueTextLabel] setBackgroundColor:CGColorCreate(colorSpace,color)];
#endif
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
		switch (button) 
		{
			case 1: 
				[self hideColorView];
				break;
		}
}


-(void)hideColorView 
{
#if 0
// UIPreferencesTableCell *cell = [encodingTable cellAtRow:i+1 column:0];
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  int i;
  for (i = 0; i<4; i++) {
	[defaults setColor:[colorControl[i*3+0] value] index:i component:0];
	[defaults setColor:[colorControl[i*3+1] value] index:i component:1];
	[defaults setColor:[colorControl[i*3+2] value] index:i component:2];
  }
//  [cell setSelected:NO withFade:YES];
#endif
  [[NSNotificationCenter defaultCenter] postNotificationName:COLORSELECTED object:@""];
}

-(void)dealloc
{
  int i;
  for (i = 0;i<12;i++) { [colorControl[i] release]; }
		
  [encodingTable release];
  [sampleCell release];
  [_view release];
  [defaults release];
  [super dealloc];
 // TODO: release sliders
}


@end
