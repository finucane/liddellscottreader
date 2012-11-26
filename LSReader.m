//
//  LSReader.m
//  liddellscottreader
//
//  Created by finucane on 11/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LSReader.h"
#import "ScannerCategory.h"
#import "StringCategory.h"
#import "Entry.h"
#import "insist.h"

#define ITALIC 0x1
#define GREEK 0x2
#define BOLD 0x4
#define END 0x8
#define DEAD 0x10

@implementation LSReader

- (id) initWithFilename:(NSString*)filename
{
  self = [super init];
  insist (self);
  
  /*read the file into a big string*/
  NSError*error = nil;
  
  NSString*s = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
  if (!s)
  {
    NSLog([error localizedDescription]);
    return 0;
  }
  entries = [[NSMutableArray alloc] init];
  scanner = [[NSScanner scannerWithString:s] retain];
  canonicalMap = 0;
  
  return self;
}

- (void) dealloc
{
  if (canonicalMap) free (canonicalMap);
  [offsets release];
  [scanner release];
  [entries release];
  [sortedEntries release];
  [canonical release];
  [dictionary release];
  [super dealloc];
}

/*collect all the beta-code entry keys into an array*/
- (void) readEntries
{
  insist (scanner && entries);
  [scanner setScanLocation:0];
  [entries removeAllObjects];
  
  NSString*s;
  int i = 0;
  while ([scanner scanPast:@"<entryFree"] && [scanner scanPast:@"key=\""] && [scanner scanUpToString:@"\"" intoString:&s])
  {
    s = [[s stringByRemovingCharactersInString:@"0123456789"] lowercaseString];
    [entries addObject:[[[Entry alloc]initWithString:s index:i]autorelease]];
    i++;
  }
  NSLog (@"%d entries read", [entries count]);
}

- (int) examineTag:(NSString*)tag sense:(NSString**)sense
{
  insist (tag);
  int flags = 0;
  
  insist (sense);
  
  if ([tag hasPrefix:@"</"])
    flags |= END;
  if ([tag grep:@"lang=\"greek\""])
    flags |= GREEK;
  if ([tag hasPrefix:@"<orth"])
    flags |= BOLD;
  if ([tag hasPrefix:@"<tr "] ||[tag hasPrefix:@"<tr>"])
    flags |= ITALIC;
    if ([tag hasPrefix:@"<quote "])
    flags |= ITALIC;
  if ([tag hasSuffix:@"/"])
      flags |= DEAD;
  if (sense && [tag hasPrefix:@"<sense"])
  {
    /*use quick and dirty c to get the sense number*/
    const char*s = [tag cStringUsingEncoding:NSUTF8StringEncoding];
    insist (s);
    char*t = strstr (s, "n=\"");
    if (t)
    {
      /*i have no idea why a trailing " is being grabbed and i don't care*/
      char buffer [200];
      if (sscanf (t, "n=\"%s\"", buffer) == 1 && *buffer != 'A')
        *sense = [[NSString stringWithFormat:@"%s", buffer] stringByRemovingCharactersInString:@"\""];
    }
  }
  
  return flags;
}

/*return the index of the word in the original entries list if the word exists, -1 otherwise*/
- (int) lookup:(NSString*)word
{
  insist (word && sortedEntries);
  int a = 0;
  int b = [sortedEntries count] - 1;
  
  word = [word lowercaseString];
  
  while (a != b && a != b + 1 && b != a + 1)
  {
    int c = (a + b) / 2;
    
    Entry*e = [sortedEntries objectAtIndex:c];
    NSComparisonResult r = [[e getWord] compare:word];
    if (r == NSOrderedAscending)
      a = c;
    else if (r == NSOrderedDescending)
      b = c;
    else return [e getIndex];
  }
  Entry*e = [sortedEntries objectAtIndex:a];
  if ([[e getWord] isEqualToString:word])
    return [e getIndex];
  e = [sortedEntries objectAtIndex:b];
  if ([[e getWord] isEqualToString:word])
    return [e getIndex];
  return -1;
}

/*mark up a greek word or phrase into hrefs if possible and add the result to mutable*/
- (void) appendGreek:(NSString*)phrase toString:(NSMutableString*)mutable
{
  insist (phrase && canonical && mutable);
  NSScanner*words = [NSScanner scannerWithString:phrase];
  insist (words);
  
  NSString*s;
  while ([words scanUpToString:@" " intoString:&s])
  {
    s = [s stringByTrimmingString:@""];
    int index = [self lookup:s];
    
    if (index >= 0)
    {
      /*get the index in the canonical ordering*/
      insist (index >= 0 && index < [canonical count]);
      int canonicalIndex = canonicalMap [index];
      
      insist ([[[canonical objectAtIndex:canonicalIndex] getBeta] isEqualToString: [[entries objectAtIndex:index] getWord]]);
      
      [mutable appendString:[NSString stringWithFormat:@"<a href=%d><g> %@ </g></a>", canonicalIndex, s]];
    }
    else
      [mutable appendString:[NSString stringWithFormat:@"<g> %@ </g>", s]];
  }
}


