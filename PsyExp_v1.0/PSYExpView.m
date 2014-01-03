//
//  PSYExpView.m
//  PsyExp_v1.0
//
//  Created by Dean Miller on 9/3/13.
//  Copyright (c) 2013 Dean Miller. All rights reserved.
//

#import "PSYExpView.h"
#import "PSYDisplay.h"
#import <OpenGL/OpenGL.h>
#import "PSYConstants.h"

#define TEX_ROWS 5
#define TEX_COLS 2

//Names of the bindings supported by this class, in addition to the ones whose support is inherited from NSView.
NSString *PSYExpViewDisplaysBindingName = @"displays";
NSString *PSYExpStartOfTrialInfoBindingName = @"startOfTrialInfo";

//Keys used in PSYExp's user defaults
static NSString *PSYAppXDivPreferencesKey = @"xDiv";
static NSString *PSYAppYDivPreferencesKey = @"yDiv";
static NSString *PSYAppFixTimePreferencesKey = @"fixTime";
static NSString *PSYAppColor1KeyPreferencesKey= @"color1Key";
static NSString *PSYAppColor2KeyPreferencesKey = @"color2Key";
static NSString *PSYAppConditionKey = @"condition";
static NSString *PSYAppInstructionsImagePathKey = @"instructionsImagePath";

//some methods that are invoked by methods above them.
@interface PSYExpView(PSYForwardDeclarations)
- (NSArray *)displays;
//- (void)stopObservingDisplays;
@end

@implementation PSYExpView

@synthesize endOfTrialInfo = _endOfTrialInfo;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //when the view is loaded, the experiment will not have begun yet.
        expState = NOT_RUNNING;
    }
    
    
    return self;
}

- (void)dealloc {
    [self unbind:PSYExpViewDisplaysBindingName];
}

#pragma mark *** bindings ***

- (NSArray *)displays {
    //an exp view doesn't hold onto an array of the displays it's presenting. that would be a cache that hasn't been justified by performance measurement. Get the array of displays from the bound-to object (an array controller, in PSYExp's case) It's poor practice for a method that returns a collection to return nil, so never return nil.
    NSArray *displays = [_displaysContainer valueForKeyPath:_displaysKeyPath];
    if (!displays) {
        displays = [NSArray array];
    }
    return displays;
}

//An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {
    
    //PSYExpView supports several different bindings.
    if ([binding isEqualToString:PSYExpViewDisplaysBindingName]) {
        
        //We don't have any options to support for our custom "graphics" binding.
        NSAssert(([options count]==0), @"PSYExpView doesn't support any options for the 'displays binding.");
                 
        //Rebinding is just as valid as resetting.
        if (_displaysContainer || _displaysKeyPath) {
            [self unbind:PSYExpViewDisplaysBindingName];
        }
        
        //Record the invormation about the binding.
        _displaysContainer = observable;
        _displaysKeyPath = [keyPath copy];
        
        /* As of now we don't really need to be observing changes to the displays container, we just need to be bound to it. Ill leave the code here though in case we want to add support for something else later.
        
        //Start observing changes to the array of displays to which we're bound
        [_displaysContainer addObserver:self forKeyPath:_displaysKeyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:&PSYExpViewDisplaysObservationContext];
         */
        
        
    }else {
        
        //For every binding except "displays" just use NSObject's default implementation. It will start observing the bound-to property. when a KVO notification is sent for the bound-to property, this object will be sent a [self setValue:theNewValue forKey:theBindingName] message, so this class just has to be KVC-compliant for a key that is the same as the binding name. Also, NSView supports a few simple bindings of its own, and there's no reason to get in the way of those.
        [super bind:binding toObject:observable withKeyPath:keyPath options:options];
    }
}

// An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)unbind:(NSString *)bindingName {
    
    //The removeObserver:forKeyPath: method is left in the comments in case we ever want to add support for observing changes to the displays array for any reason.
    if ([bindingName isEqualToString:PSYExpViewDisplaysBindingName]) {
        //[_displaysContainer removeObserver:self forKeyPath:_displaysKeyPath];
        _displaysContainer = nil;
    } else {
        
        //For every binding except "displays" just use NSObject's default implementation.
        [super unbind:bindingName];
    }
}

