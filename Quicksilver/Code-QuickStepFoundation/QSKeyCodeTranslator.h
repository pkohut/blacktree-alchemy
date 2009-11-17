//
//  QSKeyCodeTranslator.h
//  Quicksilver
//
//  Created by Alcor on 8/12/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSKeyCodeTranslator : NSObject {

}
+ (id)translator;
- (CGKeyCode)keyCodeForCharCode:(CGCharCode)charCode;
@end
