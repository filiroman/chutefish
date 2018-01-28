//
//  CBMainMenuLayer.m
//  chute balls
//
//  Created by Roman Filippov on 26.02.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CBMainMenuLayer.h"
#import "CBMainGameLayer.h"
#import "CBAudioEngine.h"
#import "cocos2d.h"
#import "CCPhysicsSprite.h"
#import "CBMenuItemSprite.h"
#import "CBGameCenterHelper.h"

#define MAX_FISHES 15


@interface CBMainMenuLayer ()
{
    CCTexture2D *spriteTexture;
    CCTexture2D *oldTexture;
    
    CCSpriteBatchNode *spriteBatchNode;
    CCSpriteBatchNode *oldBatchNode;
    
    CCMenu *menu;
    //GLESDebugDraw *m_debugDraw;
}

@property (retain, atomic) NSMutableArray *fishes;

@property (retain, nonatomic) CCMenuItemSprite *startNewGame;
@property (retain, nonatomic) CCMenuItemSprite *about;
@property (retain, nonatomic) CCMenuItemSprite *howTo;

@property (retain, nonatomic) CCSprite *topPipes;
@property (retain, nonatomic) CCSprite *gameLogo;
@property (retain, nonatomic) CCSprite *bottomPipes;
@property (retain, nonatomic) CCSprite *bottomHerbs;

@property (retain, nonatomic) CCMenuItemToggle *toggleItem;

@property (retain, nonatomic) CBMainGameLayer *mainGameScene;

@property (nonatomic) BOOL wasPlayed;

@end

@implementation CBMainMenuLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	CBMainMenuLayer *layer = [CBMainMenuLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
    if (self = [super init])
    {
        [self initPhysics];
        [self createMenu];
        
        self.touchEnabled = YES;
        
        spriteBatchNode = [[CCSpriteBatchNode batchNodeWithFile:@"fishes.png" capacity:MAX_FISHES+1] retain];
        spriteTexture = [spriteBatchNode texture];
        
        oldBatchNode = [[CCSpriteBatchNode batchNodeWithFile:@"fishes_old.png" capacity:MAX_FISHES+1] retain];
        oldTexture = [oldBatchNode texture];
        
        [self addChild:spriteBatchNode z:-1];
        [self addChild:oldBatchNode z:-1];
        
        self.fishes = [NSMutableArray array];
        self.gameLogo = [CCSprite spriteWithFile:@"game_logo.png"];
        self.topPipes = [CCSprite spriteWithFile:@"top_pipes.png"];
        self.bottomHerbs = [CCSprite spriteWithFile:@"menu_bottom_herbs.png"];
        self.bottomPipes = [CCSprite spriteWithFile:@"menu_bottom_pipes.png"];
        
        //_bottomPipes.opacity = 127;
        
        [self addChild:self.topPipes z:2];
        [self addChild:self.gameLogo];
        [self addChild:self.bottomPipes z:0];
        [self addChild:self.bottomHerbs z:1];
        
        [self checkSettings];
        
        [self scheduleUpdate];
        [self schedule:@selector(menuLogic:) interval:5.0f];
        
        self.mainGameScene = [CBMainGameLayer node];
        
        CGSize s = [CCDirector sharedDirector].winSize;
        
        self.gameLogo.position = ccp(s.width/2, s.height/2);
        self.topPipes.position = ccp(s.width/2, s.height + _topPipes.boundingBox.size.height/2);
        self.bottomHerbs.position = ccp(s.width/2, self.bottomHerbs.contentSize.height/2);
        self.bottomPipes.position = ccp(s.width/2, self.bottomPipes.contentSize.height/2);

        //self.accelerometerEnabled = YES;
        
    }
    return self;
}

