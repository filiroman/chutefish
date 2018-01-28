//
//  HelloWorldLayer.mm
//  chute balls
//
//  Created by Roman Filippov on 14.02.14.
//  Copyright Roman Filippov 2014. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "B2BodyWrapper.h"

#define BUCKET_HEIGHT 100

typedef enum {
    bodyColor1 = 0,
    bodyColor2 = 1,
    bodyColor3 = 2,
    bodyColor4 = 3
} bodyColor;


enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()
{
    NSMutableArray *_points;
    NSUInteger _pointCount;
    NSMutableArray *_wallSprites;
    NSMutableArray *_bodies;
    
    NSMutableArray *_bucketRects;
    
    int health;
    int score;
}

@property (retain, nonatomic) CCRenderTexture *target;
@property (retain, nonatomic) CCSprite *brush;
@property (retain, nonatomic) CCSprite *clearBrush;
@property (retain, nonatomic) CCLabelTTF *healthLabel;
@property (retain, nonatomic) CCLabelTTF *scoreLabel;
@property (retain, nonatomic) CCLabelTTF *gameOverLabel;

@property (retain, nonatomic) CCSpriteBatchNode *balls;
@property (retain, nonatomic) CCSpriteBatchNode *bucketBN;
@property (retain, nonatomic) CCSpriteBatchNode *topBucketBN;

-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
-(void) createMenu;
@end

