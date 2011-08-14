//
//  NRFlag.m
//  NRFlag
//
//  Created by Robert Nix on 2010.11.12.
//  Copyright 2010 nicerobot.org. All rights reserved.
//
#import <objc/runtime.h>
#import "NSArray+charactersFromString.h"
#import "NRFlag.h"
#import "Option.h"
#import "Parameter.h"

@implementation NRFlag

@synthesize program, options, parameters;

Class optionsClass = nil;
NSMutableDictionary* allowed = nil;
id optionsInstance = nil;

-(id) initUsingOptions:(Class)optionsClass_ {
  
  if (!(self = [super init])) {
    return nil;
  }
  
  program = nil;
  options = nil;
  parameters = nil;
  
  if (!optionsClass_) {
    @throw [NSException exceptionWithName:@"NilArgumentException"
                                   reason:@"optionsClass_ must not be null"
                                 userInfo:nil];
  }
  
  optionsClass = optionsClass_;
  
  if (optionsClass) {
    // Obtain a list of all the user's command-line options.
    u_int count;
    objc_property_t* properties = class_copyPropertyList(optionsClass, &count);
    allowed = [NSMutableDictionary dictionaryWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
      NSString *name = [NSString stringWithUTF8String:property_getName(properties[i])];
      // Property names beginning with _ are considered internal.
      if ([name hasPrefix:@"_"]) {
        continue;
      }
      BOOL is_positional = [name hasSuffix:@"$"];
      if (is_positional) {
        name = [name substringToIndex:[name length]-1];
      }
      NSString *attr = [NSString stringWithUTF8String:property_getAttributes(properties[i])];
      //printf("%s\n",[[attr description] UTF8String]);
      
      // Read-only properties are considered internal.
      if (NSNotFound != [attr rangeOfString:@",R,"].location) {
        continue;
      }
      unsigned char type = [attr characterAtIndex:1];
      if ('@' == type) {
        type = [attr hasPrefix:@"T@\"NSMutableArray"]?'A':'S';
      }
      
      // TODO for array-style options, check for array setter _[name]
      //      and wrapper getter to return the array.
      
      NSString *getter = nil;
      NSString *setter = nil;
      {
        for (NSString *at in [attr componentsSeparatedByString: @","]) {
          if ([at hasPrefix:@"G"]) {
            getter = [at substringFromIndex:1];
          } else if ([at hasPrefix:@"S"]) {
            setter = [at substringFromIndex:1];
          }
        }
        
        if (!getter) {
          getter = [NSString stringWithFormat:@"get%@",[name capitalizedString]];
        }
        if (!setter) {
          setter = [NSString stringWithFormat:@"set%@:",[name capitalizedString]];
        }
      }
      
      [allowed setObject:[NSArray arrayWithObjects:[NSString
                                                    stringWithFormat:@"%c",type],
                          getter,
                          setter,
                          is_positional?@"$":@"",
                          nil]
                  forKey:name];
    }
    free(properties);
    
  }
  return self;
}

-(id) initUsingOptionsName:(NSString*)name {
  if (!name) {
    @throw [NSException exceptionWithName:@"NilArgumentException"
                                   reason:@"name must not be null"
                                 userInfo:nil];
  }
  
  return [self initUsingOptions:NSClassFromString(name)];
}  

