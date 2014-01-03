//
//  PSYDataWindowController.h
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/11/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSYDataWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
    @private
    NSMutableArray *_tableContents;
    NSObject *_trialDataContainer;
    NSString *_trialDataKeyPath;
    
    IBOutlet NSTableView *_tableView;
    
    IBOutlet NSArrayController *_trialDataController;
}

@end
