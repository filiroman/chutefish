//
//  CBMainGameLayer.mm
//  chute balls
//
//  Created by Roman Filippov on 14.02.14.
//  Copyright Roman Filippov 2014. All rights reserved.
//

// Import the interfaces
#import "CBMainGameLayer.h"

// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"
#import "B2BodyWrapper.h"
#import "CBAudioEngine.h"
#import "CBGameOverPopup.h"
#import "CBMainMenuLayer.h"
#import "CBSpriteLabel.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#include <unistd.h>

#import "CBPauseMenuPopup.h"
#import "CBMainMenuLayer.h"

// Ads
#import "GADBannerView.h"
#import "GADRequest.h"


#define BUCKET_HEIGHT 112

#define DRAW_THRESHOLD 25

#define USER_RECORDS_KEY @"bestScore"
#define USER_RECORDS_FILENAME @"user_data"
#define CB_LEADERBOARD_ID @"chutefishlb"

#define WALLS_DESTROY_TIME 4.0f

#define INITIAL_HEALTH 1

#define MAX_POINTS_COUNT 90

#define DELETED_BODY_TAG 999

#define ADMOB_TAG 888


// Choose fish tags
#define LEFT_FISH 11
#define RIGHT_FISH 12

typedef enum {
    bodyColor1 = 0,
    bodyColor2 = 1,
    bodyColor3 = 2,
    bodyColor4 = 3
} bodyColor;


enum {
	kTagParentNode = 1,
};


#pragma mark - CBMainGameLayer

@interface CBMainGameLayer()
{
    NSMutableArray *_points;
    NSUInteger _pointCount;
    NSUInteger _overallPointCount;
    NSMutableArray *_wallSprites;
    NSMutableArray *_bucketRects;
    NSMutableArray *_bodies;
    
    // for help
    NSMutableArray *_firstWall;
    
    int health;
    int score;
    BOOL newRecord;
    int64_t bestScore;
    
    CCTexture2D *newFishTexture_;
    CCTexture2D *oldFishTexture_;
    
    CCTexture2D *spriteTexture_;	// weak ref
    CCTexture2D *bucketsTexture;
	b2World* world;					// strong ref
    GADBannerView *bannerView_;
    BOOL isAdPositionAtTop_;
    
    int MAX_P_COUNT;
    
    CGFloat bucketHeight;
    
}

@property (retain, nonatomic) CCRenderTexture *target;
@property (retain, nonatomic) CCSprite *brush;
@property (retain, nonatomic) CCSprite *clearBrush;
//@property (retain, nonatomic) CBSpriteLabel *healthLabel;
@property (retain, nonatomic) CBSpriteLabel *scoreLabel;
@property (retain, nonatomic) CCMenu *gamePauseMenu;
@property (retain, nonatomic) CBGameOverPopup *gameOverPopup;
@property (retain, nonatomic) CBPauseMenuPopup *pauseMenuPopup;
@property (retain, nonatomic) CCSprite *newBestScore;
@property (retain, nonatomic) CCSprite *bottomBg;
@property (retain, nonatomic) CCSprite *bottomPipes;

// for help scene
@property (retain, nonatomic) CCSprite *finger;
@property (retain, nonatomic) CCLabelTTF *helpText;
@property (retain, nonatomic) CCSprite *goBtn;


// ccsprite batch nodes
@property (retain, nonatomic) CCSpriteBatchNode *balls;
@property (retain, nonatomic) CCSpriteBatchNode *bucketBN;

@property (retain, nonatomic) CCSpriteBatchNode *fish_new;
@property (retain, nonatomic) CCSpriteBatchNode *fish_old;;

@property (nonatomic, assign) BOOL isFirstHelpWalls;
@property (nonatomic, assign) BOOL nextLevelProcessing;
@property (nonatomic, assign) BOOL touchStarted;
@property (nonatomic, assign) BOOL isSoundEnabled;
@property (nonatomic, assign) BOOL wasPlayed;
@property (nonatomic, assign) BOOL gameEnded;

@property (nonatomic, retain) UITapGestureRecognizer* tapRecognizer;


// choose fish part
@property (retain, nonatomic) CCMenu *chooseFishMenu;
@property (retain, nonatomic) CCLabelTTF *chooseFishTitle;
@property (retain, nonatomic) CCSprite *chooseMenuBG;

-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;

@end

@implementation CBMainGameLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	CBMainGameLayer *layer = [CBMainGameLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
        
        bucketHeight = BUCKET_HEIGHT;
        MAX_P_COUNT = MAX_POINTS_COUNT;
        
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            MAX_P_COUNT *= 2;
            bucketHeight *= 2.45f;
        } else if ( IS_IPHONE_6P)
        {
            MAX_P_COUNT *= 2;
            bucketHeight *= 1.3f;
        }
		
		// enable events
        
        _overallPointCount = 0;
		
		self.touchEnabled = YES;
		self.accelerometerEnabled = NO;
        
        _gameEnded = NO;
        newRecord = NO;
        
        _isSoundEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:BG_MUSIC_KEY] isEqualToString:@"YES"];
        
		CGSize s = [CCDirector sharedDirector].winSize;
		
		// init physics
		[self initPhysics];
		
        [self createBuckets];
		
		//Set up sprite
		CCSprite *bg = [CCSprite spriteWithFile:@"main_bg.png"];
        bg.position = ccp(s.width/2, s.height/2);
        //bg.opacity = 127;
        [self addChild:bg z:-1];
        
        //[self addChild:self.bucketBN z:3];
        
        [self preloadSounds];
        
        
        health = INITIAL_HEALTH;
        score = 0;
        bestScore = 0;
        
                
        _points = [[NSMutableArray alloc] init];
        _wallSprites = [[NSMutableArray alloc] init];
        _bodies = [[NSMutableArray alloc] init];
        
        _target = [[CCRenderTexture renderTextureWithWidth:s.width height:s.height pixelFormat:kCCTexture2DPixelFormat_RGBA4444] retain];
        _target.position = ccp(s.width/2, s.height/2);
        
        [self addChild:_target z:4];
        
        _brush = [[CCSprite spriteWithFile:@"largeBrush.png"] retain];
        _clearBrush = [[CCSprite spriteWithFile:@"largeClearBrush.png"] retain];
        [_clearBrush setBlendFunc:(ccBlendFunc) { GL_ZERO,GL_ONE_MINUS_SRC_ALPHA }];
        [_clearBrush setOpacity:100];
        
        
        //[self addBucketRects];
        self.bottomPipes = [CCSprite spriteWithFile:@"game_bottom_pipes.png"];
        //self.bottomPipes.opacity = 127;
        [self addChild:_bottomPipes z:5];
        self.bottomPipes.position = ccp(s.width/2, -_bottomPipes.contentSize.height/2);
        
        
        _bottomBg = [[CCSprite spriteWithFile:@"menu_bottom_herbs.png"] retain];
        [self addChild:_bottomBg z:6];
        _bottomBg.position = ccp(s.width/2, -_bottomBg.boundingBox.size.height/2);
        
        self.isHelpScene = NO;
        _isFirstHelpWalls = NO;
        _nextLevelProcessing = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:@"cbDidBecomeActiveNotification" object:nil];
        
        self.tapRecognizer = [self watchForPan:@selector(tapping:) number:2];
        
        [self initFish];
        
        [self scheduleUpdate];
	}
	return self;
}

- (UITapGestureRecognizer *)watchForPan:(SEL)selector number:(int)tapsRequired {
    UITapGestureRecognizer *recognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:selector] autorelease];
    recognizer.numberOfTapsRequired = tapsRequired;
    [[[CCDirector sharedDirector] openGLView] addGestureRecognizer:recognizer];
    return recognizer;
}

- (void)unwatch:(UIGestureRecognizer *)gr {
    [[[CCDirector sharedDirector] openGLView] removeGestureRecognizer:gr];
}

-(void)initFish
{
    self.fish_new = [CCSpriteBatchNode batchNodeWithFile:@"fishes.png" capacity:4];
    self.fish_old = [CCSpriteBatchNode batchNodeWithFile:@"fishes_old.png" capacity:4];

    newFishTexture_ = [self.fish_new texture];
    oldFishTexture_ = [self.fish_old texture];
}

