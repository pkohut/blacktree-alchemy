
// SLKeyPopUpButton.m
// Searchling
//
// Created by Alcor on Thu Jan 16 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "QSObjectView.h"
#import "QSObjectCell.h"
#import "QSController.h"
#import "QSLibrarian.h"
#import "QSInterfaceController.h"

#import <QSFoundation/QSFoundation.h>
#import "NSCursor_InformExtensions.h"
#import "QSObject_Drag.h"
#import "QSObject_Menus.h"
#import "QSObject_Pasteboard.h"
#import "QSAction.h"
//#import "NSString_CompletionExtensions.h"

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

@implementation QSObjectView

+ (Class) cellClass {
	return [QSObjectCell class];
}

- (id)validRequestorForSendType:(NSString *)sendType
					 returnType:(NSString *)returnType {
	// NSLog(@"validate %@", [self objectValue]);
	id object = [self objectValue];
	if ([object respondsToSelector:@selector(dataDictionary)] && [[[object dataDictionary] allKeys] containsObject: sendType])
		return self;
	return nil;
}

- (void)viewDidMoveToWindow {
//	NSMutableParagraphStyle *truncatedStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
//	[truncatedStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];

	//detailAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
//		[NSFont systemFontOfSize:10] , NSFontAttributeName,
//		[NSColor grayColor] , NSForegroundColorAttributeName,
//		truncatedStyle, NSParagraphStyleAttributeName,
//		nil] retain];
	//NSLog(@"move");
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNeedsDisplay:) name:NSSystemColorsDidChangeNotification object:nil];

}

- (void)awakeFromNib {
	[self viewDidMoveToWindow];
	[self registerForDraggedTypes:[NSArray arrayWithObjects:@"Apple URL pasteboard type", NSColorPboardType, NSFileContentsPboardType, NSFilenamesPboardType, NSFontPboardType, NSHTMLPboardType, NSPDFPboardType, NSPICTPboardType, NSPostScriptPboardType, NSRulerPboardType, NSRTFPboardType, NSRTFDPboardType, NSStringPboardType, NSTabularTextPboardType, NSTIFFPboardType, NSURLPboardType, NSVCardPboardType, NSFilesPromisePboardType, nil]];
	if (!controller && [self window])
		controller = [[self window] delegate];
	// [self setToolTip:@"No Selection"];
	draggedObject = nil;
	[self setDropMode:QSFullDropMode];
}
- (QSInterfaceController *)controller {
	if (!controller && [self window])
		controller = [[self window] delegate];
	return controller;
}

- (BOOL)acceptsFirstResponder {return NO;}

- (BOOL)resignFirstResponder {
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)becomeFirstResponder {
	//[controller setFocus:self];
	[self setNeedsDisplay:YES];
	return YES;
}
- (BOOL)isOpaque {
	return NO;
}

- (void)setImage:(NSImage *)image {
}