-(void) checkSettings
{
    // Check sound on/off
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *play = [userDefaults objectForKey:BG_MUSIC_KEY];
    if (play != nil)
    {
        if ([play isEqualToString:@"YES"])
            [[CBAudioEngine sharedEngine] playBackgroundMusic:@"hip_hop_bg.mp3" loop:YES];
        else {
            [self.toggleItem setSelectedIndex:1];
            //[[CBAudioEngine sharedEngine] preloadBackgroundMusic:@"hip_hop_bg.mp3"];
            self.wasPlayed = NO;
        }
        
    } else
    {
        [[CBAudioEngine sharedEngine] playBackgroundMusic:@"hip_hop_bg.mp3" loop:YES];
        [userDefaults setObject:@"YES" forKey:BG_MUSIC_KEY];
    }
    [userDefaults synchronize];
}

-(void) dealloc
{
    [self unscheduleUpdate];
    [self unschedule:@selector(menuLogic:)];
    
    delete world;
	world = NULL;
    
    [spriteTexture release];
    [oldTexture release];
    
    [spriteBatchNode release];
    [oldBatchNode release];
    [menu release];
    
    self.startNewGame = nil;
    self.howTo = nil;
    self.about = nil;
    self.toggleItem = nil;
    self.mainGameScene = nil;
    
    self.topPipes = nil;
    self.bottomHerbs = nil;
    self.bottomPipes = nil;
    self.gameLogo = nil;
    
    self.fishes = nil;
    [super dealloc];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    // Landscape left values
    b2Vec2 gravity(acceleration.x * 10, acceleration.y * 10);
    world->SetGravity(gravity);
}

-(void) registerWithTouchDispatcher
{
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}


-(void) update: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
}

-(void) onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    
    //[[CBGameCenterHelper sharedInstance] authenticateLocalUser];
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    CGFloat animationTime = 0.7f;
    
    [self.topPipes runAction:[CCMoveTo actionWithDuration:animationTime position:ccp(s.width/2, s.height - _topPipes.boundingBox.size.height/2)]];
    
    [self.gameLogo runAction:[CCSequence actionOne:[CCSpawn actionOne:[CCMoveBy actionWithDuration:animationTime position:ccp(0, 95)] two:[CCScaleTo actionWithDuration:animationTime scale:0.7f]] two:[CCCallBlock actionWithBlock:^{
        [menu runAction:[CCFadeIn actionWithDuration:animationTime]];
    }]]];
    
    /*if (IS_IPHONE_5)
        [self addNewSpriteAtPosition:ccp(s.width/2, s.height-88)];
    else
        [self addNewSpriteAtPosition:ccp(s.width/2, s.height)];*/
    
    
}

-(void) menuLogic:(ccTime)dt
{
    if ([self.fishes count] >= MAX_FISHES) {
        CCPhysicsSprite *spr = [self.fishes objectAtIndex:0];
        [spr runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:1.0f] two:[CCCallBlockN actionWithBlock:^(CCNode *node) {
            b2Body *body = [spr b2Body];
            world->DestroyBody(body);
            [node removeFromParentAndCleanup:YES];
        }]]];
        
        [self.fishes removeObjectAtIndex:0];
    }
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    [self addNewSpriteAtPosition:ccp(s.width/2, s.height)];
}

- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
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
    int forcee = 10;
    int forcey = -2;
    
    if ( IS_IPAD )
    {
        forcee *=8;
        forcey *=8;
        csize *=2;
        rsize *=2;
    }
    
    b2CircleShape circleBox;
    circleBox.m_radius = rsize/PTM_RATIO;
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &circleBox;
    fixtureDef.density = 1.0f;
	fixtureDef.friction = 0.08f;
    fixtureDef.restitution = 0.8f;
	body->CreateFixture(&fixtureDef);
    
	
    
    //	CCNode *parent = [self getChildByTag:kTagParentNode];
	
	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	//just randomly picking one of the images
	int idx = ([self randomValueBetween:0.0f andValue:1.0f] > 0.5 ? 0:1);
	int idy = ([self randomValueBetween:0.0f andValue:1.0f] > 0.5 ? 0:1);
    
    CCPhysicsSprite *sprite = nil;
    
    if ([self randomValueBetween:0.0f andValue:1.0f] > 0.5)
    {
        sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture rect:CGRectMake(csize * idx,csize * idy,csize,csize)];
        [spriteBatchNode addChild:sprite];
    }
    else
    {
        sprite = [CCPhysicsSprite spriteWithTexture:oldTexture rect:CGRectMake(csize * idx,csize * idy,csize,csize)];
        [oldBatchNode addChild:sprite];
    }
    
    [self.fishes addObject:sprite];
    
    int multiplier = CCRANDOM_0_1() > 0.5 ? -1 : 1;
	
	[sprite setPTMRatio:PTM_RATIO];
	[sprite setB2Body:body];
	[sprite setPosition: ccp( p.x - 150*multiplier, p.y)];
    
    body->SetUserData(sprite);
    
    b2Vec2 force = b2Vec2(forcee*multiplier , forcey);
    body->SetFixedRotation(false);
    body->ApplyLinearImpulse(force, body->GetPosition());
    body->ApplyTorque(CCRANDOM_0_1() > .5 ? 2 : -2);
}

