//
//  PSYDisplay.m
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/6/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import "PSYDisplay.h"

NSString *PSYDisplayItemZonesKey = @"itemZones";
NSString *PSYDisplayItemRotationsKey = @"itemRotations";
NSString *PSYDisplayItemIDsKey = @"itemIDs";
NSString *PSYDisplayItemColorsKey = @"itemColors";
NSString *PSYDisplayConditionKey = @"condition";
NSString *PSYDisplayDisplayIDKey = @"displayID";

@implementation PSYDisplay

@synthesize itemZones = _itemZones;
@synthesize itemRotations = _itemRotations;
@synthesize itemIDs = _itemIDs;
@synthesize itemColors = _itemColors;
@synthesize condition = _condition;
@synthesize displayID = _displayID;

+ (NSArray *)displaysWithProperties:(NSArray *)propertiesArray {
    
    //convert the array of display property dictionaries into an array of displays. Don't assume that property list objects are the right type.
    NSUInteger displayCount = [propertiesArray count];
    NSMutableArray *displays = [[NSMutableArray alloc] initWithCapacity:displayCount];
    for (NSUInteger index = 0; index<displayCount; index++) {
        NSDictionary *properties = [propertiesArray objectAtIndex:index];
        if ([properties isKindOfClass:[NSDictionary class]]) {
            
            //create a new display. If it doesn't work then just do nothing.
            PSYDisplay *display = [[PSYDisplay alloc] initWithProperties:properties];
            [displays addObject:display];
        }
    }
    
    return displays;
}

- (id)initWithProperties:(NSDictionary *)properties {
    
    //Invoke the designated initializer.
    self = [self init];
    if (self) {
        
        //the dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance initializers like this by the way; no one should be observing an uninitialized object.
        Class arrayClass = [NSArray class];
        Class stringClass = [NSString class];
        Class numberClass = [NSNumber class];
        NSArray *itemZonesArray = [properties objectForKey:PSYDisplayItemZonesKey];
        if ([itemZonesArray isKindOfClass:arrayClass]) {
            self.itemZones = itemZonesArray;
        }
        NSArray *itemRotationsArray = [properties objectForKey:PSYDisplayItemRotationsKey];
        if ([itemRotationsArray isKindOfClass:arrayClass]) {
            self.itemRotations = itemRotationsArray;
        }
        NSArray *itemColorsArray = [properties objectForKey:PSYDisplayItemColorsKey];
        if ([itemColorsArray isKindOfClass:arrayClass]) {
            self.itemColors = itemColorsArray;
        }
        NSString *conditionString = [properties objectForKey:PSYDisplayConditionKey];
        if ([conditionString isKindOfClass:stringClass]) {
            self.condition = conditionString;
        }
        NSNumber *displayIDNumber = [properties objectForKey:PSYDisplayDisplayIDKey];
        if ([displayIDNumber isKindOfClass:numberClass]) {
            self.displayID = displayIDNumber;
        }
    }
    return self;
}



@end