/*find the next entry and return our simple version of it.*/
- (NSString*) convertNextEntry:(int)entryIndex
{
  insist (scanner);
  
  /*make a string to append our text into*/
  NSMutableString*text = [[[NSMutableString alloc] init] autorelease];
  insist (text);
  
  NSString*key;
  
  /*get to the next entry*/
  if (![scanner scanPast:@"<entryFree"] || ![scanner scanPast:@"key=\""] || ![scanner scanUpToString:@"\"" intoString:&key])
    return nil;

  key = [[key stringByRemovingCharactersInString:@"0123456789"] lowercaseString];

  insist ([[[entries objectAtIndex:[dictionary count]] getWord] isEqualToString:key]);
  
  [scanner scanPast:@">"];
  
  /*we have some state about what to do with stuff outside of tags.
    we do these as counts in case some of the stuff can be nested*/
  int greek = 0;
  int bold = 0;
  int italic = 0;
  
  /*keep track of how deep we are in nested tags and what state flags to undo*/
  NSMutableArray*stack = [[[NSMutableArray alloc] init] autorelease];
  insist (stack);
  
  [stack addObject:[NSNumber numberWithInt:0]];

  while ([stack count])
  {
    /*we are just past the end of a tag. collect any text before the next tag*/
    
    NSString*s=nil;
    if ([scanner scanUpToString:@"<" intoString:&s])
    {
      /*there was some new text.*/
      insist (s);
      
      /*add the markup. greek is a fake tag that can be combined with bold so we do it last to make
        it innermost for easy removal.*/
      
      if (italic) [text appendString:@"<i>"];
      if (bold) [text appendString:@"<b>"];
      
      if (greek && !bold)
        [self appendGreek:s toString:text];
      else
      { 
        if (bold) [text appendString:@"<g>"];
        
        [text appendString:@" "];
        [text appendString:s];
        [text appendString:@" "];
        
        if (bold) [text appendString:@"</g>"];
      }
      /*now close the markup*/

      if (bold) [text appendString:@"</b>"];
      if (italic) [text appendString:@"</i>"];
    }
    
    /*now get the next tag*/
    NSString*tag = nil;
    [scanner scanUpToString:@">" intoString:&tag];

    insist (tag);

    [scanner scanPast:@">"];
    
    /*get some details about the tag*/
    NSString*sense = nil;
    int state = [self examineTag:tag sense:sense ? nil : &sense];

    /*if the tag was a sense tag emit the sense number*/
    if (sense)
      [text appendString:[NSString stringWithFormat:@"<b>%@</b>. ", sense]];
    
    if (state & DEAD)
    {
      /*ignore tags that close themselves*/
    }
    else if (state & END)
    {
      /*end tag. pop the top item on the stack, which should be the matching
        start tag for this end tag, and undo any state it might have done.*/
      
      int poppedState = [[stack lastObject] intValue];
      [stack removeLastObject];
      
      insist (!(poppedState & END));
      if (poppedState & GREEK) greek--;
      if (poppedState & ITALIC) italic--;
      if (poppedState & BOLD) bold--;
      insist (greek >= 0 && italic >= 0 && bold >= 0);
    }
    else
    {
      /*it is a start tag. set any state and push it on the stack*/
      if (state & GREEK) greek++;
      if (state & ITALIC) italic++;
      if (state & BOLD) bold++;
      
      [stack addObject:[NSNumber numberWithInt:state]];
    }
  }
  return text;
}

/*make greek-sorted list of words w/out diacrtics*/
- (NSArray*) makeCanonical
{
  insist (entries);
  NSMutableArray*array = [[[NSMutableArray alloc] init] autorelease];
  
  for (int i = 0; i < [entries count]; i++)
  {
    Entry*entry = [entries objectAtIndex:i];
    insist (entry);
    NSString*s = [[entry getWord] stringByRemovingCharactersInString:@"[]*)^(_/=\\+|?'1234567890"];

    /*convert final sigma to just sigma*/
    s = [s stringByReplacing:'j' withChar:'s'];
    
    /*and make sure it's lowercase*/
    s = [s lowercaseString];
    
    /*sometimes there are &lt;'s and the like. get rid of them*/
    s = [s flattenHTML];
    insist ([s length]);
    Entry*e = [[[Entry alloc]initWithString:s index:i]autorelease];
    insist (e);
    [e setBeta: [entry getWord]];
    [array addObject:e];
  }
  
  /*return a sorted array*/
  return [array sortedArrayUsingSelector:@selector (greekCompare:)];
}