// An override of the NSObject(NSKeyValueObserving) method.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:PSYExpStartOfTrialInfoBindingName]){
        NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
        
        //We have received the info for the start of a new trial. Interpret it and send the signal to begin a trial.
        NSDictionary *newInfo = [NSDictionary dictionaryWithDictionary:[change objectForKey:NSKeyValueChangeNewKey]];
        _currentDisplayNumber = [[newInfo valueForKey:@"currentDisplayNumber"] integerValue];
        
        NSInteger oldRotation = _rotation;
        _rotation = [[newInfo valueForKey:@"rotation"] integerValue];
        _targetColor = [[newInfo valueForKey:@"targetColor"] integerValue];
        NSInteger state = [[newInfo valueForKey:@"state"] integerValue];
        
        if (_rotation == ROTATED && oldRotation == NOT_ROTATED &&
            [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppConditionKey]]integerValue] != BOTH) {
            _stateToPassFromSheet = state;
            NSAlert *alert = [NSAlert alertWithMessageText:@"Please lay down on your right side." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please confirm with your experimenter that you are in the right position before continuing."];
            [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:) contextInfo:nil];
        } else {
            
            [self beginDrawing:state];
        }
        
    }
    /* I'll leave this here in case we want to add support for observing changes to the displays array.
    else if ([keyPath isEqualToString:[@"document." stringByAppendingString:PSYExpViewDisplaysBindingName]]) {

    }
     */
    else {
        // In overrides of -observeValueForKeyPath:ofObject:change:context: always invoke super when the observer notification isn't recognized. Code in the superclass is apparently doing observation of it's own. NSObject's implementation of this method throws an excpetion. Such an exception would be indicating a programming error that should be fixed.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)alertDidEnd:(NSAlert *)alert {
    [self beginDrawing:_stateToPassFromSheet];
}

#pragma mark *** Loading Images ***

- (BOOL)loadGLTextures
{
    //This method will load the textures to be used by the OpenGl engine. If we ever want to add support for user defined images in the experiment, this method will need to be changed.
    
    BOOL status = FALSE;
    
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    
    //load all the images needed into the texture array. There is a green and red texture for both target and noise

    NSString* targetR = [[NSBundle mainBundle] pathForResource:@"targetR" ofType:@"bmp"];
    NSString* targetG = [[NSBundle mainBundle] pathForResource:@"targetG" ofType:@"bmp"];
    NSString* noiseR = [[NSBundle mainBundle] pathForResource:@"noiseR" ofType:@"bmp"];
    NSString* noiseG = [[NSBundle mainBundle] pathForResource:@"noiseG" ofType:@"bmp"];
    NSString* fixationCross = [[NSBundle mainBundle] pathForResource:@"fixationCross" ofType:@"bmp"];
    NSString* end = [[NSBundle mainBundle] pathForResource:@"end" ofType:@".bmp"];
    NSString* restPeriod = [[NSBundle mainBundle] pathForResource:@"restPeriod" ofType:@".bmp"];
    //NSString* instructions = [[NSBundle mainBundle] pathForResource:@"instructions" ofType:@".bmp"];
    NSString* instructions = [userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppInstructionsImagePathKey]];
    NSString* afterPracticeInstructions = [[NSBundle mainBundle] pathForResource:@"after_practice_instructions" ofType:@".bmp"];
    NSString* continueImage = [[NSBundle mainBundle] pathForResource:@"continue" ofType:@".bmp"];
    
    NSArray *texArray = [NSArray arrayWithObjects:targetR, targetG, noiseR, noiseG, fixationCross, end, restPeriod, instructions, afterPracticeInstructions, continueImage,nil];
    
    for (int i = 0; i < [texArray count]; i++) {
        
        if( [ self loadBitmap:[texArray objectAtIndex:i] intoIndex:i ] )
            
        {
            status = TRUE;
            
            int row = floorf((float)i/(float)TEX_COLS);
            int col = i % TEX_COLS;
            
            glGenTextures( 1, &texture[ col ][ row ] );   // Create the texture
            
            // Typical texture generation using data from the bitmap. The multidimensional array thing will probably be a bit of a pain, but it will make it easier to add user defined images later if need be.
            glBindTexture( GL_TEXTURE_2D, texture[ col ][ row ] );
            
            glTexImage2D( GL_TEXTURE_2D, 0, 3, texSize[ i ].width,
                         texSize[ i ].height, 0, texFormat[ i ],
                         GL_UNSIGNED_BYTE, texBytes[ i ] );
            // Linear filtering
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
            
            free( texBytes[ i ] );
        }
    }
    return status;
}

