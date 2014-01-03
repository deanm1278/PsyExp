//
//  PSYDocument.m
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/3/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import "PSYDocument.h"
#import "PSYWindowController.h"
#import "PSYDataWindowController.h"
#import "PSYDisplay.h"
#import "PSYError.h"
#import "PSYConstants.h"

//String Constants for the trial data we will be saving.
NSString *PSYDocumentTrialDataKey = @"trialData";
NSString *PSYDocumentTrialDataParticipantKey = @"participant";
NSString *PSYDocumentTrialDataReactionTimeKey = @"reactionTime";
NSString *PSYDocumentTrialDataDateRunKey = @"dateRun";
NSString *PSYDocumentTrialDataCorrectKey = @"correct";
NSString *PSYDocumentTrialDataConditionKey = @"condition";
NSString *PSYDocumentTrialDataTrialNumberKey = @"trialNumber";
NSString *PSYDocumentTrialDataSetSizeKey = @"setSize";
NSString *PSYDocumentTrialDataDisplayIDKey = @"displayID";
NSString *PSYDocumentTrialDataEpochKey = @"epoch";
NSString *PSYDocumentTrialDataRotationKey = @"rotation";

//KVO keys
NSString *PSYExpViewEndOfTrialInfoBindingName = @"endOfTrialInfo";

//Keys used in PSYExp's user defaults.
static NSString *PSYAppXDivPreferencesKey = @"xDiv";
static NSString *PSYAppYDivPreferencesKey = @"yDiv";
static NSString *PSYAppNumItems1PreferencesKey = @"numItems1";
static NSString *PSYAppNumItems2PreferencesKey = @"numItems2";
static NSString *PSYAppNumRepeatedPreferencesKey = @"numRepeated";
static NSString *PSYAppNumRandomPreferencesKey = @"numRandom";
static NSString *PSYAppTrialsPerBlockPreferencesKey = @"trialsPerBlock";
static NSString *PSYAppBlocksPerEpochPreferencesKey = @"blocksPerEpoch";
static NSString *PSYAppEpochsPreferencesKey = @"epochs";
static NSString *PSYAppParticipantIDKey = @"participantID";
static NSString *PSYAppRotateAfterNumEpochsKey = @"rotateAfterNumEpochs";
static NSString *PSYAppNumPracticeTrialsKey = @"numPracticeTrials";
static NSString *PSYAppConditionKey = @"condition";

//Document types that must also be used in the application's Info.plist file.
static NSString *PSYDocumentTypeName = @"com.DMM.PSYExp";

//More keys, and a version number, which are just used in PSYExp's property-list-based file format.
static NSString *PSYDocumentVersionKey = @"version";
static NSInteger PSYDocumentCurrentVersion = 1;

//Some methods are invoked by methods above them.
@interface PSYDocument(PSYForwardDeclarations)
- (NSArray *)trialData;
@end

//Shuffling method for NSMutableArray to shuffle displays.
@interface NSMutableArray(shuffling)
- (void)shuffle;
@end

@implementation PSYDocument

@synthesize displays = _displays;
@synthesize trialData = _trialData;
@synthesize startOfTrialInfo = _startOfTrialInfo;

- (id)init
{
    self = [super init];
    if (self) {
        
        //Register for notifications when the participant changes, because we will need to begin a new session.
        NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
        [userDefaultsController addObserver:self forKeyPath:[@"values." stringByAppendingString:PSYAppParticipantIDKey] options:NSKeyValueObservingOptionNew context:nil];
        }
    return self;
}