- (void) read
{
  insist (scanner && entries);
 
  /*make the list of entries*/
  NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
  [self readEntries];
  [pool release];

  pool = [[NSAutoreleasePool alloc] init];
  
  /*make the sorted list for searching unstripped beta-code words*/
  sortedEntries = [[entries sortedArrayUsingSelector:@selector(compare:)] retain];
  insist (sortedEntries);

  /*now make the list of canonical entries, stripped of diacriticals, also sorted.*/
  [canonical release];
  canonical = [[self makeCanonical] retain];
  [pool release];
  
  canonicalMap = malloc (sizeof (int) * [canonical count]);
  insist (canonicalMap);
  
  for (int i = 0; i < [canonical count]; i++)
  {
    Entry*e = [canonical objectAtIndex:i];
    insist (e);
    int index = [e getIndex];
    insist (index >= 0 && index < [canonical count]);
    canonicalMap [index] = i;
  }

  [dictionary release];
  dictionary = [[NSMutableArray alloc] init];
  insist (dictionary);
  
  /*now go back and read each entry and convert it our format*/
  [scanner setScanLocation:0];
  NSString*s;
  int i = 0;
  pool = [[NSAutoreleasePool alloc] init];
  
  while (s = [self convertNextEntry:i])
  {
    [dictionary addObject:s];
    
    i++;
    [pool release];
    pool = [[NSAutoreleasePool alloc] init];
  }
  [pool release];
  
//  NSLog(@"dictionary count is %d, entries count is %d", [dictionary count], [entries count]);
  
  insist ([dictionary count] >= [entries count]);
}

- (void)changeIndexesToOffsets
{
  for (int i = 0; i < [canonical count]; i++)
  {
    Entry*e = [canonical objectAtIndex:i];
    insist (e);

    int index = [e getIndex];
    [e setIndex: [[offsets objectAtIndex:index] intValue]];
    const char*s = [[dictionary objectAtIndex:index] cStringUsingEncoding:NSUTF8StringEncoding];
    insist (s);
    [e setSize: strlen (s)];
    insist ([[e getBeta] isEqualToString:[[entries objectAtIndex:index] getWord]]);
  }
}

- (void) writeWordsAndOffsets:(const char*)filename
{
  insist (filename && canonical && offsets);
  insist ([offsets count] >= [canonical count]);
  
  unichar previous = 0;
  FILE*fp = 0;

  int entryIndex = 0;

  for (int i = 0; i < [canonical count]; i++)
  {
    Entry*e = [canonical objectAtIndex:i];
    insist (e);
    unichar first = [[e getWord] characterAtIndex:0];
    
    if (!fp || first != previous)
    {
      char buffer [200];
      sprintf (buffer, "%s_%d", filename, [Entry orderOfCharacter:first]);
      if (fp)
      {
        fclose (fp);
        entryIndex++;
      }
      
      fp = fopen (buffer, "w");
      insist (fp);
    }
    entryCounts [entryIndex]++;
    previous = first;
    fprintf (fp, "%s %s %d %d\n", [[e getWord] cStringUsingEncoding:NSUTF8StringEncoding],
             [[e getBeta] cStringUsingEncoding:NSUTF8StringEncoding],
             [e getIndex], [e getSize]);
  }
  fclose (fp);
}


- (void) computeOffsetsAndWriteDictionary:(const char*)filename
{
  insist (filename && dictionary);
  FILE*fp = fopen (filename, "w");
  insist (fp);
  
  [offsets release];
  offsets = [[NSMutableArray alloc] init];
  insist (offsets);
  
  int offset = 0;
  
  for (int i = 0; i < [dictionary count]; i++)
  {
    [offsets addObject: [NSNumber numberWithInt:offset]];
    
    NSString*s = [dictionary objectAtIndex:i];
    insist (s);
    offset += fprintf (fp, "%s\n", [s cStringUsingEncoding:NSUTF8StringEncoding]);
  }
  fclose (fp);
}

- (void) writeEntryCounts:(const char*)filename
{
  insist (filename);
  FILE*fp = fopen (filename, "w");
  insist (fp);
  
  for (int i = 0; i < LSREADER_NUM_GREEK_LETTERS; i++)
    fprintf (fp, "%d\n", entryCounts [i]);
  fclose (fp);
}
@end
