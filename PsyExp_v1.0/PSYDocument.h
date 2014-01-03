//
//  PSYDocument.h
//  Abstract: main document class
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/3/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *PSYDocumentTrialDataKey;
extern NSString *PSYDocumentTrialDataParticipantKey;
extern NSString *PSYDocumentTrialDataReactionTimeKey;
extern NSString *PSYDocumentTrialDataDateRunKey;
extern NSString *PSYDocumentTrialDataCorrectKey;
extern NSString *PSYDocumentTrialDataConditionKey;
extern NSString *PSYDocumentTrialDataTrialNumberKey;
extern NSString *PSYDocumentTrialDataDisplayIDKey;
extern NSString *PSYDocumentTrialDataSetSizeKey;
extern NSString *PSYDocumentTrialDataEpochKey;
extern NSString *PSYDocumentTrialDataRotationKey;

@interface PSYDocument : NSDocument {
    @private
    
    //other necessary variables
    NSArray *_newDisplayTargetZones;
    NSMutableArray *_oldDisplays;
    NSMutableArray *_newDisplays;
    NSInteger currentTrialNumber;
    BOOL _restPeriod;
    BOOL _practice;
}

//The value underlying the key-value coding (KVC) and observing (KVO) compliance described below.
@property NSMutableArray *displays;
@property NSMutableArray *trialData;
@property NSMutableDictionary *startOfTrialInfo;

- (void)beginNewTrial;

/* This class is KVC and KVO compliant for these keys:
 
 "currentDisplayNumber" (an int; read-write) - the index value of the display that the view should be showing.
 
 the trialData and displays properties are bound to the document in which they are opened.
 */

@end