#pragma mark *** experiment methods ***
- (void)createOldDisplays {
  
    //randomly create the old displays at the beginning of each session to be repeated throughout the experiment.
    
    //pull necessary values from preferences
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSUInteger xDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppXDivPreferencesKey]] integerValue];
    NSUInteger yDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppYDivPreferencesKey]] integerValue];
    NSUInteger numItems1 = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumItems1PreferencesKey]]integerValue];
    NSUInteger numItems2 = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumItems2PreferencesKey]]integerValue];
    NSUInteger trialsPerBlock = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppTrialsPerBlockPreferencesKey]]integerValue];
    NSUInteger numRepeated = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumRepeatedPreferencesKey]]integerValue];
    NSUInteger numRandom = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumRandomPreferencesKey]]integerValue];
    NSUInteger numZones = xDiv * yDiv;
    
    //randomly choose active zones
    NSMutableArray *targetZones = [self UniqueRandIntArrayWithNumItems:trialsPerBlock inRange:numZones];
    
    NSIndexSet *oldTargetZoneIndexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, numRepeated)];
    NSArray *oldTargetZones = [targetZones objectsAtIndexes:oldTargetZoneIndexSet];
    
    //the rest of the randomly generated zone numbers will be the target locations for the new displays.
    NSIndexSet *newTargetZoneIndexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(numRepeated, numRandom)];
    _newDisplayTargetZones = [targetZones objectsAtIndexes:newTargetZoneIndexSet];
    
    NSMutableArray *displaysPropertyListsMutableArray = [[NSMutableArray alloc] initWithCapacity:numRepeated];
    
    //Half of the repeated displays will have the number of items specified in 'Number of Items: Category 1' in the preferences, and the other half will have the number of items specified in 'Number of Items: Category 2'.
    
    int displayNumber = 1;
    int targetZoneIndex = 0;
    for (NSInteger index=0; index<numRepeated/2; index++) {
        
        //randomly generate active zones with the target zone at the head and the distractor zones following.
        NSNumber *target = [oldTargetZones objectAtIndex:targetZoneIndex];
        NSMutableArray *activeZones = [self UniqueRandIntArrayWithNumItems:numItems1 inRange:numZones withLead:target];
        
        //randomly choose rotation codes 0 - 3 for each display
        NSMutableArray *rotations = [self RandIntArrayWithNumItems:numItems1 inRange:ROTATION_RANGE];
    
        //randomly choose color codes 0 - 1 for each display
        NSMutableArray *colors = [self RandIntArrayWithNumItems:numItems1 inRange:COLOR_RANGE];
        
        //set the displays ID number.
        NSNumber *displayID = [NSNumber numberWithInt:displayNumber];
        
        //create the property list dictionaries from the created arrays and add to the aggregate list.
        NSDictionary *displayPropertyList = [NSDictionary dictionaryWithObjectsAndKeys:activeZones, PSYDisplayItemZonesKey,
                                             rotations, PSYDisplayItemRotationsKey, colors, PSYDisplayItemColorsKey, @"old", PSYDisplayConditionKey, displayID, PSYDisplayDisplayIDKey, nil];
        [displaysPropertyListsMutableArray addObject: displayPropertyList];
        displayNumber++;
        targetZoneIndex++;
    }
    
    for (NSInteger index=0; index<numRepeated/2; index++) {
        //randomly generate active zones with the target zone at the head and the distractor zones following.
        NSNumber *target = [oldTargetZones objectAtIndex:targetZoneIndex];
        NSMutableArray *activeZones = [self UniqueRandIntArrayWithNumItems:numItems2 inRange:numZones withLead:target];
        
        //randomly choose rotation codes 0 - 3 for each display
        NSMutableArray *rotations = [self RandIntArrayWithNumItems:numItems2 inRange:ROTATION_RANGE];
        
        //randomly choose color codes 0 - 1 for each display
        NSMutableArray *colors = [self RandIntArrayWithNumItems:numItems2 inRange:COLOR_RANGE];
        
        //set display ID number
        NSNumber *displayID = [NSNumber numberWithInt:displayNumber];
        
        //create the property list dictionaries from the created arrays and add to the aggregate list.
        NSDictionary *displayPropertyList = [NSDictionary dictionaryWithObjectsAndKeys:activeZones, PSYDisplayItemZonesKey,
                                             rotations, PSYDisplayItemRotationsKey, colors, PSYDisplayItemColorsKey, @"old", PSYDisplayConditionKey, displayID, PSYDisplayDisplayIDKey, nil];
        [displaysPropertyListsMutableArray addObject: displayPropertyList];
        displayNumber++;
        targetZoneIndex++;
    }
    
    //create static array and pass to the displays class.
    NSArray *displaysPropertyListsArray = [NSArray arrayWithArray:displaysPropertyListsMutableArray];
    NSArray *displays = [PSYDisplay displaysWithProperties:displaysPropertyListsArray];
    
    //Lazily instantiate the old displays array.
    if (displays && !_oldDisplays) {
        _oldDisplays = [NSMutableArray arrayWithArray:displays];
    } else {
        _oldDisplays = nil;
        _oldDisplays = [NSMutableArray arrayWithArray:displays];
    }
}