-(void)slideOffMenuWithScene:(id)scene
{
    
    CGFloat actionDuration = 1.0f;
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    /*CCFiniteTimeAction *gameLogoAction = [CCMoveBy actionWithDuration:actionDuration position:ccp(-s.width, 0)];
    CCFiniteTimeAction *newGameAction = [CCMoveBy actionWithDuration:actionDuration position:ccp(s.width,0)];
    CCFiniteTimeAction *howToAction = [CCMoveBy actionWithDuration:actionDuration position:ccp(-s.width,0)];
    CCFiniteTimeAction *toggleAction = [CCFadeOut actionWithDuration:actionDuration];
    CCFiniteTimeAction *topPipesAction = [CCMoveBy actionWithDuration:actionDuration position:ccp(0,_topPipes.contentSize.height)];
    CCFiniteTimeAction *bottomPipesAction = [CCMoveBy actionWithDuration:actionDuration position:ccp(0, -_bottomPipes.contentSize.height)];
    CCFiniteTimeAction *bottomHerbsAction = [CCMoveBy actionWithDuration:actionDuration position:ccp(0, -_bottomHerbs.contentSize.height)];
    
    CCFiniteTimeAction *aboutAction = [CCSequence actionOne:[CCMoveBy actionWithDuration:actionDuration position:ccp(s.width,0)] two:[CCCallBlock actionWithBlock:^{
        [[CCDirector sharedDirector] replaceScene:scene];
    }]];
    
    [self runAction:[CCSpawn actions:gameLogoAction, newGameAction, howToAction, toggleAction, topPipesAction, bottomPipesAction, bottomHerbsAction, aboutAction, nil]];*/
    
    [_gameLogo runAction:[CCMoveBy actionWithDuration:actionDuration position:ccp(-s.width, 0)]];
    
    [_startNewGame runAction:[CCMoveBy actionWithDuration:actionDuration position:ccp(s.width,0)]];
    
    [_howTo runAction:[CCMoveBy actionWithDuration:actionDuration position:ccp(-s.width,0)]];
    
    [_toggleItem runAction:[CCFadeOut actionWithDuration:actionDuration]];
    
    [_topPipes runAction:[CCMoveBy actionWithDuration:actionDuration position:ccp(0,_topPipes.contentSize.height)]];
    [_bottomPipes runAction:[CCMoveBy actionWithDuration:actionDuration position:ccp(0, -_bottomPipes.contentSize.height)]];
    [_bottomHerbs runAction:[CCMoveBy actionWithDuration:actionDuration position:ccp(0, -_bottomHerbs.contentSize.height)]];
    
    [_about runAction:[CCSequence actionOne:[CCMoveBy actionWithDuration:actionDuration position:ccp(s.width,0)] two:[CCCallBlock actionWithBlock:^{
        [[CCDirector sharedDirector] replaceScene:scene];
    }]]];

}

