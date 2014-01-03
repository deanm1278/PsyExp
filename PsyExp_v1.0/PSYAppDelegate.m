//
//  PSYAppDelegate.m
//  Abstract: manages display of data window, preferences window, and new participant window
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/3/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import "PSYAppDelegate.h"
#import "PSYConstants.h"

//Keys used in PSYExp's user defaults
static NSString *PSYAppAutosavesPreferencesKey = @"autosaves";
static NSString *PSYAppAutosavingDelayPreferencesKey = @"autosavingDelay";
static NSString *PSYAppXDivPreferencesKey = @"xDiv";
static NSString *PSYAppYDivPreferencesKey = @"yDiv";
static NSString *PSYAppNumItems1PreferencesKey = @"numItems1";
static NSString *PSYAppNumItems2PreferencesKey = @"numItems2";
static NSString *PSYAppNumRepeatedPreferencesKey = @"numRepeated";
static NSString *PSYAppNumRandomPreferencesKey = @"numRandom";
static NSString *PSYAppFixTimePreferencesKey = @"fixTime";
static NSString *PSYAppTrialsPerBlockPreferencesKey = @"trialsPerBlock";
static NSString *PSYAppBlocksPerEpochPreferencesKey = @"blocksPerEpoch";
static NSString *PSYAppEpochsPreferencesKey = @"epochs";
static NSString *PSYAppColor1KeyPreferencesKey= @"color1Key";
static NSString *PSYAppColor2KeyPreferencesKey = @"color2Key";
static NSString *PSYAppParticipantIDKey = @"participantID";
static NSString *PSYAppRotateAfterNumEpochsKey = @"rotateAfterNumEpochs";
static NSString *PSYAppNumPracticeTrialsKey = @"numPracticeTrials";
static NSString *PSYAppConditionKey = @"condition";
static NSString *PSYAppMulipleSetSizesKey = @"multipleSetSizes";
static NSString *PSYAppInstructionsImagePathKey = @"instructionsImagePath";

@interface NSWindowController(PSYConvenience)
-(BOOL)isWindowShown;
-(void)showOrHideWindow;
@end
@implementation NSWindowController(PSYConvenience)

//Simple convenience methods added to NSWindowController.
-(BOOL)isWindowShown {
    return [[self window] isVisible];
}

-(void)showOrHideWindow {
    NSWindow *window = [self window];
    if ([window isVisible]) {
        [window orderOut:self];
    }
    else {
        [self showWindow:self];
    }
}

@end

@implementation PSYAppDelegate

#pragma mark ***Launching***

//conformance to the NSObject(NSApplicationNotifications) information protocol.
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    //Close the application after the last window is closed
    return YES;
}

#pragma mark ***Preferences***