- (void)createNewDisplays {
    
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSUInteger numRandom = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumRandomPreferencesKey]]integerValue];
    NSUInteger numItems1 = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumItems1PreferencesKey]]integerValue];
    NSUInteger numItems2 = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumItems2PreferencesKey]]integerValue];
    NSUInteger xDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppXDivPreferencesKey]] integerValue];
    NSUInteger yDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppYDivPreferencesKey]] integerValue];
    NSUInteger numZones = xDiv * yDiv;
    
    //randomly create the new displays at the beginning of each block. Same as the old displays, half will have numItems1 and the other half will have numItems2.
    
    NSMutableArray *displaysPropertyListsMutableArray = [[NSMutableArray alloc] initWithCapacity:numRandom];
    
    int targetZoneIndex = 0;
    for (NSInteger index=0; index<numRandom/2; index++) {
        //randomly generate active zones with the target zone at the head and the distractor zones following.
        NSNumber *target = [_newDisplayTargetZones objectAtIndex:targetZoneIndex];
        NSMutableArray *activeZones = [self UniqueRandIntArrayWithNumItems:numItems1 inRange:numZones withLead:target];
        
        //randomly choose rotation codes 0 - 3 for each display
        NSMutableArray *rotations = [self RandIntArrayWithNumItems:numItems1 inRange:ROTATION_RANGE];
        
        //randomly choose color codes 0 - 1 for each display
        NSMutableArray *colors = [self RandIntArrayWithNumItems:numItems1 inRange:COLOR_RANGE];
        
        //set the display ID number. Since these displays are randomly generated we will just set the display as NaN.
        NSNumber *displayID = [NSNumber numberWithInt:NAN];
        
        //create the property list dictionaries from the created arrays and add to the aggregate list.
        NSDictionary *displayPropertyList = [NSDictionary dictionaryWithObjectsAndKeys:activeZones, PSYDisplayItemZonesKey,
                                             rotations, PSYDisplayItemRotationsKey, colors, PSYDisplayItemColorsKey, @"new", PSYDisplayConditionKey, displayID, PSYDisplayDisplayIDKey, nil];
        [displaysPropertyListsMutableArray addObject: displayPropertyList];
        targetZoneIndex++;
    }
    for (NSInteger index=0; index<numRandom/2; index++) {
        //randomly generate active zones with the target zone at the head and the distractor zones following.
        NSNumber *target = [_newDisplayTargetZones objectAtIndex:targetZoneIndex];
        NSMutableArray *activeZones = [self UniqueRandIntArrayWithNumItems:numItems2 inRange:numZones withLead:target];
        
        //randomly choose rotation codes 0 - 3 for each display
        NSMutableArray *rotations = [self RandIntArrayWithNumItems:numItems2 inRange:ROTATION_RANGE];
        
        //randomly choose color codes 0 - 1 for each display
        NSMutableArray *colors = [self RandIntArrayWithNumItems:numItems2 inRange:COLOR_RANGE];
        
        //set the display ID number. Since these displays are randomly generated we will just set the display as NaN.
        NSNumber *displayID = [NSNumber numberWithInt:NAN];
        
        //create the property list dictionaries from the created arrays and add to the aggregate list.
        NSDictionary *displayPropertyList = [NSDictionary dictionaryWithObjectsAndKeys:activeZones, PSYDisplayItemZonesKey,
                                             rotations, PSYDisplayItemRotationsKey, colors, PSYDisplayItemColorsKey, @"new", PSYDisplayConditionKey, displayID, PSYDisplayDisplayIDKey, nil];
        [displaysPropertyListsMutableArray addObject: displayPropertyList];
        targetZoneIndex++;
    }
    //create static array and pass to the displays class.
    NSArray *displaysPropertyListsArray = [NSArray arrayWithArray:displaysPropertyListsMutableArray];
    NSArray *displays = [PSYDisplay displaysWithProperties:displaysPropertyListsArray];
    
    //Again, lazily instantiate.
    if (displays && !_newDisplays) {
        _newDisplays = [NSMutableArray arrayWithArray:displays];
    } else {
        _newDisplays = nil;
        _newDisplays = [NSMutableArray arrayWithArray:displays];
    }
}

- (void)createPracticeDisplays {
    //create random displays to be used in the practice trials.
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSUInteger numItems1 = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumItems1PreferencesKey]]integerValue];
    NSUInteger numItems2 = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumItems2PreferencesKey]]integerValue];
    NSUInteger xDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppXDivPreferencesKey]] integerValue];
    NSUInteger yDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppYDivPreferencesKey]] integerValue];
    NSInteger numPracticeTrials = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumPracticeTrialsKey]] integerValue];
    NSUInteger numZones = xDiv * yDiv;
    
    //randomly create the new displays at the beginning of each block. Same as the old displays, half will have numItems1 and the other half will have numItems2.
    
    NSMutableArray *displaysPropertyListsMutableArray = [[NSMutableArray alloc] initWithCapacity:numPracticeTrials];
    NSMutableArray *practiceTrialsTargetZones = [self UniqueRandIntArrayWithNumItems:numPracticeTrials inRange:numZones];
    
    int targetZoneIndex = 0;
    for (NSInteger index=0; index<numPracticeTrials/2; index++) {
        //randomly generate active zones with the target zone at the head and the distractor zones following.
        NSNumber *target = [practiceTrialsTargetZones objectAtIndex:targetZoneIndex];
        NSMutableArray *activeZones = [self UniqueRandIntArrayWithNumItems:numItems1 inRange:numZones withLead:target];
        
        //randomly choose rotation codes 0 - 3 for each display
        NSMutableArray *rotations = [self RandIntArrayWithNumItems:numItems1 inRange:ROTATION_RANGE];
        
        //randomly choose color codes 0 - 1 for each display
        NSMutableArray *colors = [self RandIntArrayWithNumItems:numItems1 inRange:COLOR_RANGE];
        
        //set the display ID number. Since these displays are randomly generated we will just set the display as NaN.
        NSNumber *displayID = [NSNumber numberWithInt:NAN];
        
        //create the property list dictionaries from the created arrays and add to the aggregate list.
        NSDictionary *displayPropertyList = [NSDictionary dictionaryWithObjectsAndKeys:activeZones, PSYDisplayItemZonesKey,
                                             rotations, PSYDisplayItemRotationsKey, colors, PSYDisplayItemColorsKey, @"new", PSYDisplayConditionKey, displayID, PSYDisplayDisplayIDKey, nil];
        [displaysPropertyListsMutableArray addObject: displayPropertyList];
        targetZoneIndex++;
        
    }
    for (NSInteger index=0; index<numPracticeTrials/2; index++) {
        //randomly generate active zones with the target zone at the head and the distractor zones following.
        NSNumber *target = [practiceTrialsTargetZones objectAtIndex:targetZoneIndex];
        NSMutableArray *activeZones = [self UniqueRandIntArrayWithNumItems:numItems2 inRange:numZones withLead:target];
        
        //randomly choose rotation codes 0 - 3 for each display
        NSMutableArray *rotations = [self RandIntArrayWithNumItems:numItems2 inRange:ROTATION_RANGE];
        
        //randomly choose color codes 0 - 1 for each display
        NSMutableArray *colors = [self RandIntArrayWithNumItems:numItems2 inRange:COLOR_RANGE];
        
        //set the display ID number. Since these displays are randomly generated we will just set the display as NaN.
        NSNumber *displayID = [NSNumber numberWithInt:NAN];
        
        //create the property list dictionaries from the created arrays and add to the aggregate list.
        NSDictionary *displayPropertyList = [NSDictionary dictionaryWithObjectsAndKeys:activeZones, PSYDisplayItemZonesKey,
                                             rotations, PSYDisplayItemRotationsKey, colors, PSYDisplayItemColorsKey, @"new", PSYDisplayConditionKey, displayID, PSYDisplayDisplayIDKey, nil];
        [displaysPropertyListsMutableArray addObject: displayPropertyList];
        targetZoneIndex++;
    }
    
    //create static array and pass to the displays class.
    NSArray *displaysPropertyListsArray = [NSArray arrayWithArray:displaysPropertyListsMutableArray];
    NSArray *displays = [PSYDisplay displaysWithProperties:displaysPropertyListsArray];
    
    //Again, lazily instantiate.
    if (displays && !_newDisplays) {
        _newDisplays = [NSMutableArray arrayWithArray:displays];
    } else {
        _newDisplays = nil;
        _newDisplays = [NSMutableArray arrayWithArray:displays];
    }
}