/*
 * The NSBitmapImageRep is going to load the bitmap, but it will be
 * setup for the opposite coordinate system than what OpenGL uses, so
 * we copy things around.
 */
- (BOOL)loadBitmap:(NSString *)filename intoIndex:(int)texIndex
{
    BOOL success = FALSE;
    NSBitmapImageRep *theImage;
    size_t bitsPPixel, bytesPRow;
    unsigned char *theImageData;
    int rowNum, destRowNum;
    
    theImage = [ NSBitmapImageRep imageRepWithContentsOfFile:filename ];
    if( theImage != nil )
    {
        bitsPPixel = [ theImage bitsPerPixel ];
        bytesPRow = [ theImage bytesPerRow ];
        if( bitsPPixel == 24 )        // No alpha channel
            texFormat[ texIndex ] = GL_RGB;
        else if( bitsPPixel == 32 )   // There is an alpha channel
            texFormat[ texIndex ] = GL_RGBA;
        texSize[ texIndex ].width = [ theImage pixelsWide ];
        texSize[ texIndex ].height = [ theImage pixelsHigh ];
        texBytes[ texIndex ] = calloc( bytesPRow * texSize[ texIndex ].height,
                                      1 );
        if( texBytes[ texIndex ] != NULL )
        {
            success = TRUE;
            theImageData = [ theImage bitmapData ];
            destRowNum = 0;
            for( rowNum = texSize[ texIndex ].height - 1; rowNum >= 0;
                rowNum--, destRowNum++ )
            {
                // Copy the entire row in one shot
                memcpy( texBytes[ texIndex ] + ( destRowNum * bytesPRow ),
                       theImageData + ( rowNum * bytesPRow ),
                       bytesPRow );
            }
        }
    }
    
    return success;
}

#pragma mark *** drawing ***


- (void)drawRect:(NSRect)dirtyRect
{
    //Lazily load the textures. We don't want to load them more than once.
    if (!texturesLoaded) {
        if ([self loadGLTextures]) {
            texturesLoaded = TRUE;
        }
    }
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    
    //If the window has been resized, things will get all silly. To prevent this, invoke the resize method defined further down at the beginning of the drawRect: method.
    [self resizeGL];
    glClear(GL_COLOR_BUFFER_BIT);
    
    //Determine what state the experiment is in and do the appropriate thing.
    switch (expState) {
        case FIXATION:
            [self drawFixationCross];
            break;
            
        case DISPLAY:
            //Rotate the screen if we are in the specified condition
            if (_rotation == ROTATED && [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppConditionKey]]integerValue] != EGO) {
                glTranslatef(m_rectView.size.width/2, m_rectView.size.height/2, 0); //translate coordinate system to middle of screen
                glRotated(-90, 0, 0, 1); //Rotate screen
                glTranslatef(-(m_rectView.size.width/2), -(m_rectView.size.height/2), 0); //translate back.
            }
            [self drawDisplay];
            break;
            
        default:
            [self drawText:expState];
            break;
    }
    //Flush the buffer and draw to the screen.
    glFlush();
}

- (void)beginDrawing:(NSInteger)state {
    
    switch (state) {
        {case DISPLAY:
            expState = FIXATION;
            NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
            NSNumber *fixTime = [userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppFixTimePreferencesKey]];
            
            //The experiment is currently running. Have it draw the fixation cross for the amount of time specified in the user defaults, and then once that amount of time is up, invoke the setDrawDisplay method.
            _timer = [NSTimer scheduledTimerWithTimeInterval:[fixTime floatValue] target:self selector:@selector(setDrawDisplay) userInfo:nil repeats:NO];
            break;
        }
        
        case END_OF_BLOCK:
            expState = END_OF_BLOCK;
            
            //This timer will make it so a 10 second rest period is required before the participant is allowed to go on to the next block.
            _timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(setExpReady) userInfo:nil repeats:NO];
            break;
        
        default:
            expState = state;
            break;
    }
    
    [self setNeedsDisplay:YES];
}

