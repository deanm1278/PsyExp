//
//  PSYAppDelegate.h
//  Abstract: manages display of data window, preferences window, and new participant window
//
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/3/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//
/*
 So essentially this application is designed like this:
 The PSYAppDelegate class manages the data window, the preferences window, and the new participant window. It also deals with setting and binding the user defaults to the shared defaults controller. The PSYDocument class is the document, and deals with all the normal things an NSDocument class normally deals with. It also deals with creating a property lists that describe the displays to be shown to the participant. It will create a bunch of these property lists, and send them over to the PSYDisplay class, which creates the requested displays and returns them to the PSYDocument as PSYDisplay objects. The document will shuffle up all the displays and place them in an array. Each PSYDocument owns a PSYWindowController object, and the PSYWindowController object is in charge of binding the documents array of displays to an array controller that will be observed by the view. The PSYExpView class is the main view class of the application. This observes an array of PSYDisplay objects as well as a dictionary owned by the PSYDocument object (which indirectly owns the PSYExpView object) that contains information on which display in the array it should be showing, how the target should be colored and rotated, etc. The PSYExpView contains all the openGL code needed to decode and draw the PSYDisplay object. The PSYExpView class also deals with monitoring user input and placing necessary information into a dictionary that is observed by the document at the end of each trial. Once the document is notified that the PSYExpView's dictionary has changed, it knows that the trial has ended, and records the information about the trial.
 
 */

#import <Cocoa/Cocoa.h>

@interface PSYAppDelegate : NSObject <NSApplicationDelegate> {
    @private
    NSWindowController *_dataWindowController;
    NSWindowController *_preferencesPanelController;
    NSWindowController *_newParticipantWindowController;
    
    //Values that come from user defaults
    BOOL _autosaves;
    NSTimeInterval _autosavingDelay;
    NSTimeInterval _fixTime;
    NSInteger _trialsPerBlock;
    NSInteger _blocksPerEpoch;
    NSInteger _epochs;
    NSInteger _numItems1;
    NSInteger _numItems2;
    BOOL _multipleSetSizes;
    NSInteger _numRandom;
    NSInteger _numRepeated;
    NSInteger _xDiv;
    NSInteger _yDiv;
    NSInteger _numZones;
    NSInteger _participantID;
    NSString *_color1Key;
    NSString *_color2Key;
    NSInteger _rotateAfterNumEpochs;
    NSInteger _numPracticeTrials;
    NSInteger _condition;
    
    NSURL *_instructionsImagePath;
}

-(IBAction)showPreferencesPanel:(id)sender;
-(IBAction)showNewParticipantWindow:(id)sender;

@end
