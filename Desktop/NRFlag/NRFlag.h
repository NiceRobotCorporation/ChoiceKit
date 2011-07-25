//
//  NRFlag.h
//  NRFlag
//
//  Created by Robert Nix on 2010.11.12.
//  Copyright 2010 nicerobot.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NRFlag : NSObject {

}
@property (readonly) NSString* program;
@property (readonly) NSArray* options;
@property (readonly) NSArray* parameters;

-(id)initUsingOptions:(Class)cl;
-(id)initUsingOptionsName:(NSString*)name;
-(void) parse:(int)argc withArguments:(const char*[])argv;

+(NRFlag*) flagUsingOptions:(Class)optionsClass_;
+(NRFlag*) flagUsingOptionsName:(NSString*)name;  
+(NRFlag*) flag:(int)argc
              withArguments:(const char*[])argv
                usingOptions:(Class)cl;
+(NRFlag*) flag:(int)argc
              withArguments:(const char*[])argv
                usingOptionsName:(NSString*)name;
+(NRFlag*) flag:(int)argc
              withArguments:(const char*[])argv;
+(NRFlag*) flag:(int)argc,...;

-(NSString*) description;
-(NSString*) usage;

@end
