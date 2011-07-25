//
//  NSArray+charactersFromString.m
//  CommandLine
//
//  Created by Robert Nix on 2010.12.12.
//  Copyright 2010 nicerobot.org. All rights reserved.
//

#import "NSArray+charactersFromString.h"

@implementation NSArray(charactersFromNSString)

+(id)arrayWithCharactersOfString:(NSString*)str {
  NSUInteger l = str?[str length]:0;
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:l];
  for (NSUInteger i=0; i<l; i++) {
    [array addObject:[NSString stringWithFormat:@"%c",[str characterAtIndex:i]]];
  }
  return [self arrayWithArray:array];
}

@end