- (void)beginPracticeTrials {
    //Check to see that the preferences are set correctly. If they are not, send the user an alert. If they are correct, begin the experiment.
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSUInteger trialsPerBlock = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppTrialsPerBlockPreferencesKey]]integerValue];
    NSUInteger numRepeated = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumRepeatedPreferencesKey]]integerValue];
    NSUInteger numRandom = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumRandomPreferencesKey]]integerValue];
    NSUInteger rotateAfterNumEpochs = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppRotateAfterNumEpochsKey]]integerValue];
    NSUInteger epochs = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppEpochsPreferencesKey]]integerValue];
    
    //Check that user defaults are set correctly.
    if (numRandom + numRepeated != trialsPerBlock) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Preferences incorrectly set." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The number of repeated displays plus the number of random displays must be equal to the number of trials per block. Please return to the preferences panel and set these variables accordingly"];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:nil contextInfo:nil];
    } else if (rotateAfterNumEpochs > epochs) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Preferences incorrectly set." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The number of epochs to rotate after cannot be greater than the total number of epochs in the experiment. If you wish to have no rotation, set the number of epochs to rotate after equal to the total number of epochs in the study."];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:nil contextInfo:nil];
    }else {
        currentTrialNumber = 0;
        [self createPracticeDisplays];
        if (!_displays) {
            _displays = [NSMutableArray array];
        }
        
        //No old displays array will tell the system that we need to begin a new session. Another kinda shitty programming workaround since I had to add in support for practice trials after the fact, but it should work here.
        if (_oldDisplays) {
            _oldDisplays = nil;
        }
        [_displays addObjectsFromArray:_newDisplays];
        [self newPracticeTrial];
    }
}

- (void)beginSession {
    //Check to see that the preferences are set correctly. If they are not, send the user an alert. If they are correct, begin the experiment.
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSUInteger trialsPerBlock = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppTrialsPerBlockPreferencesKey]]integerValue];
    NSUInteger numRepeated = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumRepeatedPreferencesKey]]integerValue];
    NSUInteger numRandom = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumRandomPreferencesKey]]integerValue];
    NSUInteger rotateAfterNumEpochs = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppRotateAfterNumEpochsKey]]integerValue];
    NSUInteger epochs = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppEpochsPreferencesKey]]integerValue];
    
    //check again that user defaults are set correctly because why not.
    if (numRandom + numRepeated != trialsPerBlock) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Preferences incorrectly set." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The number of repeated displays plus the number of random displays must be equal to the number of trials per block. Please return to the preferences panel and set these variables accordingly"];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:nil contextInfo:nil];
    } else if (rotateAfterNumEpochs > epochs) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Preferences incorrectly set." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The number of epochs to rotate after cannot be greater than the total number of epochs in the experiment. If you wish to have no rotation, set the number of epochs to rotate after equal to the total number of epochs in the study."];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:nil contextInfo:nil];
    }else {
            
        //begins a new session with a new participant.
        currentTrialNumber = 0;
        [self createOldDisplays];
        [self beginNewBlock];
    }
}

