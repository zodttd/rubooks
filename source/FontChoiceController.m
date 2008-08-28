#import "FontChoiceController.h"

@implementation FontChoiceController

-(FontChoiceController *)init
{
	if (self = [super init])
	{
		GSLog(@"Creating font panel!");
		defaults = [BooksDefaultsController sharedBooksDefaultsController];
		struct CGRect rect = [defaults fullScreenApplicationContentRect];
		//    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
		//  rect.origin.x = rect.origin.y = 0;

		fontTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0,0,rect.size.width, rect.size.height-48)];
		NSString *fontFolderPath = @"/System/Library/Fonts/";
		// If Apple ever adds the ability to add fonts to a different
		// directory, define it here.
		NSArray *fontsFolderContents = [[NSFileManager defaultManager] directoryContentsAtPath:fontFolderPath];
		NSEnumerator *enumerator = [fontsFolderContents objectEnumerator];
		NSString *currentFont;
		NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:[fontsFolderContents count]];

		// Some fonts render as an ugly default.  These are them.
		NSArray *fontsKnownToNotWork = 
			[NSArray arrayWithObjects:@"AmericanTypewriterBold.ttf",
			@"AmericanTypewriterCondensed.ttf",
			@"AmericanTypewriterCondensedBold.ttf",
			@"AmericanTypewriterCondensedLight.ttf",
			@"AmericanTypewriterLight.ttf",
			@"LockClock.ttf",
			@"MarkerFeltWide.ttf", nil];

		while (nil != (currentFont = [enumerator nextObject]))
		{
			if ([[currentFont pathExtension] isEqualToString:@"ttf"] &&
						![fontsKnownToNotWork containsObject:currentFont])
			{
				[tempArray addObject:currentFont];
			}
		}
		availableFonts = [[NSArray alloc] initWithArray:tempArray];
		[tempArray release];
		[fontTable setDelegate:self];
		[fontTable setDataSource:self];
		[fontTable reloadData];
		//      defaults = [[BooksDefaultsController alloc] init];
	}
	GSLog(@"Created fonts prefs!");
	return self;
}

-(void)reloadData
{
	[fontTable reloadData];
}

-(UITable *)table
{
	return fontTable;
}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
	return 1;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
	return [availableFonts count];
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
	return NSLocalizedString(@"window.font.subtitle",@"Fonts");;
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
{
	return 48.0f;
}

-(void)tableRowSelected:(NSNotification *)aNotification
{
	int i = [fontTable selectedRow];
	UIPreferencesTableCell *cell = [fontTable cellAtRow:i column:0];
	NSString *title = [cell title];
	int rows = [fontTable numberOfRows];

	for (i = 0; i < rows; i++)
		[[fontTable cellAtRow:i column:0] setChecked:NO];
	[cell setChecked:YES];
	[cell setSelected:NO withFade:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:NEWFONTSELECTED object:title];

}

- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
	NSString *title;
	BOOL checked = NO;

	CGRect rect = [defaults fullScreenApplicationContentRect];
	UIPreferencesTableCell *theCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,rect.size.width,48)];

	//UIPreferencesTableCell *theCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,320,48)];
	[theCell setTitle:[[availableFonts objectAtIndex:row] stringByDeletingPathExtension]];
	[theCell setChecked:([[theCell title] isEqualToString:[defaults textFont]])];
	return [theCell autorelease];
}


-(void)dealloc
{
	[availableFonts release];
	[fontTable release];
	[defaults release];
	[super dealloc];
}

@end