- (void)mouseDown:(NSEvent *)theEvent {
	BOOL isInside = YES;
	NSPoint mouseLoc;

	theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	isInside = [self mouse:mouseLoc inRect:[self bounds]];

	switch ([theEvent type]) {
		case NSLeftMouseDragged:
			performingDrag = YES;
			// [super mouseDragged:theEvent];
			if ([self objectValue]) {
				NSRect reducedRect = [self frame];
				//reducedRect.size.width = MIN(NSWidth([self frame]), 52+MAX([[[self objectValue] name] sizeWithAttributes:nil] .width, [[[self objectValue] details] sizeWithAttributes:detailAttributes] .width) );
				NSImage *dragImage = [[[NSImage alloc] initWithSize:reducedRect.size] autorelease];
				[dragImage lockFocus];
				[[self cell] drawInteriorWithFrame:NSMakeRect(0, 0, [dragImage size] .width, [dragImage size] .height) inView:self];
				[dragImage unlockFocus];
				NSSize dragOffset = NSMakeSize(0.0, 0.0);

				if (!([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ) {
					NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
					[[self objectValue] putOnPasteboard:pboard includeDataForTypes:nil];
					[self dragImage:[dragImage imageWithAlphaComponent:0.5] at:NSZeroPoint offset:dragOffset
							 event:theEvent pasteboard:pboard source:self slideBack:!([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask)];

				} else {
					NSPoint dragPosition;
					NSRect imageLocation;

					dragPosition = [self convertPoint:[theEvent locationInWindow]
											 fromView:nil];
					dragPosition.x -= 16;
					dragPosition.y -= 16;
					imageLocation.origin = dragPosition;
					imageLocation.size = NSMakeSize(32, 32);

					[self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"silver"]
										 fromRect:imageLocation
											source:self
										 slideBack:YES
											 event:theEvent];
				}

			}
				break;
		case NSLeftMouseUp:
			//if (isInside)
			// NSLog(@"mouseUp");
			[self mouseClicked:theEvent];
			break;
		default:
			break;
	}

	return;
}
- (void)mouseClicked:(NSEvent *)theEvent {

}

- (BOOL)needsPanelToBecomeKey {
	return YES;
}

- (void)paste:(id)sender {[self readSelectionFromPasteboard:[NSPasteboard generalPasteboard]];} ;

- (void)cut:(id)sender {
	[[self objectValue] putOnPasteboard:[NSPasteboard generalPasteboard] includeDataForTypes:nil];
	[self setObjectValue:nil];
}

- (void)copy:(id)sender {
	[[self objectValue] putOnPasteboard:[NSPasteboard generalPasteboard] includeDataForTypes:nil];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard {
	QSObject *entry;
	entry = [QSObject objectWithPasteboard:pboard];
	[self setObjectValue:entry];
	return YES;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types {
	[[self objectValue] putOnPasteboard:pboard includeDataForTypes:types];
	return YES;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
	NSLog(@"write to %@", [dropDestination path]);
	NSString *name = [[[self objectValue] name] stringByAppendingPathExtension:@"silver"];

	name = [name stringByReplacing:@"/" with:@"_"];
	name = [name stringByReplacing:@":" with:@"_"];
	NSString *file = [[dropDestination path] stringByAppendingPathComponent:name];

	//NSLog(file);
	[(QSObject *)[self objectValue] writeToFile:file];
	return [NSArray arrayWithObject:name];
}

- (NSSize) cellSize {
	return [[self cell] cellSize];
}
- (NSMenu *)mxenu {
	// NSLog(@"Menu");
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"ContextMenu"] autorelease];

	NSArray *actions = [[QSLibrarian sharedInstance] validActionsForDirectObject:[self objectValue] indirectObject:nil];

	// actions = [actions sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	NSMenuItem *item;
	int i;
	for (i = 0; i<[actions count]; i++) {
		QSAction *action = [actions objectAtIndex:i];
		if (action) {
			NSArray *componentArray = [[action name] componentsSeparatedByString:@"/"];

			NSImage *icon = [action icon];
			[icon setSize:NSMakeSize(16, 16)];

			if ([componentArray count] >1) {
				NSMenuItem *groupMenu = [menu itemWithTitle:[componentArray objectAtIndex:0]];
				if (!groupMenu) {
					groupMenu = [[[NSMenuItem alloc] initWithTitle:[componentArray objectAtIndex:0] action:nil keyEquivalent:@""] autorelease];
					if (icon) [groupMenu setImage:icon];
					[groupMenu setSubmenu: [[[NSMenu alloc] initWithTitle:[componentArray objectAtIndex:0]]autorelease]];
					[menu addItem:groupMenu];
				}
				item = (NSMenuItem *)[[groupMenu submenu] addItemWithTitle:[componentArray objectAtIndex:1] action:@selector(performMenuAction:) keyEquivalent:@""];
			} else
				item = (NSMenuItem *)[menu addItemWithTitle:[action name] action:@selector(performMenuAction:) keyEquivalent:@""];

			[item setTarget:self];
			[item setRepresentedObject:action];
			if (icon) [item setImage:icon];

		}
	}

	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@""];
	[menu addItemWithTitle:@"Remove" action:@selector(delete:) keyEquivalent:@""];

	return menu;

}

- (void)performMenuAction:(NSMenuItem *)item {
	[[item representedObject] performOnDirectObject:[self objectValue] indirectObject:nil];
}

//Standard Accessors

- (id)objectValue { return [[self cell] representedObject];  }
- (void)setObjectValue:(QSBasicObject *)newObject {
	[newObject loadIcon];
	[newObject becameSelected];
	// [self setToolTip:[newObject toolTip]];
	[[self cell] setRepresentedObject:newObject];
	[self setNeedsDisplay:YES];
}

- (QSObjectDropMode) dropMode { return dropMode;  }
- (void)setDropMode:(QSObjectDropMode)aDropMode {
	dropMode = aDropMode;
}

- (BOOL)acceptsDrags { return [self dropMode];  }

- (BOOL)initiatesDrags { return initiatesDrags;  }
- (void)setInitiatesDrags:(BOOL)flag {
	initiatesDrags = flag;
}

- (QSObject *)draggedObject { return draggedObject;  }

- (void)setDraggedObject:(QSObject *)newDraggedObject {
	[draggedObject release];
	draggedObject = [newDraggedObject retain];
}

- (NSString *)searchString { return searchString;  }

- (void)setSearchString:(NSString *)newSearchString {
	if (newSearchString == searchString) return;
	[searchString release];
	searchString = [newSearchString retain];
	// [self setNeedsDisplay:YES];
}

- (unsigned int) draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	if (isLocal) return NSDragOperationMove;
	else return ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) ? NSDragOperationNone : NSDragOperationEvery;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	performingDrag = NO;
