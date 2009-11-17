
#import <Carbon/Carbon.h>
#import "NSEvent+BLTRExtensions.h"

@implementation NSEvent (BLTRExtensions)

+ (NSTimeInterval) doubleClickTime {
#if __LP64__
    return [NSEvent doubleClickInterval];
#else
	return (double) GetDblTime() / 60.0;
#endif
}

- (BOOL)isMouseDown {
    return [self buttonNumber] == NSLeftMouseDown || [self buttonNumber] == NSRightMouseDown || [self buttonNumber] == NSOtherMouseDown;
}

- (int)standardModifierFlags {
	return [self modifierFlags] & (NSCommandKeyMask | NSAlternateKeyMask | NSControlKeyMask | NSShiftKeyMask | NSFunctionKeyMask);
}

@end
