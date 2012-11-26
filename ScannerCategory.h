//
//  ScannerCategory.h
//  liddelparser
//
//  Created by David Finucane on 12/9/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSScanner (DFScannerCategory)

- (BOOL) scanPast:(NSString*)s;
- (BOOL) scanFrom:(unsigned)startLocation upTo:(unsigned)stopLocation intoString:(NSString**)aString;
- (BOOL) scanPast:(NSString*)s before:(NSString*)stopString;
@end