- (void)setDrawDisplay {
    
    //Start the reaction time timer and tell the system that we should draw the display.
    expState = DISPLAY;
    [self setNeedsDisplay:YES];
    
    _startTime = [NSDate date];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1/RESOLUTION
                                             target:self
                                           selector:@selector(tick)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)tick {
    //do nothing. This method is only here because the timer needs something to call.
}

- (void)setExpReady {
    
    //READY is set after the alloted rest period is up. The user is free to continue when they so choose.
    expState = READY;
    [self setNeedsDisplay:YES];
}

- (void)drawText:(NSInteger)text {
    
    //Draw either the end of block or end of session texture as specified by the method.
    if (text == END_OF_BLOCK) {
        glBindTexture(GL_TEXTURE_2D, texture[ 0 ][ 3 ]);
    } else if (text == END_OF_SESSION) {
        glBindTexture(GL_TEXTURE_2D, texture[ 1 ][ 2 ]);
    } else if (text == NOT_RUNNING) {
        glBindTexture(GL_TEXTURE_2D, texture[ 1 ][ 3 ]);
    } else if (text == END_OF_PRACTICE) {
        glBindTexture(GL_TEXTURE_2D, texture[ 0 ][ 4 ]);
    } else if (text == READY) {
        glBindTexture(GL_TEXTURE_2D, texture[ 1 ][ 4 ]);
    }
    
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSRect rectView = [self bounds];
    
    //find out the size of each cell in the grid.
    float width = rectView.size.width;
    float height = rectView.size.height;
    NSUInteger xDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppXDivPreferencesKey]] integerValue];
    NSUInteger yDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppYDivPreferencesKey]] integerValue];
    NSNumber *zoneHeight = [NSNumber numberWithFloat:height/(float)yDiv];
    NSNumber *zoneWidth = [NSNumber numberWithFloat:width/(float)xDiv];
    
    glPushMatrix();
    glTranslatef(m_rectView.size.width/2, m_rectView.size.height/2, 0); //translate coordinate system to middle of screen
    
    glBegin( GL_QUADS );
    
    if (text == NOT_RUNNING || text == END_OF_PRACTICE) {
        //Draw the instructions on the screen. This requires a larger rectangle for the texture.
        glTexCoord2f( 0, 0 );
        glVertex2f( -4 * [zoneWidth floatValue], -4 * [zoneHeight floatValue]);   // Bottom left
        
        glTexCoord2f( 1, 0 );
        glVertex2f(  4 * [zoneWidth floatValue], -4 * [zoneHeight floatValue]);   // Bottom right
        
        glTexCoord2f( 1, 1 );
        glVertex2f(  4 * [zoneWidth floatValue],  4 * [zoneHeight floatValue]);   // Top right
        
        glTexCoord2f( 0, 1 );
        glVertex2f( -4 * [zoneWidth floatValue],  4 * [zoneHeight floatValue]);   // Top left
        
    } else {
    
        glTexCoord2f( 0, 0 );
        glVertex2f( -2.5 * [zoneWidth floatValue], -.5 * [zoneHeight floatValue]);   // Bottom left
    
        glTexCoord2f( 1, 0 );
        glVertex2f(  2.5 * [zoneWidth floatValue], -.5 * [zoneHeight floatValue]);   // Bottom right
    
        glTexCoord2f( 1, 1 );
        glVertex2f(  2.5 * [zoneWidth floatValue],  .5 * [zoneHeight floatValue]);   // Top right
    
        glTexCoord2f( 0, 1 );
        glVertex2f( -2.5 * [zoneWidth floatValue],  .5 * [zoneHeight floatValue]);   // Top left
    }
    
    glPopMatrix();
    glEnd();
    
}