//	NSLog(@"ended at %f %f %d", aPoint.x, aPoint.y, operation);
	//	if (operation == NSDragOperationNone) NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, aPoint, NSZeroSize, nil, nil, nil);
	//	if (operation == NSDragOperationMove) [self removeFromSuperview];
}

//Dragging

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender {
	if (![self acceptsDrags] || performingDrag || ([self objectValue] && ![[self objectValue] respondsToSelector: @selector(actionForDragOperation:withObject:)]))
		return NSDragOperationNone;

	[self setDragAction:nil];
	lastDragMask = NSDragOperationNone;

	if ([[sender draggingSource] isKindOfClass:[self class]])
		[self setDraggedObject:[[sender draggingSource] objectValue]];
	else
		[self setDraggedObject:[QSObject objectWithPasteboard:[sender draggingPasteboard]]];
	return [self draggingUpdated:sender];
}

- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender {
	if ([self objectValue] && ![[self objectValue] respondsToSelector: @selector(actionForDragOperation:withObject:)])
		return NSDragOperationNone;
	NSDragOperation operation = 0;
	if (![self objectValue] || [self dropMode] == QSSelectDropMode)
		operation = NSDragOperationGeneric;
	else if ([[self objectValue] respondsToSelector:@selector(draggingEntered:withObject:)])
		operation = [[self objectValue] draggingEntered:sender withObject:[self draggedObject]];
	NSCursor *cursor;
	if (operation == NSDragOperationGeneric) {
		cursor = [NSCursor informativeCursorWithString:@"Select"];
		[cursor set];
		[[self cell] setHighlighted:NO];
	} else if (fDEV && [[NSApp currentEvent] modifierFlags] & NSControlKeyMask) {
		cursor = [NSCursor informativeCursorWithString:@"Choose Action..."];
		[cursor performSelector:@selector(set) withObject:nil afterDelay:0.0];
		operation = NSDragOperationPrivate;
	} else {
		if (operation != lastDragMask) {
			NSString *action = [[self objectValue] actionForDragOperation:operation withObject:draggedObject];
			cursor = [NSCursor informativeCursorWithString:[[QSLib actionForIdentifier:action] name]];
			[cursor performSelector:@selector(set) withObject:nil afterDelay:0.0];
		}
		if (operation)
			[[self cell] setHighlighted:YES];
	}
	lastDragMask = operation;
	return operation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[[self cell] setHighlighted:NO];
	[self setDraggedObject:nil];
	[NSCursor pop];
	[self setNeedsDisplay:YES];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {}

- (void)drawRect:(NSRect)rect { [[self cell] drawWithFrame:rectFromSize([self frame].size) inView:self];  }

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSString *action = [[self objectValue] actionForDragOperation:lastDragMask withObject:draggedObject];

	if (fDEV && [[NSApp currentEvent] modifierFlags] & NSControlKeyMask) {
		[NSMenu popUpContextMenu:[[[self objectValue] resolvedObject] actionsMenu] withEvent:[NSApp currentEvent] forView:self];
	} else if (action && [self dropMode] != QSSelectDropMode) {
		[NSThread detachNewThreadSelector:@selector(concludeDragWithAction:) toTarget:self withObject:[[QSLib actionForIdentifier:action] retain]];
	} else if (lastDragMask & NSDragOperationGeneric) {
		id winController = [[self window] windowController];
		if ([winController isKindOfClass:[QSInterfaceController class]] ) {
			[(QSInterfaceController *)winController invalidateHide];
			[[self window] makeKeyAndOrderFront:self];
		}
		[NSCursor pop];
		[[self window] selectNextKeyView:self];
		[self setObjectValue:[self draggedObject]];
		[self setDraggedObject:nil];
	} else {
		return NO;
	}
	[[self cell] setHighlighted:NO];
	[[self window] makeFirstResponder:self];
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	//	NSLog(@"conclude");
//	NSLog(@"%@", [[NSRunLoop currentRunLoop] currentMode]);
	[self setDragAction:nil];
}

- (void)concludeDragWithAction:(QSAction *)actionObject {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[actionObject performOnDirectObject:[self draggedObject] indirectObject:[self objectValue]];
	[pool release];
}

- (NSString *)dragAction { return dragAction;  }

- (void)setDragAction:(NSString *)aDragAction {
	if (dragAction != aDragAction) {
		[dragAction release];
		dragAction = [aDragAction retain];
	}
}

@end
