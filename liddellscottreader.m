#import <Foundation/Foundation.h>
#import "LSReader.h"
#import "insist.h"

int main (int argc, const char * argv[])
{
  NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
  
  @try
  {
    if (argc != 5)
    {
      NSLog (@"usage: %s <perseus-filename> <dictionary-filename> <index-basename> <entry-count-filename>", argv [0]);
      return 0;
    }
    
    NSString*filename = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
    LSReader*reader = [[LSReader alloc] initWithFilename:filename];

    insist (reader);

    [reader read];
    [reader computeOffsetsAndWriteDictionary:argv[2]];
    [reader changeIndexesToOffsets];
    [reader writeWordsAndOffsets:argv[3]];
    [reader writeEntryCounts:argv[4]];
                                            
  }
  @catch (NSException*exception)
  {
    NSLog ([NSString stringWithFormat:@"%@%@", [exception name], [exception reason]]);
  }
  [pool drain];
  return 0;
}