//conformance to the NSObject(NSApplicationNotifications) information protocol.
- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    //TODO: Autosaving Support has not yet been implemented. Set up the default values of our autosavinv preferences very early, before there's any chance of a binding using them. The default is for autosaving to be off, but 60 seconds if the user turns it on.
    
    NSURL* resourceURL = [[NSBundle mainBundle] URLForResource:@"instructions" withExtension:@".bmp"];
    NSString *URLPath = [resourceURL path];
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [userDefaultsController setInitialValues:[NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithBool:NO], PSYAppAutosavesPreferencesKey,
                                              [NSNumber numberWithDouble:60.0], PSYAppAutosavingDelayPreferencesKey,
                                              [NSNumber numberWithDouble:0.5], PSYAppFixTimePreferencesKey,
                                              [NSNumber numberWithInt:24], PSYAppTrialsPerBlockPreferencesKey,
                                              [NSNumber numberWithInt:4], PSYAppBlocksPerEpochPreferencesKey,
                                              [NSNumber numberWithInt:5], PSYAppEpochsPreferencesKey,
                                              [NSNumber numberWithInt:8], PSYAppNumItems1PreferencesKey,
                                              [NSNumber numberWithInt:10], PSYAppNumItems2PreferencesKey,
                                              [NSNumber numberWithInt:12], PSYAppNumRandomPreferencesKey,
                                              [NSNumber numberWithInt:12], PSYAppNumRepeatedPreferencesKey,
                                              [NSNumber numberWithInt:8], PSYAppXDivPreferencesKey,
                                              [NSNumber numberWithInt:8], PSYAppYDivPreferencesKey,
                                              [NSNumber numberWithInt:1], PSYAppParticipantIDKey,
                                              [NSNumber numberWithInt:5], PSYAppRotateAfterNumEpochsKey,
                                              [NSNumber numberWithInt:8], PSYAppNumPracticeTrialsKey,
                                              [NSNumber numberWithInt:PILOT], PSYAppConditionKey,
                                              [NSNumber numberWithBool:NO], PSYAppMulipleSetSizesKey,
                                              URLPath, PSYAppInstructionsImagePathKey,
                                              @"f", PSYAppColor1KeyPreferencesKey,
                                              @"j", PSYAppColor2KeyPreferencesKey, nil]];
    
    //Bind this object's preferences to the user defaults of the same name. don't bother with ivars for these values. quick way of invoking setter methods.
    [self bind:PSYAppAutosavesPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppAutosavesPreferencesKey] options:nil];
    [self bind:PSYAppAutosavingDelayPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppAutosavingDelayPreferencesKey] options:nil];
    [self bind:PSYAppFixTimePreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppFixTimePreferencesKey] options:nil];
    [self bind:PSYAppTrialsPerBlockPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppTrialsPerBlockPreferencesKey] options:nil];
    [self bind:PSYAppBlocksPerEpochPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppBlocksPerEpochPreferencesKey] options:nil];
    [self bind:PSYAppEpochsPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppEpochsPreferencesKey] options:nil];
    [self bind:PSYAppNumItems1PreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppNumItems1PreferencesKey] options:nil];
    [self bind:PSYAppNumItems2PreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppNumItems2PreferencesKey] options:nil];
    [self bind:PSYAppNumRandomPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppNumRandomPreferencesKey] options:nil];
    [self bind:PSYAppNumRepeatedPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppNumRepeatedPreferencesKey] options:nil];
    [self bind:PSYAppXDivPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppXDivPreferencesKey] options:nil];
    [self bind:PSYAppYDivPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppYDivPreferencesKey] options:nil];
    [self bind:PSYAppColor1KeyPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppColor1KeyPreferencesKey] options:nil];
    [self bind:PSYAppColor2KeyPreferencesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppColor2KeyPreferencesKey] options:nil];
    [self bind:PSYAppParticipantIDKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppParticipantIDKey] options:nil];
    [self bind:PSYAppRotateAfterNumEpochsKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppRotateAfterNumEpochsKey] options:nil];
    [self bind:PSYAppNumPracticeTrialsKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppNumPracticeTrialsKey] options:nil];
     [self bind:PSYAppConditionKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppConditionKey] options:nil];
    [self bind:PSYAppMulipleSetSizesKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppMulipleSetSizesKey] options:nil];
    [self bind: PSYAppInstructionsImagePathKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:PSYAppInstructionsImagePathKey] options:nil];
}

#pragma mark ***setters***

//TODO: may want to make method that calls all setters when 'apply' button is pushed

- (void)setAutosaves:(BOOL)autosaves {
    
    // The user has toggled the "autosave documents" checkbox in the preferences panel.
    if (autosaves) {
        
        // Get the autosaving delay and set it in the NSDocumentController.
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:_autosavingDelay];
        
    } else {
        
        // Set a zero autosaving delay in the NSDocumentController. This tells it to turn off autosaving.
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:0.0];
        
    }
    _autosaves = autosaves;
    
}


- (void)setAutosavingDelay:(NSTimeInterval)autosaveDelay {
    
    // Is autosaving even turned on right now?
    if (_autosaves) {
        
        // Set the new autosaving delay in the document controller, but only if autosaving is being done right now.
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:autosaveDelay];
        
    }
    _autosavingDelay = autosaveDelay;
    
}

- (void)setFixTime:(NSTimeInterval)fixTime {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Fixation time must be a positive number." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid fixation time."];
    
    if (fixTime < 0) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
    _fixTime = fixTime;
    }
}
- (void)setTrialsPerBlock:(int)trialsPerBlock {

    _trialsPerBlock = trialsPerBlock;
    
}
- (void)setBlocksPerEpoch:(int)blocksPerEpoch {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The number of blocks per epoch must be a positive integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number of blocks per epoch."];
    
    if (blocksPerEpoch < 1) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
    _blocksPerEpoch = blocksPerEpoch;
    }
}
- (void)setEpochs:(int)epochs {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The number of epochs must be a positive integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number of epochs."];
    
    if (epochs < 1) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
    _epochs = epochs;
    }
}
- (void)setNumItems1:(int)numItems1 {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The number of items in the display must be a positive integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number of items."];
    
    if (numItems1 < 1) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
        _numItems1 = numItems1;
    }
}
- (void)setNumItems2:(int)numItems2 {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The number of items in the display must be a positive integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number of items."];
    
    if (numItems2 < 1) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else if (!_multipleSetSizes) {
        _numItems2 = _numItems1;
    }
    else {
        _numItems2 = numItems2;
    }
}
- (void)setNumRandom:(int)numRandom {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The number of random displays must be a positive, even integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number of random displays."];
    
    if (numRandom < 1 || !(numRandom % 2 == 0)) {
        //display an error if the user tries to set an invalid participantID.
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
        _numRandom = numRandom;
        [self setTrialsPerBlock:_numRandom + _numRepeated];
    }
}
- (void)setNumRepeated:(int)numRepeated {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The number of repeated displays must be a positive, even integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number of repeated displays."];
    
    if (numRepeated < 1 || !(numRepeated % 2 == 0)) {
        //display an error if the user tries to set an invalid participantID.
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
        _numRepeated = numRepeated;
        [self setTrialsPerBlock:_numRandom + numRepeated];
    }
}
- (void)setXDiv:(int)xDiv {
    NSAlert *alert = [NSAlert alertWithMessageText:@"X Divisions must be a positive integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number of X divisions."];
    
    if (xDiv < 1) {
        //display an error if the user tries to set an invalid participantID.
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
        _xDiv = xDiv;
        [self setNumZones];
    }
}
- (void)setYDiv:(int)yDiv {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Y Divisions must be a positive integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number of Y Divisions."];
    
    if (yDiv < 1) {
        //display an error if the user tries to set an invalid participantID.
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
        _yDiv = yDiv;
        [self setNumZones];
    }
}
- (void)setNumZones {
    
    _numZones = _xDiv * _yDiv;
}

