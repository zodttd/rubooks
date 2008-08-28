#import "TOC.h"
#import "BooksApp.h"

@implementation TOCController

- (id)initWithAppController:(BooksApp *)appController chapHTML:(ChapteredHTML *)chapHTML;
{
	if (self = [super init])
	{
		controller = appController;
		defaults = [BooksDefaultsController sharedBooksDefaultsController];
		struct CGRect rect = [defaults fullScreenApplicationContentRect];

		TOCView = [[UIView alloc] initWithFrame:rect];

		navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, rect.size.width, 48.0f)];
		[navigationBar showLeftButton:NSLocalizedString(@"button.back",@"Back") withStyle:2 rightButton:nil withStyle:0];
		[navigationBar setBarStyle:0];
		[navigationBar setDelegate:self]; 
		[TOCView addSubview:navigationBar];
		UINavigationItem *title = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"window.toc.title", @"Table of Contents")];
		[navigationBar pushNavigationItem:[title autorelease]];


		chapterTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0.0f, 48.0f, rect.size.width, rect.size.height-48.0f)];
		NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:controller->textView->chapteredHTML->chapterTitles];


		int i = [controller->textView->chapteredHTML->chapterTitles count];

		if (i == 0) [tempArray addObject:NSLocalizedString(@"message.no_chapters_found",@"No Chapter Found")];

		chapters = [[NSArray alloc] initWithArray:tempArray];
		[tempArray release];

		[chapterTable setDelegate:self];
		[chapterTable setDataSource:self];
		[chapterTable reloadData];

		[TOCView addSubview:chapterTable];

// NSLog(@" %@",[chapterTable]);
                int selectedIndex = [controller->textView getSubchapter];

                [chapterTable scrollRowToVisible:(selectedIndex+1)];
//		[chapterTable scrollAndCenterTableCell:_selectedCell animated:YES];


	}
	return self;
}

-(void)reloadData
{
	[chapterTable reloadData];
}

-(UITable *)table
{
	return chapterTable;
}

-(UIView *)view
{
	return TOCView;
}


- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
	return 1;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
	return [chapters count];
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
{
	return 48.0f;
}

-(void)tableRowSelected:(NSNotification *)aNotification
{
	int i = [chapterTable selectedRow];
	[controller chapJump:([chapterTable selectedRow]-1)];
}

- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
	NSString *title;
	BOOL checked = NO;
	int selectedIndex = [controller->textView getSubchapter];
	CGRect rect = [defaults fullScreenApplicationContentRect];
	UIPreferencesTableCell *theCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,rect.size.width,48)];
	[theCell setTitle:[[chapters objectAtIndex:row] stringByDeletingPathExtension]];
        [theCell setChecked:(selectedIndex == row)];
        _selectedCell = theCell;
	return [theCell autorelease];
}


-(void)dealloc
{
	[chapters release];
	[chapterTable release];
	[defaults release];
	[super dealloc];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
NSLog(@"Button pressed: %d",button);
		switch (button) 
		{
			case 1: 
				[controller chapJump:-1];
				break;
		}
}
@end
