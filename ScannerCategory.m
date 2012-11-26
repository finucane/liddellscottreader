//
//  ScannerCategory.m
//  
//
//  Created by David Finucane on 12/9/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ScannerCategory.h"
#import "insist.h"

@implementation NSScanner (ScannerCategory)

- (BOOL) scanPast:(NSString*)s
{
  [self scanUpToString:s intoString:nil];
  return ![self isAtEnd] && [self scanString:s intoString:nil];
}

- (BOOL) scanFrom:(unsigned)startLocation upTo:(unsigned)stopLocation intoString:(NSString**)aString
{
  insist (aString && stopLocation >= startLocation);
  
  NSString*string = [self string];
  insist (string);
  
  if (stopLocation <= startLocation || stopLocation > [string length]) return NO;
  
  *aString = [[string substringWithRange: NSMakeRange (startLocation, stopLocation - startLocation)]
    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  [self setScanLocation: stopLocation == [string length] ? stopLocation - 1: stopLocation];
  
  return YES;
}

- (BOOL) scanPast:(NSString*)s before:(NSString*)stopString
{
  unsigned location = [self scanLocation];
  
  /*find stop location*/
  [self scanUpToString:stopString intoString:nil];
  unsigned stopLocation = [self scanLocation];
  
  /*restore location*/
  [self setScanLocation:location];
  
  [self scanUpToString:s intoString:nil];
   
  /*see if we found something*/
  if (![self isAtEnd] && [self scanLocation] < stopLocation)
  {
    [self scanString:s intoString:nil];
    return YES;
  }
  
  /*not found. restore location*/
  [self setScanLocation: location];
  return NO;
}
@end
