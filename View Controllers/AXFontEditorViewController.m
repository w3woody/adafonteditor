//
//  AXFontEditorViewController.m
//  AdaFontEditor
//
//  Created by William Woody on 6/24/18.
//  Copyright © 2018 Glenview Software. All rights reserved.
//

#import "AXFontEditorViewController.h"
#import "NSViewController+Document.h"
#import "AXFontEditView.h"
#import "AXCharacterViewItem.h"
#import "AXDocument.h"
#import "AXLayoutViewController.h"
#import "AXAttributesViewController.h"

@interface AXFontEditorViewController () <NSCollectionViewDataSource, NSCollectionViewDelegate>
@property (weak) IBOutlet NSCollectionView *fontCollection;
@property (weak) IBOutlet AXFontEditView *fontEditor;
@end

@implementation AXFontEditorViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDocument:) name:NOTIFY_DOCUMENTCHANGED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDocument:) name:NOTIFY_ALLCHANGED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCharacter:) name:NOTIFY_CHARACTERCHANGED object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

/*
 *	Menu items
 */

- (IBAction)showFontAttributes:(id)sender
{
	[self performSegueWithIdentifier:@"docLayoutSegue" sender:self];
}

- (IBAction)showCharacterAttributes:(id)sender
{
	NSSet<NSIndexPath *> *sel = self.fontCollection.selectionIndexPaths;
	if ([sel count] == 0) return;

	[self performSegueWithIdentifier:@"charAttrSegue" sender:self];
}

- (IBAction)delete:(id)sender
{
	[self.fontEditor clearCharacter];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"docLayoutSegue"]) {
		AXLayoutViewController *lvc = (AXLayoutViewController *)segue.destinationController;
		__weak AXLayoutViewController *wlvc = lvc;
		lvc.document = (AXDocument *)self.document;
		lvc.close = ^{
			[self dismissViewController:wlvc];
		};
	} else if ([segue.identifier isEqualToString:@"charAttrSegue"]) {
		AXDocument *doc = (AXDocument *)self.document;
		NSSet<NSIndexPath *> *sel = self.fontCollection.selectionIndexPaths;
		NSIndexPath *path = sel.anyObject;
		NSInteger code = doc.first + path.item;

		AXAttributesViewController *lvc = (AXAttributesViewController *)segue.destinationController;
		__weak AXAttributesViewController *wlvc = lvc;
		lvc.document = doc;
		lvc.charIndex = code;
		lvc.close = ^{
			[self dismissViewController:wlvc];
		};
	}
}

/*
 *	Document Notifications
 */

- (void)reloadDocument:(NSNotification *)n
{
	[self.fontEditor setDocument:(AXDocument *)self.document];

	[self.fontCollection deselectAll:nil];
	[self.fontCollection reloadData];
	[self.fontEditor setCharacter:nil atIndex:0];
}

- (void)reloadCharacter:(NSNotification *)n
{
	NSNumber *num = n.userInfo[@"char"];
	AXDocument *doc = (AXDocument *)self.document;

	NSMutableSet *set = [[NSMutableSet alloc] init];
	NSIndexPath *ipath = [NSIndexPath indexPathForItem:num.integerValue - doc.first inSection:0];
	[set addObject:ipath];
	[self.fontCollection reloadItemsAtIndexPaths:set];
}

/*
 *	Font collection view
 */

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
	return 1;
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	AXDocument *doc = (AXDocument *)self.document;
	NSInteger len = 1 + doc.last - doc.first;
	return len;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
	AXCharacterViewItem *item = [collectionView makeItemWithIdentifier:@"AXCharacterViewItem" forIndexPath:indexPath];
	AXDocument *doc = (AXDocument *)self.document;

	uint8_t charIndex = indexPath.item + doc.first;
	AXCharacter *ch = [doc characterAtIndex:charIndex];
	NSString *label;
	if ((charIndex < 32) || (charIndex >= 127)) {
		label = [NSString stringWithFormat:@"%02X",charIndex];
	} else {
		label = [NSString stringWithFormat:@"%c",charIndex];
	}

	[item.imageView setImage:ch.bitmapImage];
	[item.textField setStringValue:label];

	return item;
}

- (void)collectionView:(NSCollectionView *)col didSelectItemsAtIndexPaths:(nonnull NSSet<NSIndexPath *> *)indexPaths
{
	NSIndexPath *indexPath = indexPaths.anyObject;
	NSInteger ix = indexPath.item;
	AXDocument *doc = (AXDocument *)self.document;
	AXCharacter *ch = [doc characterAtIndex:ix + doc.first];
	[self.fontEditor setDocument:doc];
	[self.fontEditor setCharacter:ch atIndex:ix + doc.first];
}

@end
