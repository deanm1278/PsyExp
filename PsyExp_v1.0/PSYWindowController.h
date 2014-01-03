//
//  PSYWindowController.h
//  Abstract: manages the display of the experiment window.
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/3/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PSYExpView;

@interface PSYWindowController : NSWindowController <NSWindowDelegate>{
    @private
    
    //objects in the nib:
    IBOutlet PSYExpView *_expView;
    
    //The values underlying the key-value coding (KVC) and observing (KVO) compliance described below.
    IBOutlet NSArrayController *_displaysController;
}

/* This class is KVC and KVO compliant for this key:
 
 "displaysController" (an NSArrayController; read-only) - The controller that manages the displays for the exp view in the controlled window.
 
 In PSYExp:
 
 Each PSYExpView's displays are bound to the arranged objects of the containing PSYWindowController's displaysController.
 */

@end