-(void)preloadSounds
{
    [[CBAudioEngine sharedEngine] preloadEffect:@"fish_1.mp3"];
    [[CBAudioEngine sharedEngine] preloadEffect:@"fish_2.mp3"];
    [[CBAudioEngine sharedEngine] preloadEffect:@"fish_3.mp3"];
    [[CBAudioEngine sharedEngine] preloadEffect:@"fish_4.mp3"];
    [[CBAudioEngine sharedEngine] preloadEffect:@"fish_well.mp3"];
}

-(void)onExit
{
    [self unwatch:self.tapRecognizer];
}

-(void) dealloc
{
	delete world;
	world = NULL;
    
    [spriteTexture_ release];
    [newFishTexture_ release];
    [oldFishTexture_ release];
    [bucketsTexture release];
    
    self.balls = nil;
    self.fish_new = nil;
    self.fish_old = nil;
    
    self.tapRecognizer = nil;
    self.target = nil;
    self.brush = nil;
    self.clearBrush = nil;
    //self.healthLabel = nil;
    self.bucketBN = nil;
    self.chooseFishTitle = nil;
    self.chooseFishMenu = nil;
    self.chooseMenuBG = nil;
    self.gamePauseMenu = nil;
    self.gameOverPopup = nil;
    self.bottomBg = nil;
    self.bottomPipes = nil;
    
    if (_isHelpScene) {
        self.finger = nil;
        self.helpText = nil;
        self.goBtn = nil;
        [_firstWall release], _firstWall = nil;
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"cbDidBecomeActiveNotification" object:nil];
        
        bannerView_.delegate = nil;
        [bannerView_ release];
    }
    
    self.newBestScore = nil;
    
    [_bodies release];
    [_points release];
    [_wallSprites release];
    [_bucketRects release];
	
	[super dealloc];
}

-(void)startHelp
{
    CGSize s = [CCDirector sharedDirector].winSize;
    
    [_finger setPosition:ccp(s.width*0.85f, s.height*0.85f )];
    
    CGFloat yOffset = 0.48f;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        yOffset = 0.40f;
    }
    [_helpText setPosition:ccp(s.width*0.5f, s.height*yOffset)];
    
    [_finger runAction:[CCFadeIn actionWithDuration:0.5f]];
    [_helpText runAction:[CCFadeIn actionWithDuration:0.5f]];
    
    //[self performSelector:@selector(drawLine) withObject:nil afterDelay:1.0f];
    [self runAction:[CCSequence actions:
                     //[CCDelayTime actionWithDuration:2.0f],
                     [CCCallFunc actionWithTarget:self selector:@selector(drawLine)],
                     [CCDelayTime actionWithDuration:2.5f],
                     [CCCallFunc actionWithTarget:self selector:@selector(addFish)],
                     [CCDelayTime actionWithDuration:3.0f],
                     [CCCallFunc actionWithTarget:self selector:@selector(drawSecondLine)],
                     [CCDelayTime actionWithDuration:3.0f],
                     [CCCallFunc actionWithTarget:self selector:@selector(addSecondFish)],
                     [CCDelayTime actionWithDuration:3.0f],
                     [CCCallFunc actionWithTarget:self selector:@selector(showLifes)],
                     [CCDelayTime actionWithDuration:3.0f],
                     [CCCallFunc actionWithTarget:self selector:@selector(showScore)],
                     [CCDelayTime actionWithDuration:3.0f],
                     [CCCallFunc actionWithTarget:self selector:@selector(changeLabelAgain)],
                     [CCDelayTime actionWithDuration:3.0f],
                     [CCCallFunc actionWithTarget:self selector:@selector(showLastSprites)],
    nil]];
}

-(void)changeLabelAgain
{
    [self changeStringWithAnimation:NSLocalizedString(@"help_6", nil)];
    [_finger runAction:[CCFadeOut actionWithDuration:0.5f]];
    [self removeWalls:_firstWall];
    [self removeWalls:_points];
}

-(void)showLastSprites
{
    CGSize s = [CCDirector sharedDirector].winSize;
    
    self.touchEnabled = YES;
    _touchStarted = NO;
    
    CGFloat offset = 10.0f;
    CGFloat yoffest = 0.25f;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        offset *= 2;
        yoffest = 0.3f;
    }
    
    [_helpText runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:0.5f] two:[CCCallBlock actionWithBlock:^{
     
        [_helpText setString:NSLocalizedString(@"help_7", nil)];
        //NSLog(@"SIZE = %f/%f",_helpText.contentSize.width, s.width);
        //[self changeStringWithAnimation:NSLocalizedString(@"help_7", nil)];
        self.goBtn = [CCSprite spriteWithFile:@"goButton.png"];
        _goBtn.anchorPoint = ccp(0.0f,0.0f);
        _goBtn.opacity = 0;
        _goBtn.tag = 12;
        [self addChild:_goBtn];
        _helpText.anchorPoint = ccp(0.5f, 0.0f);
        _helpText.position = ccp(s.width/2 - _goBtn.contentSize.width/2, s.height*yoffest);
        _goBtn.position = ccp(_helpText.position.x + _helpText.contentSize.width/2, _helpText.position.y);
        [_helpText runAction:[CCFadeIn actionWithDuration:0.5f]];
        [_goBtn runAction:[CCSequence actions: /*[CCDelayTime actionWithDuration:0.5f], */[CCFadeIn actionWithDuration:0.5f], [CCCallBlock actionWithBlock:^{
            [_goBtn runAction:[CCRepeatForever actionWithAction:[CCSequence actionOne:[CCMoveBy actionWithDuration:0.4f position:ccp(0,5)] two:[CCMoveBy actionWithDuration:0.2f position:ccp(0,-5)]]]];
        }], nil]];
    }]]];
    
    
}

-(void)showScore
{
    CGSize s = [CCDirector sharedDirector].winSize;
    //[_scoreLabel runAction:[CCFadeIn actionWithDuration:1.0f]];
    [self.scoreLabel runAction:[CCMoveTo actionWithDuration:1.0f position:ccp(10, s.height-30)]];
    [self changeStringWithAnimation:NSLocalizedString(@"help_5", nil)];
}

-(void)showLifes
{
    CGSize s = [CCDirector sharedDirector].winSize;
    //[self.healthLabel runAction:[CCMoveTo actionWithDuration:1.0f position:ccp(s.width - _healthLabel.contentSize.width - 5, s.height-30)]];
    [self changeStringWithAnimation:[NSString stringWithFormat:NSLocalizedString(@"help_4_%d", nil), INITIAL_HEALTH]];
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        [_helpText runAction:[CCMoveBy actionWithDuration:0.5f position:ccp(0, 40.0f)]];
    }
}

-(void)drawLineFromPoint:(CGPoint)start toPoint:(CGPoint)end withHandRotation:(CGFloat)angle
{
    [_finger runAction:[CCSpawn actionOne:[CCRotateBy actionWithDuration:0.5f angle:angle] two:[CCMoveTo actionWithDuration:0.5f position:end]]];
    
    float dist = ccpDistance(end, start);
    // number of points equals to distance between start and end points
    int num_of_steps = (int)ceil(dist);
    
    float step_x = (end.x - start.x) / dist;
    float step_y = (end.y - start.y) / dist;
    
    [self processFirstTouchForPosition:start];
    
    _pointCount = 1;
    
    //[_finger runAction:[CCMoveTo actionWithDuration:0.5f position:end]];
    
    for (int i=1; i<num_of_steps; ++i) {
        [self processTouchForPosition:ccp(start.x + i * step_x, start.y + i * step_y) previousPosition:ccp(start.x + (i-1) * step_x, start.y + (i-1) * step_y)];
        _pointCount++;
    }
    
    [self processEndTouchForPosition:end];

}

