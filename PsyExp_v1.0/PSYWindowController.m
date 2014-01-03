//
//  PSYWindowController.m
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/3/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//
//
//  NOTE: we do not want this class, or the display class to know anything about the trial data, that is all handled by the PSYDocument class. This class only deals with displays.

#import "PSYWindowController.h"
#import "PSYExpView.h"
#import "PSYDocument.h"

NSString *PSYExpViewEndOfTrialInfoKey = @"endOfTrialInfo";
NSString *PSYDocumentStartOfTrialInfoKey = @"startOfTrialInfo";
NSString *PSYDocumentDisplaysKey = @"displays";


@implementation PSYWindowController


- (id)init 
{
    //do cocoa thing, specifying particular nib
    self = [super initWithWindowNibName:@"ExpWindow"];
    if (self) {
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Bind the exp view's displays to the document's displays. We do this instead of binding to the displays controller because NSArrayController is not KVC-compliant enough for "arrangedObjects" to work properly when the expView sends its bound-to object a -mutableArrayValueForKeyPath: message. The binding to self's "document.graphics" is 1) easy and 2) appropriate for a window controller that may someday be able to show one of several documents in its window. If we instead bound the graphic view to [self document] then we would have to redo the binding in -setDocument:.
    [_expView bind:PSYExpViewDisplaysBindingName toObject:self withKeyPath:[NSString stringWithFormat:@"%@.%@", @"document", PSYDocumentDisplaysKey] options:nil];
    
    //Have the exp view observe the dictictionary owned by the document so that it has all the information necessary to show the correct thing.
    [[self document] addObserver:_expView forKeyPath:PSYDocumentStartOfTrialInfoKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    
    //Have the document observe the information the exp view owns that it will need to record the trials and decide what to do next.
    [_expView addObserver:[self document] forKeyPath:PSYExpViewEndOfTrialInfoKey options:NSKeyValueObservingOptionNew context:NULL];
    
}

#pragma mark *** Overrides of NSWindowController Methods ***


//If we close this window without removing the observers from both the exp view and the document, observation info will be leaked and we don't want that. When the user clicks the close button, remove the observers.
- (void)windowWillClose:(NSNotification *)notification {
    [[self document] removeObserver:_expView forKeyPath:PSYDocumentStartOfTrialInfoKey];
    [_expView removeObserver:[self document] forKeyPath:PSYExpViewEndOfTrialInfoKey];

}

@end
