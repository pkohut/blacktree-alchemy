#import "QSTextSource.h"
#import "QSTypes.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"
#import "QSObject_PropertyList.h"

#import "NSUserDefaults_BLTRExtensions.h"
#import "QSLargeTypeDisplay.h"
#import "QSFoundation.h"

#import "QSTextProxy.h"

#import "QSObject_PropertyList.h"
#define textTypes [NSArray arrayWithObjects:@"'TEXT'", @"txt", @"html", @"htm", nil]

#define kQSTextTypeAction @"QSTextTypeAction"

#define kQSTextDiffAction @"QSTextDiffAction"
#define kQSLargeTypeAction @"QSLargeTypeAction"

@implementation QSTextActions

- (QSObject *)showLargeType:(QSObject *)dObject {
	QSShowLargeType([dObject stringValue]);
	return nil;
}

- (QSObject *)showDialog:(QSObject *)dObject {
	[NSApp activateIgnoringOtherApps:YES];
	NSRunInformationalAlertPanel(@"Quicksilver", [dObject stringValue] , @"OK", nil, nil);
	return nil;
}

- (QSObject *)speakText:(QSObject *)dObject {
	NSString *string = [dObject stringValue];
	string = [string stringByReplacing:@"\"" with:@"\\\""];
	string = [NSString stringWithFormat:@"say \"%@\"", string];
	[[[[NSAppleScript alloc] initWithSource:string] autorelease] executeAndReturnError:nil];
	return nil;
}

- (QSObject *)typeObject:(QSObject *)dObject {
	[self typeString2:[dObject objectForType:QSTextType]];
	return nil;
}

- (void)typeString:(NSString *)string {
	int i;
	BOOL upper;
	for (i = 0; i < [string length]; i++) {
        unichar c = [string characterAtIndex:i];
        CGKeyCode code = [[QSKeyCodeTranslator translator] keyCodeForCharCode:c];
//        [self AsciiToKeyCode:s[i]];
		// NSLog(@"%d", code);
		upper = isupper(c);
		if (upper)
            CGPostKeyboardEvent(kNullCharCode, kVK_Shift, true); // shift down
		CGPostKeyboardEvent(c, code, true); // key down
		CGPostKeyboardEvent(c, code, false); // key up
		if (upper)
            CGPostKeyboardEvent(kNullCharCode, kVK_Shift, false); // 'shift up
	}
}

- (void)typeString2:(NSString *)string {
	string = [string stringByReplacing:@"\n" with:@"\r"];
	NSAppleScript *sysEventsScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"System Events" ofType:@"scpt"]] error:nil];
	NSDictionary *errorDict = nil;
	[sysEventsScript executeSubroutine:@"type_text" arguments:string error:&errorDict];
	if (errorDict) NSLog(@"Execute Error: %@", errorDict);
    [sysEventsScript release];
}
@end
