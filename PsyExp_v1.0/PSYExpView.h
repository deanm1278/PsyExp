//
//  PSYExpView.h
//  Abstract: an OpenGL view to display the experiment
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/3/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *PSYExpViewDisplaysBindingName;
extern NSString *PSYExpViewStartOfTrialBindingName;

@interface PSYExpView : NSOpenGLView {
    @private
    NSRect m_rectView;
    NSObject *_displaysContainer;
    NSString *_displaysKeyPath;
    NSUInteger _targetColor;
    NSUInteger _currentDisplayNumber;
    NSUInteger _rotation;
    NSTimer *_timer;
    NSInteger expState;
    NSInteger _stateToPassFromSheet;
    NSDate *_startTime;
    
    //GL Textures used in the experiment. If we want to add support for user uploaded images rather than what's already contained in the application bundle, these arrays will need to be defined dynamically. We will cross that bridge if it ever becomes necessary to do so.
    GLenum texFormat[ 10 ];   // Format of texture (GL_RGB, GL_RGBA)
    NSSize texSize[ 10 ];     // Width and height
    char *texBytes[ 10 ];     // Texture data
    GLuint texture[ 2 ][ 5 ];     // Storage for textures
    BOOL texturesLoaded;
}

//This property will be observed by the document.
@property NSMutableDictionary *endOfTrialInfo;

@end
