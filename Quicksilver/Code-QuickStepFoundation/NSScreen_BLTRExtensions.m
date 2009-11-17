//
// NSScreen_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on 12/19/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "NSScreen_BLTRExtensions.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/graphics/IOFramebufferShared.h>
#include <IOKit/graphics/IOGraphicsInterface.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <IOKit/graphics/IOGraphicsTypes.h>
#include <ApplicationServices/ApplicationServices.h>

static void KeyArrayCallback(const void *key, const void *value, void *context) { CFArrayAppendValue(context, key);  }

@implementation NSScreen (BLTRExtensions)

+ (NSScreen *)screenWithNumber:(int)number {
    NSScreen * screen = nil;
    @try {
        screen = [[NSScreen screens] objectAtIndex:number];
    }
    @catch (NSException *e) {
        NSLog(@"Can't find Screen %d", number);
    }
    return screen;
}

- (int)screenNumber {
	return [[NSScreen screens] indexOfObject:self];
} 

- (BOOL)usesOpenGLAcceleration {
	return (BOOL)CGDisplayUsesOpenGLAcceleration([self screenNumber]);
}

- (NSString *)deviceName {
	CFArrayRef langKeys, orderLangKeys;
    CFStringRef langKey;
    io_connect_t displayPort;
    CFDictionaryRef dict, names;
    NSString *localName = nil;
    
	displayPort = CGDisplayIOServicePort([self screenNumber]);
	if ( displayPort == MACH_PORT_NULL )
		return NULL; /* No physical device to get a name from */
	dict = IODisplayCreateInfoDictionary(displayPort, 0);

	names = CFDictionaryGetValue( dict, CFSTR(kDisplayProductName) );
	/* Extract all the display name locale keys */
	langKeys = CFArrayCreateMutable( kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks );
	CFDictionaryApplyFunction( names, KeyArrayCallback, (void *)langKeys );
	/* Get the preferred order of localizations */
	orderLangKeys = CFBundleCopyPreferredLocalizationsFromArray( langKeys );
	CFRelease( langKeys );

	if ( orderLangKeys && CFArrayGetCount(orderLangKeys) ) {
		langKey = CFArrayGetValueAtIndex( orderLangKeys, 0 );
		localName = (NSString*)CFDictionaryGetValue( names, langKey );
        if (localName)
            [[localName retain] autorelease];
	}
	CFRelease(orderLangKeys);
	CFRelease(dict);

	if (!localName) {
		uint32_t model = CGDisplayModelNumber([self screenNumber]);
		uint32_t vendor = CGDisplayVendorNumber([self screenNumber]);
		localName = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Displays/Overrides/DisplayVendorID-%x/DisplayProductID-%x", vendor, model]] objectForKey:@"DisplayProductName"];
		if (!localName) localName = [NSString stringWithFormat:@"Unknown Display (%x:%x)", vendor, model];
	}
	return localName;
}
@end
