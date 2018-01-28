//
//  CBAboutPopup.m
//  chute balls
//
//  Created by Roman Filippov on 27.03.14.
//  Copyright 2014 Roman Filippov. All rights reserved.
//

#import "CBAboutPopup.h"
#import "CCSpriteScale9.h"

@implementation CBAboutPopup

+ (CBAboutPopup*) popup {
    
    CBAboutPopup *spr = [[CBAboutPopup alloc] init];
    
    CCLabelTTF *aboutLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"about_text", nil) fontName:@"Marker Felt" fontSize:26];
    //self.gameOverLabel.opacity = 0;
    [aboutLabel setColor:ccc3(255,255,255)];
    //gameOverLabel.position = ccp( s.width/2, s.height/2);
    aboutLabel.anchorPoint = ccp(0.5f, -0.7f);
    
    CCSpriteScale9 *gameOverSpr = [CCSpriteScale9 spriteWithFile:@"menu_box.png" andLeftCapWidth:11.0f andTopCapHeight:0];
    [gameOverSpr adaptiveScale9:CGSizeMake(aboutLabel.contentSize.width + 80, aboutLabel.contentSize.height + 80)];
    //gameOverposition = gameOverLabel.position;
    spr.contentSize = gameOverSpr.contentSize;
    
    CCSprite *topPart = [CCSprite spriteWithFile:@"menu_box_top.png"];
    //topPart.position = ccp(gameOverposition.x - gameOvercontentSize.width/2 - 1, gameOverposition.y);
    //topPart.contentSize = CGSizeMake(topPart.contentSize.width, gameOvercontentSize.height+20);
    topPart.scaleY = 1.8f;
    topPart.scaleX = 0.9f;
    
    [spr addChild:gameOverSpr z:0];
    [spr addChild:aboutLabel z:1];
    [spr addChild:topPart];
    
    aboutLabel.position = CGPointMake(spr.contentSize.width * spr.anchorPoint.x,
                                         spr.contentSize.height * spr.anchorPoint.y);
    gameOverSpr.position = aboutLabel.position;
    topPart.position = ccp(gameOverSpr.position.x - gameOverSpr.contentSize.width/2 - 1, gameOverSpr.position.y);
    
    return [spr autorelease];
    
}

-(void)onEnter {
    [super onEnter];
    
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

-(void)onExit {
    [super onExit];
    
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    return YES;
}

-(void)ccTouchEnded:(UITouch*)touch withEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(backButtonPressed)])
        [self.delegate backButtonPressed];
}


@end
