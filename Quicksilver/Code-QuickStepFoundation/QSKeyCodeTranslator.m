//
// QSKeyCodeTranslator.m
// Quicksilver
//
// Created by Alcor on 8/12/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSKeyCodeTranslator.h"

typedef struct {
    short kchrID;
    Str255 KCHRname;
    short transtable[256];
} Char2KeyCodeTable;

enum {
	kTableCountOffset = 256+2,
	kFirstTableOffset = 256+4,
	kTableSize = 128
};

static Char2KeyCodeTable *keytable = NULL;

@implementation QSKeyCodeTranslator

+ (id)translator {
    static QSKeyCodeTranslator * translator = nil;
    
    @synchronized(translator) {
        if (translator == nil)
            translator = [[[self alloc] init] autorelease];
    }
    return translator;
}

#warning 64bit
/* This one uses smScriptKeys key, which is deprecated on 10.6
 * Solution: get the uchr resource, like unicharForKeyCode does, then parse the uchr resource
 * according to documentation at
 * http://developer.apple.com/mac/library/DOCUMENTATION/Carbon/Reference/Unicode_Utilities_Ref/uu_app_uchr/uu_app_uchr.html
 * which ought to be more or less the same that what it does (look for UCKeyToCharTableIndex).
 */
+ (Char2KeyCodeTable *)keyTable {
	unsigned char *theCurrentKCHR, *ithKeyTable;
	short count, i, j, resID;
	Handle theKCHRRsrc;
	ResType rType;
    
#if __LP64__
    return NULL;
#else
    if (keytable == NULL) {
        keytable = malloc(sizeof(Char2KeyCodeTable));
        /* set up our table to all minus ones */
        for (i = 0; i<256; i++) keytable->transtable[i] = -1;
        /* find the current kchr resource ID */
        keytable->kchrID = (short) GetScriptVariable(smCurrentScript, smScriptKeys);
        /* get the current KCHR resource */
        theKCHRRsrc = GetResource('KCHR', keytable->kchrID);
        if (theKCHRRsrc == NULL)
            return NULL;
        GetResInfo(theKCHRRsrc, &resID, &rType, keytable->KCHRname);
        /* dereference the resource */
        theCurrentKCHR = (unsigned char *)(*theKCHRRsrc);
        /* get the count from the resource */
        count = * (short *)(theCurrentKCHR + kTableCountOffset);
        /* build inverse table by merging all key tables */
        for (i = 0; i<count; i++) {
            ithKeyTable = theCurrentKCHR + kFirstTableOffset + (i * kTableSize);
            for (j = 0; j<kTableSize; j++) {
                if ( keytable->transtable[ithKeyTable[j]] == -1)
                    keytable->transtable[ithKeyTable[j]] = j;
            }
        }
    }
#endif
	return keytable;
}

- (CGKeyCode)keyCodeForCharCode:(CGCharCode)charCode {
    Char2KeyCodeTable *table = [[self class] keyTable];
    if (table != NULL && (charCode >= 0 && charCode <= 255))
        return table->transtable[charCode];
	
    return -1;
}

@end
