//
//  StringCategory.m
//  4TrakStudio
//
//  Created by David Finucane on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "StringCategory.h"
#import "insist.h"

@implementation  NSString (StringCategory)


- (NSString *) flattenHTML
{
  NSMutableString*s = [NSMutableString stringWithCapacity:[self length]];
  insist (s);
  
  int numChars = [self length];
  BOOL inTag = NO;
  BOOL inEscape = NO;
  
  for (int i = 0; i < numChars; i++)
  {
    unichar c = [self characterAtIndex:i];
    
    if (c == '<')
      inTag = YES;
    else if(c == '>')
      inTag = NO;
    else if (!inTag && c == '&')
      inEscape = YES;
    else if (!inTag && inEscape && c == ';')
      inEscape = NO;
    else if (!inTag && !inEscape)
      [s appendFormat:@"%C", c];
  }
  
	return s;
}


- (BOOL) grep:(NSString*)s
{
  NSRange r = [self rangeOfString:s];
  return r.location != NSNotFound;
}

- (BOOL) igrep:(NSString*)s
{
  NSRange r = [self rangeOfString:s options:NSCaseInsensitiveSearch];
  return r.location != NSNotFound;
}

- (BOOL) startsWith:(NSString*)s
{
  NSRange r = [self rangeOfString:s];
  return r.location == 0;
}

- (NSString*) stringByTrimmingString:(NSString*)s;
{
  NSMutableString*ms = [NSMutableString stringWithString:self];
  NSCharacterSet*whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  
  int changes;
  do
  {
    changes = 0;
    for (NSRange r = [ms rangeOfCharacterFromSet:whitespace]; !r.location; r = [ms rangeOfCharacterFromSet:whitespace], changes++)
      [ms deleteCharactersInRange:r];
    
    for (NSRange r = [ms rangeOfString:s options:NSCaseInsensitiveSearch]; !r.location; r = [ms rangeOfString:s options:NSCaseInsensitiveSearch], changes++)
      [ms deleteCharactersInRange:r];
    
  } while (changes);
  return ms;
}


- (NSString*) stringByRemovingCharactersInString:(NSString*)s
{
  NSMutableString*ms = [NSMutableString stringWithString:self];
  NSCharacterSet*set = [NSCharacterSet characterSetWithCharactersInString:s];
  
  for (NSRange r = [ms rangeOfCharacterFromSet:set]; r.length; r = [ms rangeOfCharacterFromSet:set])
    [ms deleteCharactersInRange:r];

  return ms;
}

- (NSString *) stringByReplacing:(unichar)original withChar:(unichar)replacement
{
  NSMutableString*s = [NSMutableString stringWithCapacity:[self length]];
  insist (s);
  
  for (int i = 0; i < [self length]; i++)
  {
    unichar c = [self characterAtIndex:i];
    [s appendFormat:@"%C", c == original ? replacement : c];
  }
	return s;
}

@end