@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super initWithColor:ccc4(225, 225, 225, 255)])) {
		
		// enable events
		
		self.touchEnabled = YES;
		self.accelerometerEnabled = NO;
		CGSize s = [CCDirector sharedDirector].winSize;
		
		// init physics
		[self initPhysics];
		
        [self createBuckets];
		
		//Set up sprite
		
#if 1
		// Use batch node. Faster
		self.balls = [CCSpriteBatchNode batchNodeWithFile:@"fishes.png" capacity:4];
		spriteTexture_ = [self.balls texture];
        self.bucketBN = [CCSpriteBatchNode batchNodeWithFile:@"buckets.png" capacity:4];
        bucketsTexture = [self.bucketBN texture];
        self.topBucketBN = [CCSpriteBatchNode batchNodeWithFile:@"buckets_top.png" capacity:4];
        bucketsTopTexture = [self.topBucketBN texture];
#else
		// doesn't use batch node. Slower
		spriteTexture_ = [[CCTextureCache sharedTextureCache] addImage:@"colors.png"];
		CCNode *parent = [CCNode node];
#endif
		//[self addChild:parent z:0 tag:kTagParentNode];
        [self addChild:self.topBucketBN z:1];
        [self addChild:self.balls z:2];
        [self addChild:self.bucketBN z:3];
        
        
        health = 10;
        score = 0;
		
		self.healthLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Health: %d", health] fontName:@"Marker Felt" fontSize:22];
		[self addChild:self.healthLabel z:0];
		[self.healthLabel setColor:ccc3(0,0,0)];
		self.healthLabel.position = ccp( s.width - 50, s.height-30);
        
        self.scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Score: %d", score] fontName:@"Marker Felt" fontSize:22];
		[self addChild:self.scoreLabel z:0];
		[self.scoreLabel setColor:ccc3(0,0,0)];
		self.scoreLabel.position = ccp( 50, s.height-30);
        
        self.gameOverLabel = [CCLabelTTF labelWithString:@"Game Over!" fontName:@"Marker Felt" fontSize:32];
        self.gameOverLabel.opacity = 0;
        [self addChild:self.gameOverLabel z:0];
        [self.gameOverLabel setColor:ccc3(0,0,0)];
        self.gameOverLabel.position = ccp( s.width/2, s.height/2);
        
        _points = [[NSMutableArray alloc] init];
        _wallSprites = [[NSMutableArray alloc] init];
        _bodies = [[NSMutableArray alloc] init];
        
        _target = [[CCRenderTexture renderTextureWithWidth:s.width height:s.height pixelFormat:kCCTexture2DPixelFormat_RGBA8888] retain];
        _target.position = ccp(s.width/2, s.height/2);
        
        [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
        
        [self addChild:_target];
        
        _brush = [[CCSprite spriteWithFile:@"largeBrush.png"] retain];
        _clearBrush = [[CCSprite spriteWithFile:@"largeClearBrush.png"] retain];
        [_clearBrush setBlendFunc:(ccBlendFunc) { GL_ZERO,GL_ONE_MINUS_SRC_ALPHA }];
        [_clearBrush setOpacity:100];
        
        
        [self addBucketRects];
        
		
		[self scheduleUpdate];
        [self schedule:@selector(addBall:) interval:4.0];
        [self schedule:@selector(gameLogic:)];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
    
    self.target = nil;
    self.brush = nil;
    self.clearBrush = nil;
    self.healthLabel = nil;
    
    [_bodies release];
    [_points release];
    [_wallSprites release];
    [_bucketRects release];
	
	[super dealloc];
}

-(void) addBall: (ccTime) dt
{
    CGSize s = [CCDirector sharedDirector].winSize;
    
    [self addNewSpriteAtPosition:ccp(s.width/2, s.height)];
}

-(void) restartGame
{
    [self schedule:@selector(addBall:) interval:4.0f];
    
    [self.gameOverLabel runAction:[CCFadeOut actionWithDuration:1.0f]];
    
    health = 10;
    score = 0;
    
    [self.healthLabel setString:[NSString stringWithFormat:@"Health: %d", health]];
    [self.scoreLabel setString:[NSString stringWithFormat:@"Score: %d", score]];
}

-(void) performGameOver
{
    [self unschedule:@selector(addBall:)];
    [self.gameOverLabel runAction:[CCFadeIn actionWithDuration:1.0f]];
    
    for (b2Body *b = world->GetBodyList(); b; b = b->GetNext()) {
        if (b->GetUserData() != NULL) {
            
            CCPhysicsSprite *ball = (CCPhysicsSprite*)b->GetUserData();
            
            world->DestroyBody(b);
            [ball removeFromParentAndCleanup:YES];
        }
    }
    
    [self performSelector:@selector(restartGame) withObject:nil afterDelay:4.0f];
}

-(void) addBucketRects
{
    _bucketRects = [[NSMutableArray alloc] init];
    
    CGSize s = [CCDirector sharedDirector].winSize;
    
    CGFloat bucketWidth = s.width / 4.0f;
    
    for (int i=0; i<4; ++i) {
        
        CGFloat leftPos = i*bucketWidth;
        
        CGRect rect = CGRectMake(leftPos-16, -16, bucketWidth+32, BUCKET_HEIGHT);
        
        int idx = (i == 1) || (i == 3);
        int idy = (i == 2) || (i == 3);
        
        CCSprite *bucket = [CCSprite spriteWithTexture:bucketsTexture rect:CGRectMake(80 * idx, 87 * idy,80 ,86)];
        [self.bucketBN addChild:bucket z:3];
        bucket.anchorPoint = ccp(0,0);
        bucket.position = ccp(leftPos,0);
        
        CCSprite *bucket_top = [CCSprite spriteWithTexture:bucketsTopTexture rect:CGRectMake(80 * idx, 17 * idy,80 ,17)];

        [self.topBucketBN addChild:bucket_top z:1];
        bucket_top.anchorPoint = ccp(0,0);
        bucket_top.position = ccp(leftPos, bucket.boundingBox.size.height-7);
        
        [_bucketRects addObject:[NSValue valueWithCGRect:rect]];
    }
}

-(void) gameLogic: (ccTime) dt
{
    for (int i=0; i<[_bucketRects count]; ++i) {
        
        CGRect bucket = [[_bucketRects objectAtIndex:i] CGRectValue];
        
        for (b2Body *b = world->GetBodyList(); b; b = b->GetNext()) {
            if (b->GetUserData() != NULL) {
                CCPhysicsSprite *ball = (CCPhysicsSprite*)b->GetUserData();
                
                if (CGRectContainsRect(bucket, ball.boundingBox))
                {
                    
                    if (ball.tag != i) {
                        
                        [self.healthLabel setString:[NSString stringWithFormat:@"Health: %d", --health]];
                        
                        if (health == 0)
                        {
                            [self performGameOver];
                            return;
                        }
                        
                    } else {
                        
                        [self.scoreLabel setString:[NSString stringWithFormat:@"Score: %d", ++score]];
                    }
                    
                    world->DestroyBody(b);
                    [ball removeFromParentAndCleanup:YES];
                }
                
                //NSLog(@"Ball detected!");
            }
        }
    }
}

-(void) createBuckets
{
    CGSize s = [CCDirector sharedDirector].winSize;
    
    CGFloat bucketWidth = s.width / 4.0f;
    
    for (int i=0; i<4; ++i) {
        
        CGFloat leftPos = i*bucketWidth;
        CGFloat rightPos = leftPos + bucketWidth;
        
        b2BodyDef corner1Def;
        corner1Def.type = b2_staticBody;
        corner1Def.position.Set(leftPos/PTM_RATIO, 0);
        b2Body* corner1 = world->CreateBody(&corner1Def);
        b2EdgeShape corner1Shape;
        
        corner1Shape.Set(b2Vec2(leftPos/PTM_RATIO, 0), b2Vec2(rightPos/PTM_RATIO, 0));
        corner1->CreateFixture(&corner1Shape,0);
        
        corner1Shape.Set(b2Vec2(leftPos/PTM_RATIO, (BUCKET_HEIGHT-13.0f)/PTM_RATIO), b2Vec2(leftPos/PTM_RATIO, 0));
        corner1->CreateFixture(&corner1Shape,0);
        
        corner1Shape.Set(b2Vec2(rightPos/PTM_RATIO, (BUCKET_HEIGHT-13.0f)/PTM_RATIO), b2Vec2(rightPos/PTM_RATIO, 0));
        corner1->CreateFixture(&corner1Shape,0);

    }
	
}

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
	// Reset Button
	CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
	}];

	// to avoid a retain-cycle with the menuitem and blocks
	__block id copy_self = self;

	// Achievement Menu Item using blocks
	CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id sender) {
		
		
		GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
		achivementViewController.achievementDelegate = copy_self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:achivementViewController animated:YES];
		
		[achivementViewController release];
	}];
	
	// Leaderboard Menu Item using blocks
	CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
		
		
		GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
		leaderboardViewController.leaderboardDelegate = copy_self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:leaderboardViewController animated:YES];
		
		[leaderboardViewController release];
	}];
	
	CCMenu *menu = [CCMenu menuWithItems:itemAchievement, itemLeaderboard, reset, nil];
	
	[menu alignItemsVertically];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	[menu setPosition:ccp( size.width/2, size.height/2)];
	
	
	[self addChild: menu z:-1];	
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
	
	/*m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);*/
	
	
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
}