-(void) createMenu
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    // define the button
    CCMenuItem *on;
    CCMenuItem *off;
    
    on = [CCMenuItemImage itemWithNormalImage:@"sound_on.png"
                                selectedImage:@"sound_on.png" target:nil selector:nil];
    on.tag = 1;
    
    
    off = [CCMenuItemImage itemWithNormalImage:@"sound_off.png"
                                 selectedImage:@"sound_off.png" target:nil selector:nil];
    off.tag = 0;
    
    self.toggleItem = [CCMenuItemToggle itemWithTarget:self
                                              selector:@selector(soundButtonTapped:) items:on, off, nil];
    CCMenu *toggleMenu = [CCMenu menuWithItems:self.toggleItem, nil];
    
    
    CGFloat xOffset = 35;
    CGFloat yOffset = 50;
    CGFloat menuPositionDivider = 2.3f;
    
    //CGFloat tubesOffset = 20.0f;
    
    int ar_iphone[4][4] = {{10, 132, 82, 132}, {100, 65, 42, 65}, {155, 83, 60, 83}, {227, 117, 82, 117}};
    int ar_ipad[4][4] = {{42, 268, 172, 268}, {254, 134, 94, 134}, {390, 168, 126, 168}, {554, 238, 172, 238}};
    
    int (*ar)[4] = ar_iphone;
    
    if ( IS_IPAD )
    {
        xOffset *= 2;
        yOffset *= 2;
        
        if (IS_RETINA)
            xOffset *=1.5f;
        
        menuPositionDivider = 3.0f;
        
        /*for (int i=0; i<4; ++i) {
            for (int j=0; j<4; ++j) {
                ar[i][j] *= 2;
            }
        }*/
        ar = ar_ipad;
    }
    
    else if (IS_IPHONE_6)
    {
        for (int i=0; i<4; ++i) {
            for (int j=0; j<4; ++j) {
                //if (i==0 && j==0)
                    //continue;
                ar[i][j]*=1.18f;
            }
        }
    }
    
    else if (IS_IPHONE_6P)
    {
        xOffset *= 1.7f;
        menuPositionDivider = 2.6f;
        for (int i=0; i<4; ++i) {
            for (int j=0; j<4; ++j) {
                //if (i==0 && j==0)
                   // continue;
                ar[i][j]*=1.30f;
            }
        }
    }
    
    toggleMenu.position = ccp(size.width - xOffset, size.height - yOffset);
    [self addChild:toggleMenu z:4];
    
    CCSprite *bg = [CCSprite spriteWithFile:@"main_bg.png"];
    [self addChild:bg z:-2];
    //bg.opacity = 180;
    bg.position = ccp(size.width/2, size.height/2);

    
    
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:32];
    
    self.howTo = [CCMenuItemImage itemWithNormalImage:NSLocalizedString(@"how_to_play_image", nil) selectedImage:NSLocalizedString(@"how_to_play_image", nil) block:^(id sender) {
        
        [self removeAllFish];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[CBAudioEngine sharedEngine] fadeBackgroundMusicFrom:1.0f to:0.0f duration:0.7f];
        });
        
        self.mainGameScene.isHelpScene = YES;
        [self slideOffMenuWithScene:self.mainGameScene];

    }];
    
    
    self.about = [CCMenuItemImage itemWithNormalImage:NSLocalizedString(@"about_image", nil) selectedImage:NSLocalizedString(@"about_image", nil) block:^(id sender) {
        
        NSString *iTunesLink = @"itms://itunes.apple.com/us/artist/roman-filippov/id568945240";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        

        
    }];
    
    self.startNewGame = [CCMenuItemImage itemWithNormalImage:NSLocalizedString(@"new_game_image", nil) selectedImage:NSLocalizedString(@"new_game_image", nil) block:^(id sender) {
        
        [self removeAllFish];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[CBAudioEngine sharedEngine] fadeBackgroundMusicFrom:1.0f to:0.0f duration:0.7f];
        });
        
        self.mainGameScene.isHelpScene = NO;
        [self slideOffMenuWithScene:self.mainGameScene];
    }];
    
	menu = [[CCMenu menuWithItems:_startNewGame, _howTo, _about, nil] retain];
    
    [menu alignItemsVertically];
	[menu setPosition:ccp( size.width/2, size.height/menuPositionDivider)];
    menu.opacity = 0;
    

	[self addChild: menu z:2];
    
    [self createBucketForRect:CGRectMake(ar[0][0], ar[0][1], ar[0][2], ar[0][3])];
    [self createBucketForRect:CGRectMake(ar[1][0], ar[1][1], ar[1][2], ar[1][3])];
    [self createBucketForRect:CGRectMake(ar[2][0], ar[2][1], ar[2][2], ar[2][3])];
    [self createBucketForRect:CGRectMake(ar[3][0], ar[3][1], ar[3][2], ar[3][3])];
}