- (void)setParticipantID:(NSInteger)participantID {
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Participant number must be a positive integer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid participant number."];
    
    if (participantID < 1) {
        //display an error if the user tries to set an invalid participantID.
        [alert beginSheetModalForWindow:[_newParticipantWindowController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
        
        //Set the new participantID. When a new participant is specified, hide the new participant window.
        _participantID = participantID;
        if ([_newParticipantWindowController isWindowShown]) {
            [_newParticipantWindowController showOrHideWindow];
        }
    }
}

- (void)setColor1Key:(NSString *)color1Key {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The key must be a single character" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid key."];
    
    if ([color1Key length] != 1) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
    _color1Key = color1Key;
    }
}

- (void)setColor2Key:(NSString *)color2Key {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The key must be a single character" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid key."];
    
    if ([color2Key length] != 1) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
    } else {
        _color2Key = color2Key;
    }
}

- (void)setRotateAfterNumEpochs:(NSInteger)rotateAfterNumEpochs {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The number of epochs after which the layouts rotate must be a positive integer" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number."];
    
    if (rotateAfterNumEpochs < 1) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    } else {
        _rotateAfterNumEpochs = rotateAfterNumEpochs;
    }
    
}

- (void)setNumPracticeTrials:(NSInteger)numPracticeTrials {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The number of practice trials must be an even, positive integer" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid number."];
    
    if (numPracticeTrials < 0 || !(numPracticeTrials % 2 == 0)) {
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    } else {
        _numPracticeTrials = numPracticeTrials;
    }
}

- (void)setCondition:(NSInteger)condition {
    _condition = condition;
    
}

- (IBAction)setInstructionsFromInterface:(id)sender {
    
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Disable the selection of directories in the dialog.
    [openDlg setCanChooseDirectories:NO];
    
    //Enable only .bmp files for selection
    NSArray *filesArray = [NSArray arrayWithObject:@"bmp"];
    [openDlg setAllowedFileTypes:filesArray];
    [openDlg setAllowsOtherFileTypes:NO];
    
    // Display the dialog.  If the OK button was pressed,
    // process the files.
    if ([openDlg runModal] == NSOKButton) {
        
        NSString *newFilePath = [[openDlg URL] path];
        
        NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
        
        [userDefaultsController setValue:newFilePath forKeyPath:[@"values." stringByAppendingString:PSYAppInstructionsImagePathKey]];
        
        NSAlert *alert = [NSAlert alertWithMessageText:@"Image Selected" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The new image will appear once a new file is created, or the program is restarted."];
        
        [alert beginSheetModalForWindow:[_preferencesPanelController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        
    };
    
}

//TODO: fix so that when enabled it will set to value that's in the text field.
- (void)setMultipleSetSizes:(BOOL)multipleSetSizes {
    _multipleSetSizes = multipleSetSizes;
    if (!_multipleSetSizes) {
        [self setNumItems2:_numItems1];
    }
}

#pragma mark *** Invoked by menu items ***

- (IBAction)showPreferencesPanel:(id)sender {
    
    // We always show the same preferences panel. Its controller doesn't get deallocated when the user closes it.
    if (!_preferencesPanelController) {
        _preferencesPanelController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];
        
        // Make the panel appear in a good default location.
        [[_preferencesPanelController window] center];
        
    }
    [_preferencesPanelController showWindow:sender];
    
}

- (IBAction)showNewParticipantWindow:(id)sender {
    
    // We always show the same new participant window. Its controller doesn't get deallocated when the user closes it.
    if (!_newParticipantWindowController) {
        _newParticipantWindowController = [[NSWindowController alloc] initWithWindowNibName:@"NewParticipant"];
        
        // Make the panel appear in a good default location.
        [[_newParticipantWindowController window] center];
        
    }
    [_newParticipantWindowController showWindow:sender];
    
}

- (void)alertDidEnd:(NSAlert *)alert {
    //do nothing.
}
@end