-(void)drawLine
{
    int line_length = 80;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        line_length *= 3;
    }
    
    CGPoint start = _finger.position;
    CGPoint end = ccp(start.x - line_length, start.y - line_length);
    [self drawLineFromPoint:start toPoint:end withHandRotation:0];
    
    
    _firstWall = [[NSMutableArray arrayWithArray:_points] retain];
    [_points removeAllObjects];
}

-(void)changeStringWithAnimation: (NSString*)newString
{
    [_helpText runAction:[CCSequence actions:[CCFadeOut actionWithDuration:0.5f],
                          [CCCallBlockN actionWithBlock:^(CCNode *node) {
        [(CCLabelTTF*)node setString:newString];
    }],
                          [CCFadeIn actionWithDuration:0.5f],
                          nil]];
}

-(void)addFish
{
    CGSize s = [CCDirector sharedDirector].winSize;
    
    [self changeStringWithAnimation:NSLocalizedString(@"help_2", nil)];
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        [_helpText runAction:[CCMoveBy actionWithDuration:0.5f position:ccp(0, -20.0f)]];
    }
    
    [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:3.0f] two:[CCCallBlock actionWithBlock:^{
        [self addNewSpriteAtPosition:ccp(s.width/2, s.height)];
    }]]];
}

-(void)addSecondFish
{
    CGSize s = [CCDirector sharedDirector].winSize;
    
    [self addNewSpriteAtPosition:ccp(s.width/2, s.height)];
}

-(void)drawSecondLine
{
    CGSize s = [CCDirector sharedDirector].winSize;
    int line_length = 100;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        line_length *= 3;
    }
    
    [self changeStringWithAnimation:NSLocalizedString(@"help_3", nil)];
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        [_helpText runAction:[CCMoveBy actionWithDuration:0.5f position:ccp(0, -50.0f)]];
    }
    
    [_finger runAction:[CCSequence actions:[CCDelayTime actionWithDuration:2.0f],
                                        [CCMoveTo actionWithDuration:1.0f position:ccp(30+line_length, s.height/2-line_length/2)],
                                        [CCCallBlock actionWithBlock:^{
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            [_helpText runAction:[CCMoveBy actionWithDuration:0.5f position:ccp(0, 80.0f)]];
        }
        [self drawLineFromPoint:ccp(30+line_length, s.height/2-line_length/2) toPoint:ccp(10, s.height/2) withHandRotation:90.0f];
    }], nil]];
}

-(void)chooseOldFish
{
    self.balls = self.fish_old;
    spriteTexture_ = oldFishTexture_;
    
    [self addChild:self.balls z:2];
}

-(void)chooseNewFish
{
    self.balls = self.fish_new;
    spriteTexture_ = newFishTexture_;
    
    [self addChild:self.balls z:2];
}

-(void)setIsHelpScene:(BOOL)isHelpScene
{
    _isHelpScene = isHelpScene;
    
    CGFloat fontSize = 12.0f;
    CGFloat fontSizeHelp = 24.0f;
    CGFloat offset = 90.0f;
    CGFloat fontSizeChoose = 24.0f;
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        fontSize *= 2;
        fontSizeHelp *= 2;
        offset *= 1.5f;
        fontSizeChoose *=2;
    } else if ( IS_IPHONE_6P)
    {
        offset *= 1.25f;
    }
    
    //self.healthLabel = [CBSpriteLabel spriteWithFile:@"health_button.png" labelText:[NSString stringWithFormat:NSLocalizedString(@"Health: %d", nil), health] fontName:NSLocalizedString(@"stat_font", nil) fontSize:fontSize];
    //[self addChild:self.healthLabel z:0];
    //self.healthLabel.anchorPoint = ccp(0.0f,1.0f);
    //self.healthLabel.position = ccp( s.width, s.height-30);
    
    self.scoreLabel = [CBSpriteLabel spriteWithFile:@"health_button.png" labelText:[NSString stringWithFormat:NSLocalizedString(@"Score: %d", nil), score] fontName:NSLocalizedString(@"stat_font", nil) fontSize:fontSize];
    [self addChild:self.scoreLabel z:0];
    self.scoreLabel.anchorPoint = ccp(0.0f,1.0f);
    self.scoreLabel.position = ccp(-_scoreLabel.contentSize.width, s.height-30);
    
    if (isHelpScene)
    {
        //self.healthLabel.visible = YES;
        self.scoreLabel.visible = YES;
        _isFirstHelpWalls = YES;
        
        self.touchEnabled = NO;
        
        self.finger = [CCSprite spriteWithFile:@"pointer.png"];
        _finger.opacity = 0;
        _finger.anchorPoint = ccp(0,1.0f);
        [self addChild:_finger];
        
        self.helpText = [CCLabelTTF labelWithString:NSLocalizedString(@"help_1", nil) fontName:NSLocalizedString(@"main_font", nil) fontSize:fontSizeChoose];
        _helpText.opacity = 0;
        _helpText.anchorPoint = ccp(0.5f,0.0f);
        [self addChild:_helpText z:7];
        
        [self chooseOldFish];
        
    } else {
        
        //self.healthLabel.visible = NO;
        self.scoreLabel.visible = NO;
        
        self.touchEnabled = YES;
        _touchStarted = NO;
        
        [self retrieveTopTenScores];
        
		//self.healthLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:NSLocalizedString(@"Health: %d", nil), health] fontName:@"Marker Felt" fontSize:fontSize];

        
        //self.scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:NSLocalizedString(@"Score: %d", nil), score] fontName:@"Marker Felt" fontSize:fontSize];
        
        
        // Choose fish part
        self.chooseFishTitle = [CCLabelTTF labelWithString:NSLocalizedString(@"choose_fish", nil) fontName:NSLocalizedString(@"main_font", nil) fontSize:fontSizeHelp];
        CCMenuItemImage *leftFish = [CCMenuItemImage itemWithNormalImage:@"fish_two.png" selectedImage:@"fish_two.png" target:self selector:@selector(fishChosen:)];
        leftFish.tag = LEFT_FISH;
        
        CCMenuItemImage *rightFish = [CCMenuItemImage itemWithNormalImage:@"fish_one.png" selectedImage:@"fish_one.png" target:self selector:@selector(fishChosen:)];
        rightFish.tag = RIGHT_FISH;
        
        self.chooseFishMenu = [CCMenu menuWithItems:leftFish, rightFish, nil];
        [_chooseFishMenu alignItemsHorizontallyWithPadding:50.0f];
        
        self.chooseMenuBG = [CCSprite spriteWithFile:@"game_over_bg.png"];
        
        [self addChild:_chooseMenuBG];
        [self addChild:_chooseFishTitle];
        [self addChild:_chooseFishMenu];
        
        _chooseMenuBG.position = ccp(s.width*0.5f, s.height*0.5f);
        _chooseFishTitle.position = ccp(s.width*0.5f, s.height*0.55f);
        _chooseFishMenu.position = ccp(s.width*0.5f, s.height*0.45f);
        
        _chooseMenuBG.opacity = 0;
        _chooseFishMenu.opacity = 0;
        _chooseFishTitle.opacity = 0;
        
        
        
        self.gameOverPopup = [CBGameOverPopup popup];
        self.gameOverPopup.position = ccp(s.width + self.gameOverPopup.contentSize.width, s.height/2 + BUCKET_HEIGHT/2);
        [self addChild:self.gameOverPopup];
        [self.gameOverPopup setPopupScore:score];
        [self.gameOverPopup setPopupBestScore:bestScore];
        self.gameOverPopup.delegate = (id)self;
        
        CCMenuItemImage *gameMenuButton = [CCMenuItemImage itemWithNormalImage:@"menu_button.png" selectedImage:@"menu_button.png" target:self selector:@selector(menuButtonPressed:)];
        self.gamePauseMenu = [CCMenu menuWithItems:gameMenuButton, nil];
        [self addChild:self.gamePauseMenu];
        self.gamePauseMenu.position = ccp(-self.gamePauseMenu.contentSize.width, s.height - offset);
    }
    
    self.pauseMenuPopup = [CBPauseMenuPopup popup];
    self.pauseMenuPopup.position = ccp(s.width + self.pauseMenuPopup.contentSize.width, s.height/2);
    self.pauseMenuPopup.visible = NO;
    self.pauseMenuPopup.delegate = (id)self;
    self.pauseMenuPopup.isHelpScene = isHelpScene;
    [self addChild:self.pauseMenuPopup z:5];

}