- (void)newPracticeTrial {
    if (!_startOfTrialInfo) {
        _startOfTrialInfo = [[NSMutableDictionary alloc] init];
    }
    
    //Use manual change notification for the startOfTrialInfo key. Not usually the best practice, but in this case it should not cause any problems.
    [self willChangeValueForKey:@"startOfTrialInfo"];
    [_startOfTrialInfo removeAllObjects];
    
    currentTrialNumber++;
    
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSInteger numPracticeTrials = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppNumPracticeTrialsKey]] integerValue];
    NSNumber *state;
    NSNumber *currentDisplayNumber;
    NSNumber *rotation;
    
    if (currentTrialNumber > numPracticeTrials) {
        //we have reached the end of the practice trials.
        state = [NSNumber numberWithInteger:END_OF_PRACTICE];
        _practice = NO;
    } else {
        state = [NSNumber numberWithInteger:DISPLAY];
    }
    
    rotation = [NSNumber numberWithInt:NOT_ROTATED];
    currentDisplayNumber = [NSNumber numberWithInteger:currentTrialNumber-1];
    
    //Randomly generate target color each round.
    NSNumber *targetColor = [NSNumber numberWithInt:arc4random_uniform(COLOR_RANGE)];
    NSNumber *displayNum = currentDisplayNumber;
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:displayNum, @"currentDisplayNumber", targetColor, @"targetColor", rotation, @"rotation", state, @"state", nil];
    [_startOfTrialInfo setDictionary:info];
    [self didChangeValueForKey:@"startOfTrialInfo"];
}

- (void)beginNewBlock {
    
    //begins a new block of trials.
    [self createNewDisplays];
    
    //lazily instantiate master displays array.
    NSMutableArray *array = [NSMutableArray array];
    if (!_displays) {
        _displays = [[NSMutableArray alloc] init];
    }
    [_displays removeAllObjects];
    [array addObjectsFromArray:_oldDisplays];
    
    [array addObjectsFromArray:_newDisplays];
    
    [array shuffle];
    [self insertDisplays:array atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [array count])]];
    
    [self beginNewTrial];
}

- (void)beginNewTrial {
    
    //Processes a trial
    if (!_startOfTrialInfo) {
        _startOfTrialInfo = [[NSMutableDictionary alloc] init];
    }
    
    //Use manual change notification for the startOfTrialInfo key. Not usually the best practice, but in this case it should not cause any problems.
    [self willChangeValueForKey:@"startOfTrialInfo"];
    [_startOfTrialInfo removeAllObjects];
    
    currentTrialNumber++;
    
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSInteger trialsPerBlock = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppTrialsPerBlockPreferencesKey]] integerValue];
    NSInteger blocksPerEpoch = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppBlocksPerEpochPreferencesKey]] integerValue];
    NSInteger epochs = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppEpochsPreferencesKey]] integerValue];
    NSInteger rotateAfterNumEpochs = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppRotateAfterNumEpochsKey]]integerValue];
    NSInteger condition = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppConditionKey]]integerValue];
    NSNumber *state;
    NSInteger currentDisplayNumber;
    NSNumber *rotation;
    
    
    //Figure out what state of the experiment we are in, and set that in the startOfTrialInfo dictionary. No information is sent directly from one object to another, it is all done through KVO. Also set in the dictionary what number display we should be on as well as the color of the target and the rotation of the display.
    if ((currentTrialNumber-1) % trialsPerBlock == 0 && currentTrialNumber != 1 && !_restPeriod) {
        
        if (currentTrialNumber > trialsPerBlock * blocksPerEpoch * epochs) {
            //We are at the end of a session.
            state = [NSNumber numberWithInteger:END_OF_SESSION];
        } else {
            //We are at the end of a block.
            state = [NSNumber numberWithInteger:END_OF_BLOCK];
            _restPeriod = YES;
            currentTrialNumber--;
        }
    } else {
        _restPeriod = NO;
        state = [NSNumber numberWithInteger:DISPLAY];
    }
    
    if (rotateAfterNumEpochs*blocksPerEpoch*trialsPerBlock < currentTrialNumber && condition != PILOT) {
        rotation = [NSNumber numberWithInt:ROTATED];
    } else {
    rotation = [NSNumber numberWithInt:NOT_ROTATED];
    }
    currentDisplayNumber = (currentTrialNumber-1) % trialsPerBlock;
        
    //Randomly generate target color each round.
    NSNumber *targetColor = [NSNumber numberWithInt:arc4random_uniform(COLOR_RANGE)];
    NSNumber *displayNum = [NSNumber numberWithInteger:currentDisplayNumber];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:displayNum, @"currentDisplayNumber", targetColor, @"targetColor", rotation, @"rotation", state, @"state", nil];
    [_startOfTrialInfo setDictionary:info];
    [self didChangeValueForKey:@"startOfTrialInfo"];
    
}

