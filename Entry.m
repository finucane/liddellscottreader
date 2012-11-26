//
//  Entry.m
//  liddellscottreader
//
//  Created by David Finucane on 11/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Entry.h"
#import "insist.h"

@implementation Entry
 

- (id) initWithString:(NSString*)s index:(int)anIndex
{
  self = [super init];
  insist (self);
  word = [s retain];
  index = anIndex;
  return self;
}

- (id) initWithWord:(NSString*)aWord beta:(NSString*)aBeta index:(int)anIndex size:(int)aSize
{
  self = [super init];
  insist (self);
  word = [aWord retain];
  beta = [aBeta retain];
  index = anIndex;
  size = aSize;
  return self;
}

- (id) initWithCoder:(NSCoder*)coder
{
  insist (coder);
  self = [super init];
  insist (self);
  
  word = [[coder decodeObjectForKey:@"word"] retain];
  beta = [[coder decodeObjectForKey:@"beta"] retain];
  index = [coder decodeIntForKey:@"index"];
  size = [coder decodeIntForKey:@"size"];
  
  return self;
}

- (void) dealloc
{
  [word release];
  [beta release];
  [super dealloc];
}

/*the greek alphabet sorts slightly differently from ours*/
+ (int) orderOfCharacter:(unichar)c
{
  switch (c)
  {
    case 'a': return 0;
    case 'b': return 1;
    case 'g': return 2;
    case 'd': return 3;
    case 'e': return 4;
    case 'z': return 5;
    case 'h': return 6;
    case 'q': return 7;
    case 'i': return 8;
    case 'k': return 9;
    case 'l': return 10;
    case 'm': return 11;
    case 'n': return 12;
    case 'c': return 13;
    case 'o': return 14;
    case 'p': return 15;
    case 'r': return 16;
    case 's': return 17;
    case 't': return 18;
    case 'u': return 19;
    case 'f': return 20;
    case 'x': return 21;
    case 'y': return 22;
    case 'w': return 23;
    case 'v': return 24;//fucking digamma
    default:
      return -1;
  }
  return -1;
}

/*return 0 if it's *, the uppercase symbol*/
+ (unichar) betaToGreek:(unichar)c uppercase:(BOOL)uppercase
{
  /*try the diacritics first*/
  switch (c)
  {
    case ')': return 0x0313;
    case '(': return 0x0314;
    case '/': return 0x0301;
    case '=': return 0x0342;
    case '\\': return 0x0300;
    case '+': return 0x0308;
    case '|': return 0x0345;
    case '?': return 0x0323;
    case '_': return 0x0304;
    case '^': return 0x0302;
    case '*': return 0;
  }
  
  /*not a diacritic. if it's a letter we know about just look it up.*/
  int order = [self orderOfCharacter:tolower (c)];
  
  /*skip past terminal sigma*/
  if (order >= 17)
    order++;
  
  if (order >= 0)
  {
    return (uppercase ? 0x0391 : 0x03b1) + order;
  }
  
  /*don't know what this is, assume it's punctuation*/
  return c;
}

+ (NSComparisonResult) greekCompare:(NSString*)a b:(NSString*)b
{
  insist (a && b);
  for (int i = 0; i < [a length] && i < [b length]; i++)
  {
    int o1 = [Entry orderOfCharacter: [a characterAtIndex:i]];
    int o2 = [Entry orderOfCharacter: [b characterAtIndex:i]];
    if (o1 < o2) return NSOrderedAscending;
    if (o1 > o2) return NSOrderedDescending;
  }
  if ([a length] <[b length]) return NSOrderedAscending;
  if ([a length] >[b length]) return NSOrderedDescending;
  return NSOrderedSame;
  
}

/*for sorting based on the beta code mapping of the greek alphabet*/
- (NSComparisonResult) greekCompare:(Entry*)entry
{
  return [Entry greekCompare:word b:entry->word];
}

- (NSComparisonResult) compare:(Entry*)entry
{
  return [word compare:entry->word];
}

+ (NSString*) getGreek:(NSString*)beta
{
  insist (beta);
  NSMutableString*s = [[[NSMutableString alloc] init] autorelease];
  insist (s);

  BOOL uppercase = NO;
  
  /*go through and translate char by char beta-code to unicode*/
  for (int i = 0; i < [beta length]; i++)
  {
    unichar c = [self betaToGreek:[beta characterAtIndex:i] uppercase:uppercase];
    if (c == 0)
      uppercase = YES;
    else
    {
      uppercase = NO;
      [s appendFormat:@"%C", c];
    }
  }
  return s;
}


- (NSString*)getGreek
{
  return [Entry getGreek:beta];
}

- (NSString*) getWord
{
  return word;
}

- (int) getIndex
{
  return index;
}
- (void) setIndex:(int)anIndex
{
  index = anIndex;
}
- (void) setSize:(int)aSize
{
  size = aSize;
}
- (int) getSize
{
  return size;
}
- (void) setBeta:(NSString*)aBeta;
{
  [beta release];
  beta = [aBeta retain];
}
- (NSString*)getBeta
{
  return beta;
}
- (void) encodeWithCoder:(NSCoder*)coder
{
  insist (coder);
  [coder encodeObject:word forKey:@"word"];
  [coder encodeObject:beta forKey:@"beta"];
  [coder encodeInt:index forKey:@"index"];
  [coder encodeInt:size forKey:@"size"];
}

@end