- (void)didBecomeActive
{
    _touchStarted = NO;
}

- (void)hidePauseMenu
{
    CGSize s = [CCDirector sharedDirector].winSize;
    [self.pauseMenuPopup runAction:[CCSequence actionOne:[CCMoveTo actionWithDuration:0.25f position:ccp(-self.pauseMenuPopup.contentSize.width, self.pauseMenuPopup.position.y)] two:[CCCallBlock actionWithBlock:^{
        self.pauseMenuPopup.visible = NO;
        self.pauseMenuPopup.position = ccp(s.width + self.pauseMenuPopup.contentSize.width, s.height/2);
        _touchStarted = NO;
        [self resumeSchedulerAndActions];
    }]]];
}

- (void)menuButtonPressed:(id)sender
{
    
    if (health == 0)
        return;
    
    CGSize s = [CCDirector sharedDirector].winSize;
    if (self.pauseMenuPopup.visible)
    {
        [self hideBanner];
        [self hidePauseMenu];
    } else {
        [self showBanner];
        [self pauseSchedulerAndActions];
        self.pauseMenuPopup.visible = YES;
        [self.pauseMenuPopup runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(s.width/2, self.pauseMenuPopup.position.y)]];
    }
    
}

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(void) saveUserRecords {
    NSString *path = [[[self applicationDocumentsDirectory] stringByAppendingPathComponent:USER_RECORDS_FILENAME] stringByAppendingString:@".plist"];
    
    NSMutableDictionary* plist;
    if (![[NSFileManager defaultManager] fileExistsAtPath: path])
        plist = [[NSMutableDictionary alloc] init];
    else
        plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    [plist setValue:[NSNumber numberWithInt:bestScore] forKey:USER_RECORDS_KEY];
    [plist writeToFile:path atomically:YES];
    [plist release];
}

- (void) retrieveTopTenScores
{
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
    if (leaderboardRequest != nil)
    {
        leaderboardRequest.playerScope = GKLeaderboardPlayerScopeGlobal;
        leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
        leaderboardRequest.identifier = CB_LEADERBOARD_ID;
        leaderboardRequest.range = NSMakeRange(1,1);
        [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            
            //NSLog(@"%d", [scores count]);
            
            if (error != nil)
            {
                [self loadUserRecords];
            }
            //if (scores != nil)
            //{
                int newBestScore = leaderboardRequest.localPlayerScore.value;
                if (bestScore > newBestScore)
                    [self reportScore:bestScore forLeaderboardID:CB_LEADERBOARD_ID];
                else
                    bestScore = newBestScore;
            //}
        }];
    }
}

-(void) loadUserRecords {
    NSString *path = [[[self applicationDocumentsDirectory] stringByAppendingPathComponent:USER_RECORDS_FILENAME] stringByAppendingString:@".plist"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path])
        bestScore = 0;
    else {
        NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        bestScore = [[plist valueForKey:USER_RECORDS_KEY] intValue];
        [plist release];
    }
}

-(void) addBall: (ccTime) dt
{
    CGSize s = [CCDirector sharedDirector].winSize;
    
    [self addNewSpriteAtPosition:ccp(s.width/2, s.height)];
}

-(void) restartGame
{
    _overallPointCount = 0;
    newRecord = NO;
    _touchStarted = NO;
    _gameEnded = NO;
    
    [self resumeSchedulerAndActions];
    [self unschedule:@selector(addBall:)];
    [self schedule:@selector(addBall:) interval:4.0f];
    
    health = INITIAL_HEALTH;
    score = 0;
    
    //[self.healthLabel.spriteLabel setString:[NSString stringWithFormat:NSLocalizedString(@"Health: %d", nil), health]];
    [self.scoreLabel.spriteLabel setString:[NSString stringWithFormat:NSLocalizedString(@"Score: %d", nil), score]];
    
    CGSize s = [CCDirector sharedDirector].winSize;
    //[self.healthLabel runAction:[CCMoveTo actionWithDuration:0.3f position:ccp( s.width - _healthLabel.contentSize.width - 5, s.height-30)]];
    
    self.touchEnabled = YES;
}

- (void) reportScore: (int64_t) l_score forLeaderboardID: (NSString*) category
{
    GKScore *scoreReporter = [[GKScore alloc] initWithCategory:category];
    scoreReporter.shouldSetDefaultLeaderboard = YES;
    scoreReporter.value = l_score;
    scoreReporter.context = 0;
    
    [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
        // Do something interesting here.
    }];
    
    
}

-(void) showRecordBadge
{
    if (!newRecord)
        return;
    
    self.newBestScore = [CCSprite spriteWithFile:@"new_record.png"];
    [self addChild:_newBestScore];
    _newBestScore.position = _gameOverPopup.position;
    
    _newBestScore.scale = 5.0f;
    
    CGFloat actDuration = 0.7f;
    
    CGFloat offset = 20.0f;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        offset *= 2;
    }
    
    [_newBestScore runAction:[CCSpawn actions:[CCMoveTo actionWithDuration:actDuration position:ccp(_gameOverPopup.position.x - _gameOverPopup.contentSize.width/2 + offset, _gameOverPopup.position.y - _gameOverPopup.contentSize.height/2)], [CCScaleTo actionWithDuration:actDuration scale:1.0f], [CCRotateBy actionWithDuration:actDuration angle:15.0f], nil]];
}

-(void)deleteAllBodies
{
    for (b2Body *b = world->GetBodyList(); b; b = b->GetNext()) {
        if (b->GetUserData() != NULL) {
            
            CCPhysicsSprite *ball = (CCPhysicsSprite*)b->GetUserData();
            
            world->DestroyBody(b);
            [ball removeFromParentAndCleanup:YES];
        }
    }
}

-(void) performGameOver
{
    [self unschedule:@selector(addBall:)];
    
    //self.touchEnabled = NO;
    _gameEnded = YES;
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    [self reportScore:score forLeaderboardID:CB_LEADERBOARD_ID];
    
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
    if (leaderboardRequest != nil)
    {
        leaderboardRequest.playerScope = GKLeaderboardPlayerScopeGlobal;
        leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
        leaderboardRequest.identifier = CB_LEADERBOARD_ID;
        leaderboardRequest.range = NSMakeRange(1,1);
        [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            
            if (error != nil)
            {
            }

            int newBestScore = leaderboardRequest.localPlayerScore.value;
            if (bestScore > newBestScore)
                [self reportScore:bestScore forLeaderboardID:CB_LEADERBOARD_ID];
            else
                bestScore = newBestScore;
        }];
    }

    
    [self.gameOverPopup setPopupScore:score];
    [self.gameOverPopup setPopupBestScore:bestScore];
    [self.gameOverPopup runAction:[CCSequence actionOne:[CCMoveTo actionWithDuration:1.0f position:ccp(s.width/2, self.gameOverPopup.position.y)] two:[CCCallFunc actionWithTarget:self selector:@selector(showRecordBadge)]]];
    
    [self showBanner];
    
    if (newRecord)
    {
        [self reportScore:bestScore forLeaderboardID:CB_LEADERBOARD_ID];
    }
    
    [self deleteAllBodies];
    
    //[self performSelector:@selector(restartGame) withObject:nil afterDelay:4.0f];
}

