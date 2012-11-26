//
//  StringCategory.h
//  4TrakStudio
//
//  Created by David Finucane on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (StringCategory)
- (BOOL) grep:(NSString*)s;
- (BOOL) igrep:(NSString*)s;
- (BOOL) startsWith:(NSString*)s;
- (NSString*) stringByTrimmingString:(NSString*)s;
- (NSString*) stringByRemovingCharactersInString:(NSString*)s;
- (NSString *) flattenHTML;
- (NSString *) stringByReplacing:(unichar)original withChar:(unichar)replacement;
@end