- (void)drawFixationCross {
    
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSRect rectView = [self bounds];
    
    //find out the size of each cell in the grid.
    float width = rectView.size.width;
    float height = rectView.size.height;
    NSUInteger xDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppXDivPreferencesKey]] integerValue];
    NSUInteger yDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppYDivPreferencesKey]] integerValue];
    NSNumber *zoneHeight = [NSNumber numberWithFloat:height/(float)yDiv];
    NSNumber *zoneWidth = [NSNumber numberWithFloat:width/(float)xDiv];
    
    glBindTexture( GL_TEXTURE_2D, texture[ 0 ][ 2 ] );// Select our texture
    glPushMatrix();
    
    glTranslatef(m_rectView.size.width/2, m_rectView.size.height/2, 0); //translate coordinate system to middle of screen
    
    glBegin( GL_QUADS );
    
    glTexCoord2f( 0, 0 );
    glVertex2f( -.5 * [zoneWidth floatValue], -.5 * [zoneHeight floatValue]);   // Bottom left
    
    glTexCoord2f( 1, 0 );
    glVertex2f(  .5 * [zoneWidth floatValue], -.5 * [zoneHeight floatValue]);   // Bottom right
    
    glTexCoord2f( 1, 1 );
    glVertex2f(  .5 * [zoneWidth floatValue],  .5 * [zoneHeight floatValue]);   // Top right
    
    glTexCoord2f( 0, 1 );
    glVertex2f( -.5 * [zoneWidth floatValue],  .5 * [zoneHeight floatValue]);   // Top left
    
    glPopMatrix();
    glEnd();
}

- (void)drawDisplay {
    
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    NSRect rectView = [self bounds];
    
    //find out the size of each cell in the grid.
    float width = rectView.size.width;
    float height = rectView.size.height;
    NSUInteger xDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppXDivPreferencesKey]] integerValue];
    NSUInteger yDiv = [[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppYDivPreferencesKey]] integerValue];
    
    NSNumber *zoneWidth;
    NSNumber *zoneHeight;
    
    zoneHeight = [NSNumber numberWithFloat:height/(float)yDiv];
    zoneWidth = [NSNumber numberWithFloat:width/(float)xDiv];
    
    //Get the displays array.
    NSMutableArray *displays = [_displaysContainer valueForKeyPath:_displaysKeyPath];
    
    //Make sure we are observing an item of the correct class.
    if ([displays isKindOfClass:[NSMutableArray class]]) {
        
        //select the display the startOfTrialInfo owned by the document says we should be drawing.
        PSYDisplay *display = [displays objectAtIndex:_currentDisplayNumber];
        for (NSUInteger i = 0; i<[display.itemZones count]; i++) {
            
            //Loop through all the items in the selected display's itemZones array. Determine where on the screen they should be drawn based on the size of each zone in the grid.
            NSUInteger Z = [[display.itemZones objectAtIndex:i] integerValue];
            double pos = (float)Z/(float)xDiv;
            NSNumber *row = [NSNumber numberWithDouble:floor(pos)];
            NSNumber *col = [NSNumber numberWithDouble:Z % xDiv];
            float xPos = [col floatValue] * [zoneWidth floatValue];
            float yPos = [row floatValue] * [zoneHeight floatValue];
            float x1 = xPos + [zoneWidth floatValue];
            float y1 = yPos + [zoneHeight floatValue];
            
            //Get the rotation information from the properties arays contained in the display.
            GLuint rotation = [[display.itemRotations objectAtIndex:i] intValue];
            const GLfloat texCoords[4][2] = { {0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0}};
            
            //Draw the image in the desired rotation.
            //The items array in each display is created so that the target it always at index 0.
            if (i == 0) {
                //Item is a target, randomly generate and record it's color.
                glBindTexture( GL_TEXTURE_2D, texture[ _targetColor ][ 0 ] );
            } else {
                //Item is a distractor, get it's color from the display properties array.
                GLuint color = [[display.itemColors objectAtIndex:i] intValue];
                glBindTexture( GL_TEXTURE_2D, texture[ color ][ 1 ] );
            }
            
            glBegin(GL_QUADS);
            
            glTexCoord2f( texCoords[rotation%4][0],texCoords[rotation%4][1] );
            glVertex2f(xPos, yPos); //bottom left
            rotation++;
            
            glTexCoord2f( texCoords[rotation%4][0],texCoords[rotation%4][1] );
            glVertex2f(x1, yPos); //bottom right
            rotation++;
            
            glTexCoord2f( texCoords[rotation%4][0],texCoords[rotation%4][1] );
            glVertex2f(x1, y1); //top right
            rotation++;
            
            glTexCoord2f( texCoords[rotation%4][0],texCoords[rotation%4][1] );
            glVertex2f(xPos, y1); //top left
            rotation++;
            
            glEnd();
        }
    }
}