-(void) addBucketRects
{
    _bucketRects = [[NSMutableArray alloc] init];
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    CGFloat bucketWidth = s.width / 4.0f;
    
    int leftAlign = 2;
    
    for (int i=0; i<4; ++i) {
        
        CGFloat leftPos = i*bucketWidth + leftAlign;
        
        int idx = (i == 1) || (i == 3);
        int idy = (i == 2) || (i == 3);
        
        int internalWidth = 75;
        int internalHeight = 114;
        
        CGRect rect = CGRectMake(leftPos-16, -16, bucketWidth+32, BUCKET_HEIGHT);
        
        CCSprite *bucket = [CCSprite spriteWithTexture:bucketsTexture rect:CGRectMake(internalWidth * idx, internalHeight * idy, internalWidth ,internalHeight)];
        [self.bucketBN addChild:bucket z:3];
        bucket.anchorPoint = ccp(0,0);
        bucket.position = ccp(leftPos,0);
        
//        CCSprite *bucket_top = [CCSprite spriteWithTexture:bucketsTopTexture rect:CGRectMake(bucketWidth * idx, 17 * idy, bucketWidth ,17)];
//        
//        [self.topBucketBN addChild:bucket_top z:1];
//        bucket_top.anchorPoint = ccp(0,0);
//        bucket_top.position = ccp(leftPos, bucket.boundingBox.size.height-7);
        
        [_bucketRects addObject:[NSValue valueWithCGRect:rect]];
    }
    
    self.bucketBN.position = ccp(0, 0);
}

-(void) onEnterTransitionDidFinish
{
    CGSize s = [CCDirector sharedDirector].winSize;
    
    //self.healthLabel.visible = YES;
    self.scoreLabel.visible = YES;
    
    CGFloat animTime = 1.0f;
    
    if (!_isHelpScene) {
        
        [self initGADBannerWithAdPositionAtTop:YES];
        [self hideBannerAnimate:NO];
        
        [self showChooseMenu];
        
    } else {
        
        //[self unschedule:@selector(addBall:)];
        //[self unschedule:@selector(gameLogic:)];
        
        [self performSelector:@selector(startHelp) withObject:nil afterDelay:2.0f];
        
        [self.bottomPipes runAction:[CCMoveTo actionWithDuration:animTime position:ccp(s.width/2, _bottomPipes.contentSize.height/2)]];
        [self.bottomBg runAction:[CCMoveTo actionWithDuration:animTime position:ccp(s.width/2, _bottomBg.contentSize.height/2)]];
    }
    
}

-(void)showChooseMenu
{
    CGFloat animTime = 1.0f;
    
    [_chooseMenuBG runAction:[CCFadeIn actionWithDuration:animTime]];
    [_chooseFishTitle runAction:[CCFadeIn actionWithDuration:animTime]];
    [_chooseFishMenu runAction:[CCFadeIn actionWithDuration:animTime]];
}

-(void)hideChooseMenu
{
    CGFloat animTime = 0.5f;
    [_chooseMenuBG runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:animTime] two:[CCCallBlockN actionWithBlock:^(CCNode *node) {
        _chooseMenuBG.visible = NO;
    }]]];
    [_chooseFishMenu runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:animTime] two:[CCCallBlockN actionWithBlock:^(CCNode *node) {
        _chooseFishMenu.visible = NO;
    }]]];
    [_chooseFishTitle runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:animTime] two:[CCCallBlockN actionWithBlock:^(CCNode *node) {
        _chooseFishTitle.visible = NO;
    }]]];
}

-(void)fishChosen: (id)sender
{
    [self hideChooseMenu];
    
    CCMenuItemImage *senderItem = (CCMenuItemImage*)sender;
    
    if (senderItem.tag == LEFT_FISH)
        [self chooseOldFish];
    else
        [self chooseNewFish];
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    CGFloat rightOffset = 30;
    CGFloat offset = 90.0f;
    CGFloat leftOffset = 30.0f;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        rightOffset *= 2;
        offset *=2;
        leftOffset *=2;
    } else if (IS_IPHONE_6P)
    {
        offset *=1.25f;
        leftOffset *=1.25f;
    }
    
    CGFloat animTime = 1.0f;
    
    //[self.healthLabel runAction:[CCMoveTo actionWithDuration:animTime position:ccp( s.width - _healthLabel.contentSize.width - 5, s.height-30)]];
    [self.scoreLabel runAction:[CCMoveTo actionWithDuration:animTime position:ccp(10, s.height-30)]];
    [self.gamePauseMenu runAction:[CCMoveTo actionWithDuration:animTime position:ccp(leftOffset, s.height - offset)]];
    
    [self schedule:@selector(addBall:) interval:4.0f];
    [self schedule:@selector(gameLogic:)];
    
    [self.bottomPipes runAction:[CCMoveTo actionWithDuration:animTime position:ccp(s.width/2, _bottomPipes.contentSize.height/2)]];
    [self.bottomBg runAction:[CCMoveTo actionWithDuration:animTime position:ccp(s.width/2, _bottomBg.contentSize.height/2)]];
}

-(void) onEnter
{
    [super onEnter];
    
    //[[CBAudioEngine sharedEngine] stopBackgroundMusic];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *play = [userDefaults objectForKey:BG_MUSIC_KEY];
    if (play != nil)
    {
        if ([play isEqualToString:@"YES"]) {
            [[CBAudioEngine sharedEngine] playBackgroundMusic:@"main_theme.mp3" loop:YES];
            self.wasPlayed = YES;
        }
        else
        {
            //[self.toggleItem setSelectedIndex:1];
            [[CBAudioEngine sharedEngine] preloadBackgroundMusic:@"main_theme.mp3"];
            self.wasPlayed = NO;
        }
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[CBAudioEngine sharedEngine] fadeBackgroundMusicFrom:0.0f to:1.0f duration:0.5f];
    });
}


-(CGFloat)getIntervalForScore
{
    CGFloat nextTime;
    
    if (score > 45)
        nextTime = 0.4f;
    else
        nextTime = 4 - (4*score / 50.0f);

    return nextTime;
}

-(void) gameLogic: (ccTime) dt
{
    for (int i=0; i<[_bucketRects count]; ++i) {
        
        CGRect bucket = [[_bucketRects objectAtIndex:i] CGRectValue];
        
        for (b2Body *b = world->GetBodyList(); b; b = b->GetNext()) {
            if (b->GetUserData() != NULL) {
                CCPhysicsSprite *ball = (CCPhysicsSprite*)b->GetUserData();
                
                if (ball.tag == DELETED_BODY_TAG)
                    continue;
                
                if (CGRectContainsPoint(bucket, ball.position))
                {
                    if (_isSoundEnabled)
                        [[CBAudioEngine sharedEngine] playEffect:@"fish_well.mp3"];
                    
                    if (ball.tag != i) {
                        
                        --health;
                        
                        //[self.healthLabel.spriteLabel setString:[NSString stringWithFormat:NSLocalizedString(@"Health: %d", nil), --health]];
                        
//                        if (health == 9) {
//                            CGSize s = [CCDirector sharedDirector].winSize;
//                            [self.healthLabel runAction:[CCMoveTo actionWithDuration:0.3f position:ccp( s.width - _healthLabel.contentSize.width - 5, s.height-30)]];
//                        }
                        
                        if (health == 0)
                        {
                            [self performGameOver];
                            return;
                        }
                        
                    } else {
                        
                        [self.scoreLabel.spriteLabel setString:[NSString stringWithFormat:NSLocalizedString(@"Score: %d", nil), ++score]];
                        if (score > bestScore)
                        {
                            bestScore = score;
                            newRecord = YES;
                            [self saveUserRecords];
                        }
                        
                        if (score % 5 == 0 && !_nextLevelProcessing)
                        {
                            _nextLevelProcessing = YES;
                            
                            [self unschedule:@selector(addBall:)];
                            
                            CGFloat nextTime = [self getIntervalForScore];
                            
                            //NSLog(@"Interval = %f", nextTime);
                            
                            [self addBall:1.0f];
                            [self performSelector:@selector(nextLevelForTime:) withObject:[NSNumber numberWithFloat:nextTime] afterDelay:0.0f];
                        }
                        
                    }
                    
                    ball.tag = DELETED_BODY_TAG;
                    
                    [ball runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:0.15f] two:[CCCallBlockN actionWithBlock:^(CCNode *node) {
                        
                        [node removeFromParentAndCleanup:YES];
                        world->DestroyBody(b);
                    }]]];
                    
                }
                
                //NSLog(@"Ball detected!");
            }
        }
    }
}

-(void)nextLevelForTime:(NSNumber*)time
{
    [self schedule:@selector(addBall:) interval:[time floatValue]];
    _nextLevelProcessing = NO;
}

