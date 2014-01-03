//
//  PSYDataWindowController.m
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/11/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import "PSYDataWindowController.h"
#import "PSYDocument.h"

NSString *PSYDataWindowControllerTrialDataBindingName = @"trialData";

@interface PSYDataWindowController ()

@end

@implementation PSYDataWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"dataWindow"];
    if (self) {
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Bind the exp view's displays to the document's displays. We do this instead of binding to the displays controller because NSArrayController is not KVC-compliant enough for "arrangedObjects" to work properly when the expView sends its bound-to object a -mutableArrayValueForKeyPath: message. The binding to self's "document.graphics" is 1) easy and 2) appropriate for a window controller that may someday be able to show one of several documents in its window. If we instead bound the graphic view to [self document] then we would have to redo the binding in -setDocument:.
    [self bind:PSYDocumentTrialDataKey toObject:self withKeyPath:[NSString stringWithFormat:@"%@.%@", @"document", PSYDocumentTrialDataKey] options:nil];
    
}

#pragma mark *** Overrides of NSWindowController Methods ***

- (void)setDocument:(NSDocument *)document {
    // Cocoa Bindings makes many things easier. Unfortunately, one of the things it makes easier is creation of reference counting cycles. In Mac OS 10.4 and later NSWindowController has a feature that keeps bindings to File's Owner, when File's Owner is a window controller, from retaining the window controller in a way that would prevent its deallocation. We're setting up bindings programmatically in -windowDidLoad though, so that feature doesn't kick in, and we have to explicitly unbind to make sure this window controller and everything in the nib it owns get deallocated. We do this here instead of in an override of -[NSWindowController close] because window controllers aren't sent -close messages for every kind of window closing. Fortunately, window controllers are sent -setDocument:nil messages during window closing.
    if (!document) {
        [self unbind:PSYDocumentTrialDataKey];
    }
    
    // Redo the observing of the document's rotation when the document changes.
    [super setDocument:document];
    
}

#pragma mark *** TableView Methods ***

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_tableContents count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *trial = [_tableContents objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    
    //Set each cell in each column for the right key.
    if ([identifier isEqualToString:PSYDocumentTrialDataTrialNumberKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataTrialNumberKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataTrialNumberKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataReactionTimeKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataReactionTimeKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataReactionTimeKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataParticipantKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataParticipantKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataParticipantKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataConditionKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataConditionKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataConditionKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataCorrectKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataCorrectKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataCorrectKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataDateRunKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataDateRunKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataDateRunKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataDisplayIDKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataDisplayIDKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataDisplayIDKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataSetSizeKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataSetSizeKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataSetSizeKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataEpochKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataEpochKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataEpochKey]];
        return cellView;
    } else if ([identifier isEqualToString:PSYDocumentTrialDataRotationKey]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:PSYDocumentTrialDataRotationKey owner:self];
        [cellView.textField setStringValue:[trial valueForKey:PSYDocumentTrialDataRotationKey]];
        return cellView;
    } else {
        return nil;
    }
}

#pragma mark *** bindings ***

//An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {
    //PSYExpView supports several different bindings.
    if ([binding isEqualToString:PSYDataWindowControllerTrialDataBindingName]) {
        
        //We don't have any options to support for our custom trialData binding.
        NSAssert(([options count]==0), @"PSYDataWindowController doesn't support any options for the trialData binding.");
        
        //Rebinding is just as valid as resetting.
        if (_trialDataContainer || _trialDataKeyPath) {
            [self unbind:PSYDataWindowControllerTrialDataBindingName];
        }
        
        //Record the invormation about the binding.
        _trialDataContainer = observable;
        _trialDataKeyPath = [keyPath copy];
        
        NSArray *trials = [_trialDataContainer valueForKeyPath:_trialDataKeyPath];
        if ([trials isKindOfClass:[NSArray class]]) {
            
            //fill the table contents array with the trials.
            _tableContents = [NSMutableArray arrayWithArray:trials];
        }
        
        //reload all the data in our table view after the binding has been set.
        [_tableView reloadData];
                
    }else {
        
        //For every binding except "trialData" just use NSObject's default implementation. It will start observing the bound-to property. when a KVO notification is sent for the bound-to property, this object will be sent a [self setValue:theNewValue forKey:theBindingName] message, so this class just has to be KVC-compliant for a key that is the same as the binding name.
        [super bind:binding toObject:observable withKeyPath:keyPath options:options];
    }
}

@end