-(void)resizeGL {
    
    glClearColor(0, 0, 0, 0);
    
    //Disable unnecessary states.
    glDisable(GL_DITHER);
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_FOG);
    glDisable(GL_DEPTH_TEST);
    glPixelZoom(1.0,1.0);
    
    glEnable(GL_TEXTURE_2D);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    //Lock the frame size to be a perfect square
    NSRect window = [self.window frame];
    NSRect frame = [self frame];
    if(window.size.height != window.size.width){
        if (window.size.height < window.size.width) {
            frame.size.height = window.size.height - 50;
            frame.size.width = frame.size.height;
        } else if (window.size.width < window.size.height) {
            frame.size.width = window.size.width - 50;
            frame.size.height = frame.size.width;
        }
        NSSize size;
        size.height = frame.size.height;
        size.width = frame.size.width;
    
        [self setFrameSize:size];
        NSPoint origin;
        origin.x = (window.size.width - frame.size.width)/2;
        origin.y = self.frame.origin.y;
        [self setFrameOrigin:origin];
    }
    
    NSRect rectView = [self bounds];
	//if current size and width are different, make size and width current
	if(m_rectView.size.width != rectView.size.width || m_rectView.size.height != rectView.size.height) {
        
		glViewport(0, 0, rectView.size.width, rectView.size.height);
		m_rectView = rectView;
	}
    
    gluOrtho2D(NSMinX(m_rectView), NSMaxX(m_rectView), NSMinY(m_rectView),
               NSMaxY(m_rectView));
    
    //[self setNeedsDisplay:YES]; //using setNeedsDisplay:YES will cause crash when model is altered
}

#pragma mark *** event handling ***

//acceptsFirstResponder: needs to be set so that the view will get the keyDown: message when the user presses a key.
- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
    if (expState == DISPLAY) {
    
        NSInteger answer;
        NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
        
        //I messed up a little bit and made RED = 0, so if I say if(answer) the machine will not record the answer RED as an answer. Add 1 to all these things to fix this.
        if ([[theEvent characters] isEqualToString:[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppColor1KeyPreferencesKey]]]) {
            answer = RED + 1;
        
        } else if ([[theEvent characters] isEqualToString:[userDefaultsController valueForKeyPath:[@"values." stringByAppendingString:PSYAppColor2KeyPreferencesKey]]]) {
            answer = GREEN + 1;
        } else answer = NAN;
    
        //Check if the answer is correct and set trial end info to be observed by the document.
        if (answer) {
        
            if (_timer) {
                NSTimeInterval elapsedTime = -[_startTime timeIntervalSinceNow];
                [_timer invalidate];
        
                NSNumber *rt = [NSNumber numberWithFloat:elapsedTime];
                NSNumber *correct;
                if (answer == _targetColor + 1) {
                    correct = [NSNumber numberWithBool:YES];
                } else {
                    correct = [NSNumber numberWithBool:NO];
                }
                
                //Make the end of trial info dictionary and notify observers that it has changed
                [self willChangeValueForKey:@"endOfTrialInfo"];
                if (_endOfTrialInfo) {
                    [_endOfTrialInfo removeAllObjects];
                }
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:rt, @"reactionTime", correct, @"correct", nil];
                _endOfTrialInfo = [NSMutableDictionary dictionaryWithDictionary:info];
                [self didChangeValueForKey:@"endOfTrialInfo"];
            }
        }
    } else if (expState == READY || expState == END_OF_PRACTICE) {
        
        //If a rest period has just ended, set a signal in the dictionary to be observed by the document.
        [self willChangeValueForKey:@"endOfTrialInfo"];
        if (!_endOfTrialInfo) {
            _endOfTrialInfo = [[NSMutableDictionary alloc] init];
        }
        [_endOfTrialInfo removeAllObjects];
        [_endOfTrialInfo setObject:@"inputAfterRestPeriod" forKey:@"signal"];
        [self didChangeValueForKey:@"endOfTrialInfo"];
        
    } else if (expState == NOT_RUNNING) {
        //If a user has signaled to begin a session, set a signal in the dictionary to be observed by the document.
        [self willChangeValueForKey:@"endOfTrialInfo"];
        if (!_endOfTrialInfo) {
           _endOfTrialInfo = [[NSMutableDictionary alloc] init];
        }
        [_endOfTrialInfo setObject:@"inputBeforeSessionStart" forKey:@"signal"];
        [self didChangeValueForKey:@"endOfTrialInfo"];
    }
}

@end