-(void) parse:(int)argc withArguments:(const char*[])argv {
  
  program = [NSString stringWithUTF8String:argv[0]];
  
  // Construct an instance of the user's options for passing values
  // through to be massaged if needed.
  optionsInstance = [[optionsClass alloc] init];
  
  NSMutableArray *options_ = [NSMutableArray arrayWithCapacity:2];
  NSMutableArray *parameters_ = [NSMutableArray arrayWithCapacity:2];
  
  // Parse the command-line.
  for( int argi=1; argi<argc; argi++ ) {
    NSString *arg = [NSString stringWithUTF8String:argv[argi]];
    NSArray *opt = nil;
    NSString *name = nil;
    NSArray *names = nil;
    id value = [NSNumber numberWithInt:1];
    
    if ('-' == argv[argi][0]) { // option
      BOOL is_long = ('-' == argv[argi][1]);
      if (is_long) { // long
        NSArray *nv = [arg componentsSeparatedByString: @"="];
        name = [[nv objectAtIndex:0] substringFromIndex:2];
        names = [NSArray arrayWithObject:name];
        if (1 < [nv count]) {
          value = [nv objectAtIndex:1];
        } else {
          value = nil;
        }
      } else {
        name = [arg substringFromIndex:1];
        names = [NSArray arrayWithCharactersOfString:name];
      }
      
      // Iterate over the options. If this is a long option, there'll only
      // be one. If the argument is short, there can be multiple.
      for (NSString *n in names) {
        opt = [allowed objectForKey:n];
        if (!opt) {
          if (is_long /* is implied if n>1 char */ && [n hasPrefix:@"no"]) {
            n = [n substringFromIndex:2];
            opt = [allowed objectForKey:n];
            value = [NSNumber numberWithInt:0];
          } 
          if (!opt) {
            fprintf(stderr,"Invalid option: %s\n",[n UTF8String]);
            continue;
          }
        }
        
        //*
        unsigned char type = [[opt objectAtIndex:0] characterAtIndex:0];
        // If there option requires a parameter (is a string or int option),
        // grab the next argument.
        switch (type) {
          case 'A': // NSString*
          case 'S': // NSString*
          case 'i': // int
            if (!is_long && (1+argi)<argc) {
              value = [NSString stringWithUTF8String:argv[++argi]];
            }
            if (!value) {
              fprintf(stderr,"Option requires a parameter: %s\n",[n UTF8String]);
              continue;
            }
            break;
          case 'c': // Boolean
            if (!value) {
              value = [NSNumber numberWithInt:1];
            }
            break;
        }
        
        NSString *option_mode = [opt objectAtIndex:3];
        if ([option_mode length]) {
          n = [NSString stringWithFormat:@"%@%@",n,option_mode];
        }
        
        if (optionsInstance) {
          // Set the parameter.
          switch (type) {
            case 'A': // NSMutableArray*
              break;
            case 'S': // NSString*
              [optionsInstance setValue:value forKey:n];
              break;
            case 'i': // int
              [optionsInstance setValue:[NSNumber numberWithInt:[value intValue]] forKey:n];
              break;
            case 'c': // Boolean
              [optionsInstance setValue:value forKey:n];
              break;
          }
          value = [optionsInstance valueForKey:n];
          //*/
        }
        // TODO All non-positional parameters are global and assocaited with
        //      the intance of this NRFlag.
        [options_ addObject:[Option option:argi type:type withName:n withValue:value]];
      }
    } else { // parameter
      // TODO Parameter is to contain a set of positional options that are
      //      currently in effect for this parameter.
      [parameters_ addObject:[Parameter parameter:argi withValue:arg]];
    }
  }
  
  options = [NSArray arrayWithArray:options_];
  parameters = [NSArray arrayWithArray:parameters_];
}

+(NRFlag*) flagUsingOptions:(Class)optionsClass_ {
  return [[[NRFlag alloc] initUsingOptions:optionsClass_] autorelease];
}

+(NRFlag*) flagUsingOptionsName:(NSString*)name {
  return [NRFlag flagUsingOptions:NSClassFromString(name)];
}

+(NRFlag*) flag:(int)argc
  withArguments:(const char*[])argv
   usingOptions:(Class)optionsClass {
  
  NRFlag *cl = [[[NRFlag alloc] initUsingOptions:optionsClass] autorelease];
  [cl parse:argc withArguments:argv];
  return cl;
}

+(NRFlag*) flag:(int)argc
  withArguments:(const char*[])argv
usingOptionsName:(NSString*)name {
  return [NRFlag flag:argc
        withArguments:argv
         usingOptions:NSClassFromString(name)];
}

+(NRFlag*) flag:(int)argc
  withArguments:(const char*[])argv {
  return [NRFlag flag:argc withArguments:argv usingOptions:nil];
}

+ (NRFlag*) flag:(int)argc,... {
  va_list args;
  va_start(args, argc);
  const char **argv = va_arg(args, const char **);
  va_end(args);
  return [NRFlag flag:argc withArguments:argv usingOptions:nil];
}

-(NSString*) description {
  return [NSString stringWithFormat:@"%@ %@ %@",program,options,parameters];
}

-(NSString*) usage {
  // TODO Organize in a dictionary of arrays per getter.
  //      Each getter will have one or more parameter names.
  //      Call the optionClass' [getter]Description if it exists.
  //      Print the dictionary in alphabetical order.
  return [allowed description];
}
@end
