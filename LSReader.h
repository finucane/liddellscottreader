//
//  LSReader.h
//  liddellscottreader
//
//  Created by finucane on 11/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LSREADER_NUM_GREEK_LETTERS 25

@interface LSReader : NSObject
{
  NSScanner*scanner;
  NSMutableArray*entries;
  int*canonicalMap;
  NSArray*sortedEntries;
  NSArray*canonical;
  NSMutableArray*offsets;
  NSMutableArray*dictionary;
  int entryCounts [LSREADER_NUM_GREEK_LETTERS];
}

- (id) initWithFilename:(NSString*)filename;
- (void) read;
- (void) writeWordsAndOffsets:(const char*)filename;
- (void) computeOffsetsAndWriteDictionary:(const char*)filename;
- (void) changeIndexesToOffsets;
- (void) writeEntryCounts:(const char*)filename;
@end
