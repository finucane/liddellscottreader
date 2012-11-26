//
//  Entry.h
//  liddellscottreader
//
//  Created by David Finucane on 11/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Entry : NSObject <NSCoding>
{
  NSString*word;
  NSString*beta;
  int index;
  int size;
}

- (id) initWithString:(NSString*)s index:(int)anIndex;
- (id) initWithWord:(NSString*)aWord beta:(NSString*)aBeta index:(int)anIndex size:(int)aSize;
- (NSComparisonResult) compare:(Entry*)entry;
- (NSComparisonResult) greekCompare:(Entry*)entry;
- (NSComparisonResult) greekCompare:(Entry*)entry;
- (NSString*) getWord;
- (int) getIndex;
- (void) setIndex:(int)anIndex;
- (void) setBeta:(NSString*)beta;
- (NSString*)getBeta;
- (void) setSize:(int)size;
- (int) getSize;
- (NSString*) getBeta;
- (NSString*) getGreek;
+ (int) orderOfCharacter:(unichar)c;

+ (NSComparisonResult) greekCompare:(NSString*)a b:(NSString*)b;
+ (unichar) betaToGreek:(unichar)c uppercase:(BOOL)uppercase;
+ (NSString*) getGreek:(NSString*)beta;
@end