-(void)removeAllFish
{
    for (CCPhysicsSprite *spr in self.fishes) {
        
        [spr runAction:[CCSequence actionOne:[CCFadeOut actionWithDuration:0.5f] two:[CCCallBlockN actionWithBlock:^(CCNode *node) {
            b2Body *body = [spr b2Body];
            world->DestroyBody(body);
            [node removeFromParentAndCleanup:YES];
        }]]];
    };
}

-(void)soundButtonTapped:(CCMenuItemToggle*)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        if ([sender selectedItem].tag == 0)
        {
            [[CBAudioEngine sharedEngine] pauseBackgroundMusic];
            [userDefaults setObject:@"NO" forKey:BG_MUSIC_KEY];
            self.wasPlayed = YES;
        }
        else {
            
            if (self.wasPlayed)
                [[CBAudioEngine sharedEngine] resumeBackgroundMusic];
            else
                [[CBAudioEngine sharedEngine] playBackgroundMusic:@"hip_hop_bg.mp3"];
            
            [userDefaults setObject:@"YES" forKey:BG_MUSIC_KEY];
        }
        [userDefaults synchronize];

    });
}

-(void)createBucketForRect:(CGRect) pos
{
    // Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
    groundBodyDef.type = b2_staticBody;
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
    b2EdgeShape pShape;
    
    
	
    pShape.Set(b2Vec2(pos.origin.x/PTM_RATIO, pos.origin.y/PTM_RATIO), b2Vec2((pos.origin.x)/PTM_RATIO, (pos.origin.y-pos.size.height)/PTM_RATIO));
    groundBody->CreateFixture(&pShape, 0);
    pShape.Set(b2Vec2(pos.origin.x/PTM_RATIO, (pos.origin.y-pos.size.height)/PTM_RATIO), b2Vec2((pos.origin.x+pos.size.width)/PTM_RATIO, (pos.origin.y-pos.size.height)/PTM_RATIO));
    groundBody->CreateFixture(&pShape, 0);
    pShape.Set(b2Vec2((pos.origin.x+pos.size.width)/PTM_RATIO, (pos.origin.y-pos.size.height)/PTM_RATIO), b2Vec2((pos.origin.x+pos.size.width)/PTM_RATIO, (pos.origin.y)/PTM_RATIO));
    groundBody->CreateFixture(&pShape, 0);
    pShape.Set(b2Vec2((pos.origin.x+pos.size.width)/PTM_RATIO, pos.origin.y/PTM_RATIO), b2Vec2(pos.origin.x/PTM_RATIO, pos.origin.y/PTM_RATIO));
    groundBody->CreateFixture(&pShape, 0);
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [touch locationInView: [touch view]];
    location = [[CCDirector sharedDirector] convertToGL: location];
    
    for (CCPhysicsSprite *spr in self.fishes) {
        if (ccpDistance(spr.position, location) <= spr.contentSize.width*2)
        {
            CGPoint force = ccpSub(spr.position, location);
            b2Body *body = [spr b2Body];
            body->ApplyForceToCenter(b2Vec2(force.x*40, force.y*40));
        }
    }
}

-(void) initPhysics
{
	
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
//	GLESDebugDraw *m_debugDraw = new GLESDebugDraw( PTM_RATIO );
//     world->SetDebugDraw(m_debugDraw);
//     
//     uint32 flags = 0;
//     flags += b2Draw::e_shapeBit;
//     		flags += b2Draw::e_jointBit;
//     		flags += b2Draw::e_aabbBit;
//     		flags += b2Draw::e_pairBit;
//     		flags += b2Draw::e_centerOfMassBit;
//     m_debugDraw->SetFlags(flags);
	
	
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
    
//    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
//     
//     kmGLPushMatrix();
//     
//     world->DrawDebugData();
//     
//     kmGLPopMatrix();
}


@end