#pragma mark *** KVO methods ***

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    
    if ([keyPath isEqualToString:PSYExpViewEndOfTrialInfoBindingName]) {
        
        //We have received a notification that the information we are observing in the display has changed. This may mean either that the user has signaled to start a new block (or session), or that there is new information about the outcome of a trial.
    
        NSArray *info = [change valueForKey:NSKeyValueChangeNewKey];
        
        if ([info isKindOfClass:[NSMutableDictionary class]]) {
            NSString *signal = [info valueForKey:@"signal"];
            if (signal) {
                if ([signal isEqualToString:@"inputBeforeSessionStart"]) {
                    [self beginPracticeTrials];
                    _practice = YES;
                    
                } else if ([signal isEqualToString:@"inputAfterRestPeriod"]) {
                    if (!_oldDisplays) {
                        //if there are no old displays, we must be at the end of the practice trials.
                        [self beginSession];
                    } else if (_oldDisplays) {
                        [self beginNewBlock];
                    }
                }
            } else {
                //no signal has been set, it is a regular trial. Get info and record.
                NSNumber *reactionTime = [NSNumber numberWithFloat:[[info valueForKey:@"reactionTime"] floatValue]];
                NSNumber *correct = [NSNumber numberWithBool:[[info valueForKey:@"correct"] boolValue]];
            
                //record the trial in our array of trial data.
                if (!_practice) {
                    [self recordTrial:reactionTime correct:correct];
                    [self beginNewTrial];
                } else if (_practice) {
                    [self newPracticeTrial];
                }
            }
        }
        
    } else if ([keyPath isEqualToString:[@"values." stringByAppendingString:PSYAppParticipantIDKey]]) {
        
        //The user has changed the participant number, this means a new session should begin. Set the necessary information so that the display can observe it and display the correct information.
        if (!_startOfTrialInfo) {
            _startOfTrialInfo = [[NSMutableDictionary alloc] init];
        }

        [self willChangeValueForKey:@"startOfTrialInfo"];
        NSNumber *state = [NSNumber numberWithInteger:NOT_RUNNING];
        [_startOfTrialInfo setObject:state forKey:@"state"];
        [self didChangeValueForKey:@"startOfTrialInfo"];
        
    }
    else {
        // In overrides of -observeValueForKeyPath:ofObject:change:context: always invoke super when the observer notification isn't recognized. Code in the superclass is apparently doing observation of it's own. NSObject's implementation of this method throws an excpetion. Such an exception would be indicating a programming error that should be fixed.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark ***Private KVC-compliance for public properties***
//The methods of the format below are necessary to ensure KVC/KVO compliance. Not really used currently but I will put them in just in case.

- (void)insertDisplays:(NSArray *)displays atIndexes:(NSIndexSet *)indexes {
    //do actual insertion. Instantiate displays array lazily.
    if (!_displays) {
        _displays = [[NSMutableArray alloc] init];
    }
    [_displays insertObjects:displays atIndexes:indexes];
    
}

- (void)removeDisplaysAtIndexes:(NSIndexSet *)indexes {
    //find out what displays are being removed. We lazily create the displays array if necessary even though it should never be necessary, just so a helpful exception will be thrown if this method is being misused.
    if (!_displays) {
        _displays = [[NSMutableArray alloc] init];
    }
    
    //Do actual removal
    [_displays removeObjectsAtIndexes:indexes];
}

- (void)insertTrialData:(NSArray *)trialData atIndexes:(NSIndexSet *)indexes {
    //do actual insertion. Instantiate trialData array lazily.
    if (!_trialData) {
        _trialData = [[NSMutableArray alloc] init];
        }
    [_trialData insertObjects:trialData atIndexes:indexes];
    
    //May need to point each trial back to document that owns it. Refer to Sketch example
}

- (void)removeTrialDataAtIndexes:(NSIndexSet *)indexes {
    //find out what trials are being removed. We lazily create the trialData array if necessary even though it should never be necessary, just so a helpful exception will be thrown if this method is being misused.
    if (!_trialData) {
        _trialData = [[NSMutableArray alloc] init];
    }
    //Do actual removal
    [_trialData removeObjectsAtIndexes:indexes];
}

#pragma mark *** Trial Methods ***

-(void)recordTrial:(NSNumber *)reactionTime correct:(NSNumber *)correct {
    
    //Create a dictionary of the trial that has just been completed and add it into our trial array.
    
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    
     NSUInteger trialsPerBlock = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppTrialsPerBlockPreferencesKey]] integerValue];
    NSUInteger blocksPerEpoch = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppBlocksPerEpochPreferencesKey]] integerValue];
    NSUInteger rotateAfterNumEpochs = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppRotateAfterNumEpochsKey]] integerValue];
    
    int epoch = ceilf((float)currentTrialNumber/(float)trialsPerBlock/(float)blocksPerEpoch);
    NSUInteger currentDisplayNumber = (currentTrialNumber-1) % trialsPerBlock;
    PSYDisplay *currentDisplay = [_displays objectAtIndex:currentDisplayNumber];
    
    NSString *condition = [NSString stringWithString:currentDisplay.condition];
    NSNumber *participant = [NSNumber numberWithInt:[[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppParticipantIDKey]] intValue]];
    NSDate *dateRun = [NSDate date];
    NSNumber *trialNumber = [NSNumber numberWithInteger:currentTrialNumber];
    NSNumber *setSize = [NSNumber numberWithInteger:[currentDisplay.itemZones count]];
    NSNumber *displayID = currentDisplay.displayID;
    NSNumber *epochNumber = [NSNumber numberWithInt:epoch];
    
    NSNumber *rotation;
    if (rotateAfterNumEpochs*blocksPerEpoch*trialsPerBlock < currentTrialNumber) {
        rotation = [NSNumber numberWithInt:ROTATED];
    } else {
        rotation = [NSNumber numberWithInt:NOT_ROTATED];
    }
    
    NSDictionary *trial = [NSDictionary dictionaryWithObjectsAndKeys:
                           participant, PSYDocumentTrialDataParticipantKey,
                           reactionTime, PSYDocumentTrialDataReactionTimeKey,
                           correct, PSYDocumentTrialDataCorrectKey,
                           condition, PSYDocumentTrialDataConditionKey,
                           dateRun, PSYDocumentTrialDataDateRunKey,
                           trialNumber, PSYDocumentTrialDataTrialNumberKey,
                           setSize, PSYDocumentTrialDataSetSizeKey,
                           displayID, PSYDocumentTrialDataDisplayIDKey,
                           epochNumber, PSYDocumentTrialDataEpochKey,
                           rotation, PSYDocumentTrialDataRotationKey, nil];
    if (!_trialData) {
        _trialData = [[NSMutableArray alloc] init];
    }
    [_trialData addObject:trial];
    
    
}

