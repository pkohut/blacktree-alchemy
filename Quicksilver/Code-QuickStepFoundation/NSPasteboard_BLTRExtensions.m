//
// NSPasteboard_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on Sun Nov 09 2003.
// Copyright (c) 2003 Blacktree, Inc.. All rights reserved.
//

#import "NSPasteboard_BLTRExtensions.h"
#import "NSString_BLTRExtensions.h"
#import "NDResourceFork.h"
#import "QSKeyCodeTranslator.h"

void QSForcePaste() {
    CGCharCode charCode = 'v';
	CGKeyCode keyCode = [[QSKeyCodeTranslator translator] keyCodeForCharCode:charCode];

	CGInhibitLocalEvents(YES);
	CGEnableEventStateCombining(NO);

	CGSetLocalEventsFilterDuringSupressionState(kCGEventFilterMaskPermitAllEvents, kCGEventSupressionStateSupressionInterval);

	CGPostKeyboardEvent(kNullCharCode, kVK_Command, true);
	CGPostKeyboardEvent(charCode, keyCode, true);
	CGPostKeyboardEvent(charCode, keyCode, false);
	CGPostKeyboardEvent(kNullCharCode, kVK_Command, false);

	CGEnableEventStateCombining(YES);
	CGInhibitLocalEvents(NO);
}

@implementation NSPasteboard (Clippings)
+ (NSPasteboard *)pasteboardByFilteringClipping:(NSString *)path { // Not thread safe?
//	if (VERBOSE) NSLog(@"Filtering Clipping %@", path);
	NSPasteboard *pboard = [NSPasteboard pasteboardWithUniqueName];

	NDResourceFork *resource = [NDResourceFork resourceForkForReadingAtPath:path];
	NSData *dragData = [resource dataForType:'drag' Id:128];

	NSMutableDictionary *typesDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
	int i;
	ResType type;
	unsigned long resID;
	NSData *resData;
	for (i = 16; i+16 <= [dragData length]; i += 16) {
		[dragData getBytes:&type range:NSMakeRange(i, 4)];
		[dragData getBytes:&resID range:NSMakeRange(i+4, 4)];

		NSString *key = NSFileTypeForHFSTypeCode(type);
	//	NSLog(@"leng %d", [key length]);
		if ([key length] == 6) { //Some strange types yeild short strings
		resData = [resource dataForType:type Id:(short) resID];
			if (resData)
			[typesDictionary setObject:resData forKey:[key encodedPasteboardType]];
		}
	}

	[pboard declareTypes:[typesDictionary allKeys] owner:self];
	NSString *key;
	NSEnumerator *keyEnumerator = [typesDictionary keyEnumerator];
	while(key = [keyEnumerator nextObject])
		[pboard setData:[typesDictionary objectForKey:key] forType:key];

	return [NSPasteboard pasteboardByFilteringTypesInPasteboard:pboard];
}
@end
