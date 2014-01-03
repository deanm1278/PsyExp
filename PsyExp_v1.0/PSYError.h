//
//  PSYError.h
//  Abstract: custom error domain and constants for PSYExp, and a function to create a new error object.
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/5/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

//PSYExp establishes its own error domain, and some errors in that domain.
extern NSString *PSYErrorDomain;
enum {
    PSYUnknownFileReadError = 1
};

//Given one of the error codes declared above, return an NSError whose user info is set up to match.
NSError *PSYErrorWithCode(NSInteger code);