-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	/*ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	world->DrawDebugData();	
	
	kmGLPopMatrix();*/
}

-(void) addNewSpriteAtPosition:(CGPoint)p
{
	CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	// Define the dynamic body.
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	//b2PolygonShape dynamicBox;
	//dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
    
    b2CircleShape circleBox;
    circleBox.m_radius = 16.0f/PTM_RATIO;
	
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
    
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(32 * idx,32 * idy,32,32)];
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
	
	[sprite setPTMRatio:PTM_RATIO];
	[sprite setB2Body:body];
	[sprite setPosition: ccp( p.x, p.y)];
    
    body->SetUserData(sprite);
    
    b2Vec2 force = b2Vec2(5 , -2);
    body->ApplyLinearImpulse(force, body->GetPosition());

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

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _pointCount = 1;
    
    UITouch *touch = [touches anyObject];
    
    CGPoint location = [touch locationInView: [touch view]];
    
    location = [[CCDirector sharedDirector] convertToGL: location];
    
    [_points addObject:[NSValue valueWithCGPoint:location]];
    
    //NSLog(@"Line started at: %f, %f", location.x, location.y);
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _pointCount++;
    
    UITouch *touch = [touches anyObject];
    
    CGPoint location = [touch locationInView: [touch view]];
    
    location = [[CCDirector sharedDirector] convertToGL: location];
    
    CGPoint end = [touch previousLocationInView:[touch view]];
    end = [[CCDirector sharedDirector] convertToGL:end];
    
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
    
    if (_pointCount == POINT_COUNT)
    {
        NSArray *wallPoints = [NSArray arrayWithArray:_points];
        
        [self createStaticWall];
        
        [self performSelector:@selector(removeWalls:) withObject:wallPoints afterDelay:4.0f];
        
        _pointCount = 0;
        NSValue *lastValue = [[_points objectAtIndex:[_points count]-1] retain];
        [_points removeAllObjects];
        [_points addObject:lastValue];
        [lastValue release];
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
    
    int pointCount = [wallPoints count] == 2 ? 3 : 1;
    
    for (int i=0; i<pointCount; ++i) {
        self.clearBrush.position = ccp(initPoint.x, initPoint.y);
        [self.clearBrush visit];
    }
    
    //[self.target end];
    
    for (int j=0; j<5; ++j) {
    
    for (int i=1; i<[wallPoints count]; ++i) {
        
        //[self.target begin];
        
        CGPoint prevPoint = [wallPoints[i-1] CGPointValue];
        CGPoint currPoint = [wallPoints[i] CGPointValue];
        
        NSLog(@"Dell prev point: %f/%f. Curr point: %f/%f", prevPoint.x, prevPoint.y, currPoint.x, currPoint.y);
        
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
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
    
    CGPoint location = [touch locationInView: [touch view]];
    
    location = [[CCDirector sharedDirector] convertToGL: location];
    
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
        [_points addObject:[NSValue valueWithCGPoint:location]];
    }
    
    
    NSArray *wallPoints = [NSArray arrayWithArray:_points];
    
    [self createStaticWall];
    
    [self performSelector:@selector(removeWalls:) withObject:wallPoints afterDelay:4.0f];
    
    [_points removeAllObjects];
}

@end