-(void) createBuckets
{
    
    _bucketRects = [[NSMutableArray alloc] init];
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    CGFloat bucketWidth = s.width/4.0f;
    CGFloat heightOffset = 0;
    
    for (int i=0; i<4; ++i) {
        
        CGFloat leftPos = i*bucketWidth;
        CGFloat rightPos = leftPos + bucketWidth;
        
        b2BodyDef corner1Def;
        corner1Def.type = b2_staticBody;
        corner1Def.position.Set(leftPos/PTM_RATIO, heightOffset);
        b2Body* corner1 = world->CreateBody(&corner1Def);
        b2EdgeShape corner1Shape;
        
        corner1Shape.Set(b2Vec2(leftPos/PTM_RATIO, heightOffset), b2Vec2(rightPos/PTM_RATIO, heightOffset));
        corner1->CreateFixture(&corner1Shape,0);
        
        corner1Shape.Set(b2Vec2(leftPos/PTM_RATIO, (heightOffset + bucketHeight)/PTM_RATIO), b2Vec2(leftPos/PTM_RATIO, heightOffset));
        corner1->CreateFixture(&corner1Shape,0);
        
        corner1Shape.Set(b2Vec2(rightPos/PTM_RATIO, (heightOffset + bucketHeight)/PTM_RATIO), b2Vec2(rightPos/PTM_RATIO, heightOffset));
        corner1->CreateFixture(&corner1Shape,0);
        
        CGRect bucket = CGRectMake(leftPos, 0, bucketWidth, bucketHeight);
        [_bucketRects addObject:[NSValue valueWithCGRect:bucket]];
        
    }
	
}

- (void)hideBanner
{
    [self hideBannerAnimate:YES];
}

- (void)hideBannerAnimate:(BOOL)animate
{
    if (animate)
    {
        [UIView animateWithDuration:0.7f animations:^{
            [bannerView_ setAlpha:0.0f];
        }];
    } else
    {
        [bannerView_ setAlpha:0.0f];
    }
}

- (void)showBannerAnimate:(BOOL)animate
{
    if (animate)
    {
        [UIView animateWithDuration:0.7f animations:^{
            [bannerView_ setAlpha:1.0f];
        }];
    } else
    {
        [bannerView_ setAlpha:1.0f];
    }
}

- (void)showBanner
{
    [self showBannerAnimate:YES];
}

- (void)backToMenuButtonPressedOnGameOver:(CBGameOverPopup*)popup
{
    [self hideBanner];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0f scene:[CBMainMenuLayer node]]];
}

- (void)restartButtonPressedOnGameOver:(CBGameOverPopup*)popup
{
    [self hideBanner];
    [self.newBestScore runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:0.5f] two:[CCCallBlockN actionWithBlock:^(CCNode *node) {
        [node removeFromParentAndCleanup:YES];
        self.newBestScore = nil;
    }]]];
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    [self.gameOverPopup runAction:[CCSequence actionOne:[CCMoveTo actionWithDuration:1.0f position:ccp(0-self.gameOverPopup.contentSize.width, self.gameOverPopup.position.y)] two:[CCMoveTo actionWithDuration:0.0f position:ccp(s.width + self.gameOverPopup.contentSize.width, self.gameOverPopup.position.y)]]];
    
    [self restartGame];
}

-(void) initPhysics
{
	
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
    
//    GLESDebugDraw *m_debugDraw = new GLESDebugDraw( PTM_RATIO );
//    world->SetDebugDraw(m_debugDraw);
//    
//    uint32 flags = 0;
//    flags += b2Draw::e_shapeBit;
//         		flags += b2Draw::e_jointBit;
//    //     		flags += b2Draw::e_aabbBit;
//    //		flags += b2Draw::e_pairBit;
//    //		flags += b2Draw::e_centerOfMassBit;
//    m_debugDraw->SetFlags(flags);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
    
    //top
    
    groundBox.Set(b2Vec2(s.width*0.5/PTM_RATIO, s.height*2/PTM_RATIO), b2Vec2(0, s.height/PTM_RATIO));
    groundBody->CreateFixture(&groundBox,0);
    
    groundBox.Set(b2Vec2(s.width*0.5/PTM_RATIO, s.height*2/PTM_RATIO), b2Vec2(s.width/PTM_RATIO, s.height/PTM_RATIO));
    groundBody->CreateFixture(&groundBox,0);
}

-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
//	
//	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
//     
//     kmGLPushMatrix();
//     
//     world->DrawDebugData();
//     
//     kmGLPopMatrix();
}

-(void) addNewSpriteAtPosition:(CGPoint)p
{
	//CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	// Define the dynamic body.
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	//b2PolygonShape dynamicBox;
	//dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
    
    
    int csize = 48;
    CGFloat rsize = 20.0f;
    if (IS_IPHONE_6P)
    {
        csize = 64;
        rsize *= 1.25f;
    }
    CGFloat powerOffset = _isHelpScene ? 2 : 7;
    
    CGFloat xHelp = 5;
    CGFloat yHelp = -4;
    
    int initialPower_x = 2;
    int initialPower_y = -1;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        csize *=2;
        rsize *=2;
        powerOffset *= _isHelpScene ? 2 : 3;
        xHelp *= 2;
        yHelp *= 2;
        initialPower_x *= 40;
        initialPower_y *= 40;
    }
    
    
    b2CircleShape circleBox;
    circleBox.m_radius = rsize/PTM_RATIO;
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &circleBox;
	fixtureDef.density = 1.0f;
	fixtureDef.friction = 0.3f;
    fixtureDef.restitution = 0.4f;
	body->CreateFixture(&fixtureDef);
	
    
    //	CCNode *parent = [self getChildByTag:kTagParentNode];
	
	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	//just randomly picking one of the images
	int idx = (CCRANDOM_0_1() > .5 ? 0:1);
	int idy = (CCRANDOM_0_1() > .5 ? 0:1);
    
    if (_isHelpScene) {
        idx = 0;
        idy = 1;
    }
    
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(csize * idx,csize * idy,csize,csize)];
    if (idx == 0)
    {
        if (idy == 0)
            sprite.tag = bodyColor1;
        else
            sprite.tag = bodyColor3;
    } else {
        if (idy == 0)
            sprite.tag = bodyColor2;
        else
            sprite.tag = bodyColor4;
    }
    
	[self.balls addChild:sprite z:2];
    
    int multi = CCRANDOM_0_1() > 0.5 ? 1 : -1;
    
    int posRandom = arc4random() % 3 - 1;
    
    if (_isHelpScene) {
        posRandom = 0;
        multi = 1;
    }
	
	[sprite setPTMRatio:PTM_RATIO];
	[sprite setB2Body:body];
	[sprite setPosition: ccp( p.x + 40*posRandom, p.y)];
    
    body->SetUserData(sprite);
    
    int maxPower = 4 + score / 5;
    
    int forceX = _isHelpScene ? xHelp : (arc4random() % maxPower) + initialPower_x;
    int forceY = _isHelpScene ? yHelp : -((int)(arc4random() % maxPower)) + initialPower_y;
    
    //NSLog(@"Force x: %d/Force y: %d", forceX, forceY);
    
    b2Vec2 force = b2Vec2(forceX*multi , forceY);
    body->ApplyLinearImpulse(force, body->GetPosition());
    body->ApplyAngularImpulse(CCRANDOM_0_1());
    
    if (!_isHelpScene && _isSoundEnabled)
    {
        int soundNum = arc4random() % 4 + 1;
        NSString *fileName = [NSString stringWithFormat:@"fish_%d.mp3", soundNum];
        [[CBAudioEngine sharedEngine] playEffect:fileName];
    }
}

-(void) update: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 5;
	int32 positionIterations = 4;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
}

