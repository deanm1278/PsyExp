//
//  PSYDisplay.h
//  PsyExp_v1.0
//  Abstract: the display/layout class that creates what will be shown to the participant. This class is not entirely necessary, because the whole step of creating a display object could by bypassed if the exp view just interpreted the property list dictionary on it's own, but if nothing else I suppose haivng a designated display class makes the code a bit more readable.
//
//  Created by Dean Miller on 9/6/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

//keys described down below.
extern NSString *PSYDisplayItemZonesKey;
extern NSString *PSYDisplayItemRotationsKey;
extern NSString *PSYDisplayItemIDsKey;
extern NSString *PSYDisplayItemColorsKey;
extern NSString *PSYDisplayConditionKey;
extern NSString *PSYDisplayDisplayIDKey;


@interface PSYDisplay : NSObject

@property NSArray *itemZones;
@property NSArray *itemRotations;
@property NSArray *itemIDs;
@property NSArray *itemColors;
@property NSString *condition;
@property NSNumber *displayID;

//given an array of property list dictionaries whose validity has not been determined, return an array of displays
+ (NSArray *)displaysWithProperties:(NSArray *)propertiesArray;

- (id)initWithProperties:(NSDictionary *)properties;

/* This class is KVC and KVO compliant for these keys even though they are not used in the current state of the application.
 
 "itemzones" (an NSArray; read-only) the zones the items are to be drawn in.
 
 "itemRotations" (an NSArray; read-only) the rotations the items should have. upright would be 0, pointing to the left would be 1, upside down would be 2, and pointing to the right would be 3.
 
 "itemColors" (an NSArray; read-only) the colors the items should have. 0 = red, 1 = green.
 
 "itemIDs" (an NSArray; read-only) whether each item is a target or a distractor. 0 = distractor, 1 = target.
 
 "zones" (an NSArray; read-only) the location of each zone in the display.
 */

@end