#pragma mark ***Overrides of NSDocument Methods***

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
   
    // This application's Info.plist only declares one document type, which goes by the name: PSYDocumentName FIXIT. Use -[NSWorkspace type:conformsToType:] to work with UTI
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    BOOL readSuccessfully;
    NSArray *trialData = nil;
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    BOOL useTypeConformance = [workspace respondsToSelector:@selector(type:conformsToType:)];
    
    if ((useTypeConformance && [workspace type:typeName conformsToType:PSYDocumentTypeName])) {
        
        //this is the correct file format. Read in the property list.
        NSDictionary *properties = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
        
        if (properties) {
            //Get the trialData. Strictly speaking the property list of an empty document should have an empty trialData array, not no trialData array, but we cope easily with either. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources.
            NSArray *trialsPropertyArray = [properties objectForKey:PSYDocumentTrialDataKey];
            trialData = [NSArray arrayWithArray:trialsPropertyArray];
        
        } else if (outError) {
            //if property list parsing fails we have no choice but to admit that we don't know what went wrong. The error description returned by +[NSPropertyListSerialization propertyListFromData:mutabilityOption:format:errorDescription:] would be pretty technical, and not the sort of thing we should show to a user.
            *outError = PSYErrorWithCode(PSYUnknownFileReadError);
        }
        readSuccessfully = properties ? YES : NO;
    
    } else {
        NSLog(@"Error in readFromData:");
        readSuccessfully = NO;
        *outError = PSYErrorWithCode(PSYUnknownFileReadError);
    }
    
    // Did the reading work? in this method we ought to either do nothing and return an error or overwrite every property of the document. Don't leave the document in a half baked state.
    if (readSuccessfully) {
        //update this document's list of trials by going through KVC-compliant mutation methods. KVO notifications will be automatically sent to observers (which does matter, because this might be happening at some time other than document opening; reverting, for instance).
        if (!_trialData) {
            _trialData = [NSArray arrayWithArray:trialData];
        } else {
            [_trialData removeAllObjects];
            [_trialData addObjectsFromArray:trialData];
        }
    } //else it was the responsibility of something in the previous paragraph to set *outError.
    return readSuccessfully;
    
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // This method must be prepared for typeName to be any value that might be in the array returned by an invocation of -writable types for save operation:. Because this class:
    // doesn't - override -writableTypesForSaveOperation: , and
    // doesn't - override +writableTypes or +isNativeType: (which the default implementation of -writableTypesForSaveOperation: invokes),
    // and because:
    // - PSYExp has a "Save a Copy As" file menu item that results in NSSaveToOperations,
    // we know that the type names we have to handle here include:
    // - PSYDocumentTypeName, because this applications's Info.plist file declares that instances of this class can play the "editor" role for it, and
    // - CSV because according to the Info.plist a PSYExp document is exportable as that. This is the file that will be used in analysis because pandas, excel, spss, etc. are all well equipped to work with this file type.
    // We use -[NSWorkspace type:conformsToType:], which is nearly always the correct thing to do with UTIs, but the arguments are reversed compared to what's typical. Think about it: this method doesn't know how to write any particular subtype of the supported types, so it should assert if it's asked to. It does however, effectively know how to write all of the subtypes of the supported types (like public.data), and there's no reason for it to refuse to do so. Not particularly useful in a method that takes an error: parameter and outError!=NULL you must set *outError to something decent.
    NSData *data;
    NSArray *trialData = [self trialData];
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    BOOL useTypeConformance = [workspace respondsToSelector:@selector(type:conformsToType:)];
    if ((useTypeConformance && [workspace type:PSYDocumentTypeName conformsToType:typeName])) {
        
        //convert the contents of the document to a property list and then flatten the property list.
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        [properties setObject:[NSNumber numberWithInteger:PSYDocumentCurrentVersion] forKey:PSYDocumentVersionKey];
        [properties setObject:trialData forKey:PSYDocumentTrialDataKey];
        data = [NSPropertyListSerialization dataFromPropertyList:properties format:NSPropertyListXMLFormat_v1_0
                                                errorDescription:NULL];
        
    } else if ([typeName isEqualToString:@"public.comma-separated-values-text"]) {
        
        //Unfortunately there is no UTI for csv files, so we will just check if the correct type name was passed in. Not great programming practice, but shouldn't see any problems here.
        NSString *csvString = [self makeCSVStringFromArrayOfPropertyLists:trialData];
        data = [csvString dataUsingEncoding:NSUTF8StringEncoding];
    }
    else {
        
        //Hopefully we won't get any errors.
        NSLog(@"Error in dataOfType:");
        *outError = PSYErrorWithCode(PSYUnknownFileReadError);
    }
    return data;
}