- (void)createStaticWall
{
    
    // Define the ground body.
	b2BodyDef groundBodyDef;
    groundBodyDef.type = b2_staticBody;
	groundBodyDef.position.Set(0, 0);
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
    b2EdgeShape edgeShape;
    
    for (int i=1; i<[_points count]; ++i) {
        
        CGPoint prevPoint = [_points[i-1] CGPointValue];
        CGPoint nextPoint = [_points[i] CGPointValue];
        
        edgeShape.Set(b2Vec2(prevPoint.x/PTM_RATIO, prevPoint.y/PTM_RATIO), b2Vec2(nextPoint.x/PTM_RATIO, nextPoint.y/PTM_RATIO));
        groundBody->CreateFixture(&edgeShape,0);
        
    }
    
    //[self.target clear:0 g:0 b:0 a:0];
    
    [_bodies addObject:[B2BodyWrapper b2BodyWithObject:groundBody]];
    
}

-(void) registerWithTouchDispatcher
{
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL)processFirstTouchForPosition:(CGPoint)location
{
    if (location.y <= BUCKET_HEIGHT-DRAW_THRESHOLD)
        return NO;
    
    _touchStarted = YES;
    
    [_points addObject:[NSValue valueWithCGPoint:location]];
    ++_overallPointCount;
    
    //NSLog(@"Added in first");
    
    return YES;
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_isHelpScene || _gameEnded)
    {
        NSLog(@"Help Scene or game ended!");
        return YES;
    }
    
    if (_touchStarted)
    {
        NSLog(@"Touch already started!");
        return NO;
    }
    
    if (_overallPointCount > MAX_P_COUNT)
    {
        NSLog(@"Overall >!");
        return NO;
    }
    
    if (_chooseMenuBG.visible)
    {
        NSLog(@"Pause Menu!");
        return NO;
    }
    
    _pointCount = 1;
    
    CGPoint location = [touch locationInView: [touch view]];
    location = [[CCDirector sharedDirector] convertToGL: location];
    
    return [self processFirstTouchForPosition:location];
}

- (void)processTouchForPosition:(CGPoint)location previousPosition:(CGPoint)end
{
    if (location.y <= BUCKET_HEIGHT-DRAW_THRESHOLD)
        return;
    
    //NSLog(@"Prev point: %f/%f. Curr point: %f/%f", end.x, end.y, location.x, location.y);
    
    [self.target begin];
    float distance = ccpDistance(location, end);
    
    for (int i=0; i<distance; i++) {
        float difx = location.x - end.x;
        float dify = location.y - end.y;
        float delta = (float)i / distance;
        
        self.brush.position = ccp(end.x + (difx * delta), end.y + (dify * delta));
        [self.brush visit];
    }
    
    [self.target end];
    
    [_points addObject:[NSValue valueWithCGPoint:location]];
    ++_overallPointCount;
    
    //NSLog(@"Added in middle");
    
    if (_pointCount == POINT_COUNT)
    {
        NSArray *wallPoints = [NSArray arrayWithArray:_points];
        
        [self createStaticWall];
        
        if (!_isFirstHelpWalls) {

            [self performSelector:@selector(removeWalls:) withObject:wallPoints afterDelay:WALLS_DESTROY_TIME];
        
            _pointCount = 1;
            NSValue *lastValue = [[_points objectAtIndex:[_points count]-1] retain];
            [_points removeAllObjects];
            [_points addObject:lastValue];
            ++_overallPointCount;
            [lastValue release];
        }
    }

}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_isHelpScene || _gameEnded)
        return;
    
    CGPoint location = [touch locationInView: [touch view]];
    
    location = [[CCDirector sharedDirector] convertToGL: location];
    
    CGPoint end = [touch previousLocationInView:[touch view]];
    end = [[CCDirector sharedDirector] convertToGL:end];
    
    if (_overallPointCount > MAX_P_COUNT)
    {
        if (_touchStarted)
        {
            NSLog(@"Process end touch in middle!");
            [self processEndTouchForPosition:location];
        }
        else
            return;
    }
    else
    {
        _pointCount++;
        [self processTouchForPosition:location previousPosition:end];
    }
}

/*- (void)removeWalls:(NSArray*)wallPoints
 {
 CCSprite *removingSprite = [[[_wallSprites objectAtIndex:0] retain] autorelease];
 [_wallSprites removeObjectAtIndex:0];
 
 [removingSprite runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:1.0] two:[CCCallFuncN actionWithTarget:self selector:@selector(removeWall:)]]];
 
 /*    [node removeFromParentAndCleanup:YES];
 b2Body *groundBody = [[__bodies objectAtIndex:0] body];
 world->DestroyBody(groundBody);
 
 [__bodies removeObjectAtIndex:0];
 [__wallSprites removeObjectAtIndex:0];
 }]]];
 
 }
 
 - (void)removeWall:(CCNode*)node
 {
 NSLog(@"BBB");
 [node removeFromParentAndCleanup:YES];
 b2Body *groundBody = [[_bodies objectAtIndex:0] body];
 world->DestroyBody(groundBody);
 
 [_bodies removeObjectAtIndex:0];
 }*/

- (void)removeWalls:(NSArray*)wallPoints
{
    if ([wallPoints count] == 0)
        return;
    
    [self.target begin];
    
    CGPoint initPoint = [wallPoints[0] CGPointValue];
    
    int pointCount = [wallPoints count] == 2 ? 2 : 1;
    
    for (int i=0; i<pointCount; ++i) {
        self.clearBrush.position = ccp(initPoint.x, initPoint.y);
        [self.clearBrush visit];
    }
    
    //[self.target end];
    
    for (int j=0; j<2; ++j) {
        
        for (int i=1; i<[wallPoints count]; ++i) {
            
            //[self.target begin];
            
            CGPoint prevPoint = [wallPoints[i-1] CGPointValue];
            CGPoint currPoint = [wallPoints[i] CGPointValue];
            
            //NSLog(@"Dell prev point: %f/%f. Curr point: %f/%f", prevPoint.x, prevPoint.y, currPoint.x, currPoint.y);
            
            float distance = ccpDistance(currPoint, prevPoint);
            
            for (int i=0; i<distance; i++) {
                float difx = currPoint.x - prevPoint.x;
                float dify = currPoint.y - prevPoint.y;
                float delta = (float)i / (float)distance;
                
                self.clearBrush.position = ccp(prevPoint.x + (difx * delta), prevPoint.y + (dify * delta));
                //[self.clearBrush runAction:[CCMoveTo actionWithDuration:1.0f position:ccp(prevPoint.x + (difx * delta), prevPoint.y + (dify * delta))]];
                [self.clearBrush visit];
            }
            
            //[self.target end];
            
        }
    }
    
    //[self.target begin];
    
    CGPoint lastPoint = [wallPoints[[wallPoints count]-1] CGPointValue];
    
    for (int i=0; i<pointCount; ++i) {
        self.clearBrush.position = ccp(lastPoint.x, lastPoint.y);
        [self.clearBrush visit];
    }
    
    [self.target end];
    b2Body *groundBody = [[_bodies objectAtIndex:0] body];
    
    world->DestroyBody(groundBody);
    
    [_bodies removeObjectAtIndex:0];
    
    if (_overallPointCount != 0)
        _overallPointCount -= [wallPoints count];
}

- (void)processEndTouchForPosition:(CGPoint)location
{
    _touchStarted = NO;
    NSLog(@"_touchStarted = NO");
    if ([_points count] == 1)
    {
        if (CGPointEqualToPoint([[_points objectAtIndex:0] CGPointValue], location))
        {
            [_points removeAllObjects];
            return;
        }
    }
    
    if (!CGPointEqualToPoint([[_points objectAtIndex:[_points count]-1] CGPointValue], location))
    {
        if (location.y > BUCKET_HEIGHT-DRAW_THRESHOLD) {
            [_points addObject:[NSValue valueWithCGPoint:location]];
            ++_overallPointCount;
            //NSLog(@"Added in last");
        }
    }
    
    
    NSArray *wallPoints = [NSArray arrayWithArray:_points];
    
    [self createStaticWall];
    
    
    if (!_isFirstHelpWalls) {
        [self performSelector:@selector(removeWalls:) withObject:wallPoints afterDelay:4.0f];
        //[self scheduleOnce:@selector(removeWalls:) delay:4.0f];
        [_points removeAllObjects];
    }

}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [touch locationInView: [touch view]];
    location = [[CCDirector sharedDirector] convertToGL: location];
    
    if (_isHelpScene)
    {
        
        if (CGRectContainsPoint(_goBtn.boundingBox, location))
        {
            [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:2.0f scene:[CBMainMenuLayer scene] ]];
            
        }
        return;
        
    }
    if (!_touchStarted)
        return;
    
    if (CGRectContainsPoint(_newBestScore.boundingBox, location))
    {
        
        //[self showLeaderboard:CB_LEADERBOARD_ID];
        return;
    }
    
    if ([_points count] == 0)
        return;
 
    
    [self processEndTouchForPosition:location];
}

- (void) showLeaderboard: (NSString*) leaderboardID
{
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
        gameCenterController.leaderboardTimeScope = GKLeaderboardTimeScopeToday;
        gameCenterController.leaderboardCategory = leaderboardID;
        
        AppController *app =  (AppController*)[[UIApplication sharedApplication] delegate];
        gameCenterController.gameCenterDelegate = (id)app.navController;
        [app.navController presentModalViewController:gameCenterController animated:YES];
        
    }
}


#pragma mark - CBPauseMenuPopup delegate

- (void)resumeButtonPressed:(CBPauseMenuPopup*)popup
{
    [self hideBanner];
    [self menuButtonPressed:nil];
}

- (void)restartButtonPressed:(CBPauseMenuPopup*)popup
{
    if (!_isHelpScene) {
        [self hideBanner];
        [self deleteAllBodies];
        [self hidePauseMenu];
        [self restartGame];
    }
}

- (void)backToMenuButtonPressed:(CBPauseMenuPopup*)popup
{
    [self hideBanner];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0f scene:[CBMainMenuLayer node]]];
}

- (void)soundButtonPressedWithState:(CBSoundButtonState)btnState fromPopup:(CBPauseMenuPopup*)popup
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (btnState == CBSoundButtonStateOff)
    {
        [[CBAudioEngine sharedEngine] pauseBackgroundMusic];
        [userDefaults setObject:@"NO" forKey:BG_MUSIC_KEY];
        _isSoundEnabled = NO;
        self.wasPlayed = YES;
    }
    else if (btnState == CBSoundButtonStateOn) {
        
        if (self.wasPlayed)
            [[CBAudioEngine sharedEngine] resumeBackgroundMusic];
        else
            [[CBAudioEngine sharedEngine] playBackgroundMusic:@"main_theme.mp3"];
        
        [userDefaults setObject:@"YES" forKey:BG_MUSIC_KEY];
        _isSoundEnabled = YES;
    }
    [userDefaults synchronize];
}

- (void)tapping:(UITapGestureRecognizer *)recognizer {
    
    [_points removeAllObjects];
    _overallPointCount--;           // fast fix, because first point added in ccBeginTouch
    
    if (_isHelpScene)
        return;
    
    if (health == 0)
        return;
    
    if (_chooseMenuBG.visible)
        return;
    
    [self menuButtonPressed:nil];
    
}

#pragma mark - AdMod Methods

-(void)initGADBannerWithAdPositionAtTop:(BOOL)isAdPositionAtTop {
    isAdPositionAtTop_ = isAdPositionAtTop;
    
    // NOTE:
    // Add your publisher ID here and fill in the GADAdSize constant for the ad
    // you would like to request.
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    bannerView_.adUnitID = @"ca-app-pub-9979239950075108/9293652675";
    bannerView_.delegate = self;
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [bannerView_ setRootViewController:rootViewController];
    
    [rootViewController.view addSubview:bannerView_];
    [bannerView_ loadRequest:[self createRequest]];
    // Use the status bar orientation since we haven't signed up for orientation
    // change notifications for this class.
    [self resizeViewsForOrientation:
     [[UIApplication sharedApplication] statusBarOrientation]];
    
}

- (GADRequest *)createRequest {
    GADRequest *request = [GADRequest request];
    
    // Make the request for a test ad. Put in an identifier for the simulator as
    // well as any devices you want to receive test ads.
    request.testDevices = @[ /*@"859b00d449dfd0a878bc3700c6b7a040"*/ ];
    return request;
}

- (void)resizeViewsForOrientation:(UIInterfaceOrientation)toInt {
    // If the banner hasn't been created yet, no need for resizing views.
    if (!bannerView_) {
        return;
    }
    
    /*BOOL adIsShowing = [self getChildByTag:ADMOB_TAG] != nil;
    if (!adIsShowing) {
        return;
    }*/
    
    // Frame of the main RootViewController which we call the root view.
    CGSize rootViewFrame = [CCDirector sharedDirector].winSize;
    // Frame of the main RootViewController view that holds the Cocos2D view.
    CGRect glViewFrame = [[CCDirector sharedDirector] openGLView].frame;
    CGRect bannerViewFrame = bannerView_.frame;
    CGRect frame = bannerViewFrame;
    frame.size.width = glViewFrame.size.width;
    // The updated x and y coordinates for the origin of the banner.
    CGFloat yLocation = rootViewFrame.height-frame.size.height;
    CGFloat xLocation = 0.0;
    
    if (isAdPositionAtTop_) {
        // Move the root view underneath the ad banner.
        glViewFrame.origin.y = bannerViewFrame.size.height;
        // Center the banner using the value of the origin.
        if (UIInterfaceOrientationIsLandscape(toInt)) {
            // The superView has not had its width and height updated yet so use those
            // values for the x and y of the new origin respectively.
            xLocation = (rootViewFrame.height -
                         bannerViewFrame.size.width) / 2.0;
        } else {
            xLocation = (rootViewFrame.width -
                         bannerViewFrame.size.width) / 2.0;
        }
    } else {
        // Move the root view to the top of the screen.
        glViewFrame.origin.y = 0;
        // Need to center the banner both horizontally and vertically.
        if (UIInterfaceOrientationIsLandscape(toInt)) {
            yLocation = rootViewFrame.width -
            bannerViewFrame.size.height;
            xLocation = (rootViewFrame.height -
                         bannerViewFrame.size.width) / 2.0;
        } else {
            yLocation = rootViewFrame.height -
            bannerViewFrame.size.height;
            xLocation = (rootViewFrame.width -
                         bannerViewFrame.size.width) / 2.0;
        }
    }
    frame.origin = CGPointMake(xLocation, yLocation);
    bannerView_.frame = frame;
    
    if (UIInterfaceOrientationIsLandscape(toInt)) {
        // The super view's frame hasn't been updated so use its width
        // as the height.
        glViewFrame.size.height = rootViewFrame.width -
        bannerViewFrame.size.height;
        glViewFrame.size.width = rootViewFrame.height;
    } else {
        glViewFrame.size.height = rootViewFrame.height -
        bannerViewFrame.size.height;
    }
    [[CCDirector sharedDirector] openGLView].frame = glViewFrame;
    
}

#pragma mark - GADBannerViewDelegate impl

- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    NSLog(@"Received ad");
}

- (void)adView:(GADBannerView *)view
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"Failed to receive ad with error: %@", [error localizedFailureReason]);
}

//#pragma mark - iADBanner Delegate & Methods
//
//- (void) initIADBannerWithAdPositionAtTop:(BOOL)isAdPositionAtTop {
//    
//    isAdPositionAtTop_ = isAdPositionAtTop;
//    
//    iAd = [[ADBannerView alloc] initWithFrame:CGRectZero];
//    iAd.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
//    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
//    [rootViewController.view addSubview:iAd];
//    
//    CGFloat yLocation = rootViewController.view.frame.size.height-iAd.frame.size.height;
//    iAd.frame = CGRectMake(0, yLocation, iAd.frame.size.width, iAd.frame.size.height);
//    
//    
//    
//    NSLog(@"iAd Loading...");
//}
//
//-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
//    
//    NSLog(@"Error %@",[error description]);
//    
//    [iAd setHidden:YES];
//    [bannerView_ setHidden:NO];
//    
//    [self initGADBannerWithAdPositionAtTop:YES];
//}



@end