- (NSString *)makeCSVStringFromArrayOfPropertyLists:(NSArray *)array {
    
    //So a CSV file basically just defines a table by separating the values that should be in each cell by a comma, and signals the beginning of a new row by a newline ('\n') character. Take all of the values we have in our data and set up a big long string in CSV format.
    
    NSMutableString *csvString = [NSMutableString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n", PSYDocumentTrialDataParticipantKey,
                                  PSYDocumentTrialDataReactionTimeKey, PSYDocumentTrialDataTrialNumberKey, PSYDocumentTrialDataConditionKey, PSYDocumentTrialDataDateRunKey, PSYDocumentTrialDataCorrectKey, PSYDocumentTrialDataSetSizeKey, PSYDocumentTrialDataDisplayIDKey, PSYDocumentTrialDataEpochKey, PSYDocumentTrialDataRotationKey];
    
    for (NSDictionary *plist in array) {
        NSString *stringToAppend = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                                    [plist valueForKey:PSYDocumentTrialDataParticipantKey],
                                    [plist valueForKey:PSYDocumentTrialDataReactionTimeKey],
                                    [plist valueForKey:PSYDocumentTrialDataTrialNumberKey],
                                    [plist valueForKey:PSYDocumentTrialDataConditionKey],
                                    [plist valueForKey:PSYDocumentTrialDataDateRunKey],
                                    [plist valueForKey:PSYDocumentTrialDataCorrectKey],
                                    [plist valueForKey:PSYDocumentTrialDataSetSizeKey],
                                    [plist valueForKey:PSYDocumentTrialDataDisplayIDKey],
                                    [plist valueForKey:PSYDocumentTrialDataEpochKey],
                                    [plist valueForKey:PSYDocumentTrialDataRotationKey]];
        [csvString appendString:stringToAppend];
    }
    return csvString;
}

- (void)makeWindowControllers {
    //create the experiment window
    PSYWindowController *windowController = [[PSYWindowController alloc] init];
    [self addWindowController:windowController];
    
}

- (void)showDataWindow:(id)sender {
    //Load that shit.
    PSYDataWindowController *windowController = [[PSYDataWindowController alloc] init];
    [self addWindowController:windowController];
    [windowController showWindow:sender];
    
}

#pragma mark *** NSMutableArray creating methods ***

//These methods are all down here to keep the new and old display creating methods clean. I could have done them in a category of NSMutableArray, but I arbitrarily chose to do them this way. This shouldn't really create any problems.

- (NSMutableArray *)UniqueRandIntArrayWithNumItems:(NSInteger)items inRange:(NSInteger)range {
    
    //given a range and a desired number of items, returns an NSMutableArray of unique random integers between 0 and the given range
    NSMutableArray *array = [[NSMutableArray alloc ]initWithCapacity:items];
    if (array) {
        while ([array count] < items) {
            NSUInteger rand = arc4random_uniform((int)range);
            NSNumber *randNumber = [NSNumber numberWithInteger:rand];
            NSInteger i = 0;
            for (NSNumber *number in array){
                if ([randNumber isEqualToNumber:number]) {
                    i = 1;
                }
            }
            if (i == 0) {
                [array addObject:randNumber];
            }
        }
    }
    return array;
}

- (NSMutableArray *)UniqueRandIntArrayWithNumItems:(NSInteger)items inRange:(NSInteger)range withLead:(NSNumber *)lead {
    
    //given a range and a desired number of items, returns an NSMutableArray of unique random integers between 0 and the given range. The array will have the passed in 'lead' value at the head of it.
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:items];
    if (array) {
        [array addObject:lead];
        while ([array count] < items) {
            NSUInteger rand = arc4random_uniform((int)range);
            NSNumber *randNumber = [NSNumber numberWithInteger:rand];
            NSInteger i = 0;
            for (NSNumber *number in array){
                if ([randNumber isEqualToNumber:number]) {
                    i = 1;
                }
            }
            if (i == 0) {
                [array addObject:randNumber];
            }
        }
    }
    return array;
}



- (NSMutableArray *)RandIntArrayWithNumItems:(NSInteger)items inRange:(NSInteger)range {
    
    //Returns an array of random integers in the specified range.
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:items];
    if (array) {
        for (NSInteger index=0; index<items; index++) {
            NSUInteger rand = arc4random_uniform((int)range);
            NSNumber *randNumber = [NSNumber numberWithInteger:rand];
            [array addObject:randNumber];
        }
    }
    return array;
}

@end

@implementation NSMutableArray (Shuffling)

- (void)shuffle
{
    NSUInteger count = [self count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSInteger nElements = count - i;
        NSInteger n = (arc4random() % nElements) + i;
        [self exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}
@end
