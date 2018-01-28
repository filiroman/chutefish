//
//  CBGameOverPopup.m
//  chute balls
//
//  Created by Roman Filippov on 01.03.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CBGameOverPopup.h"
#import "cocos2d.h"
#import "CCSpriteScale9.h"

@interface CBGameOverPopup ()

@property (retain, nonatomic) CCLabelTTF *score;


@end

@implementation CBGameOverPopup

- (id)init
{
    if (self = [super initWithFile:@"game_over_bg.png"])
    {
        CGFloat generalFontSize = 18.0f;
        CGFloat menuOffset = 35.0f;
        
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            generalFontSize *= 2;
            menuOffset *= 2;
        }
        
        
        /*CCLabelTTF *gameOverLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"Game Over!", nil) fontName:@"Marker Felt" fontSize:fontSize];
        //self.gameOverLabel.opacity = 0;
        [gameOverLabel setColor:ccc3(255,255,255)];
        //gameOverLabel.position = ccp( s.width/2, s.height/2);
        gameOverLabel.anchorPoint = ccp(0.5f, -0.7f);*/
        
        CGSize s = self.contentSize;
        
        
        self.score = [CCLabelTTF labelWithString:[NSString stringWithFormat:NSLocalizedString(@"Your Score: %d", nil), 00] fontName:NSLocalizedString(@"stat_font", nil) fontSize:generalFontSize];
        
        CCMenuItemImage* resetBtn = [CCMenuItemImage itemWithNormalImage:@"reset_button.png" selectedImage:@"reset_button.png" target:self selector:@selector(resetPressed:)];
        CCMenuItemImage* menuBtn = [CCMenuItemImage itemWithNormalImage:@"back_to_menu_button.png" selectedImage:@"back_to_menu_button.png" target:self selector:@selector(menuPressed:)];
        CCMenu* menu = [CCMenu menuWithItems:resetBtn, menuBtn, nil];
        [menu alignItemsHorizontallyWithPadding:20.0f];
        
        [self addChild:_score];
        [self addChild:menu];
        
        _score.position = ccp(s.width/2, s.height/2 + _score.contentSize.height + menuOffset*0.5f);
        menu.position = ccp(s.width/2, resetBtn.contentSize.height/2 + menuOffset);

    }
    return self;
}

- (void)dealloc
{
    self.score = nil;
    
    [super dealloc];
}

+ (CBGameOverPopup*) popup {
    
    return [[[CBGameOverPopup alloc] init] autorelease];
}

- (void)resetPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(restartButtonPressedOnGameOver:)])
        [self.delegate restartButtonPressedOnGameOver:self];
}

- (void)menuPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(backToMenuButtonPressedOnGameOver:)])
        [self.delegate backToMenuButtonPressedOnGameOver:self];
}

- (void)setPopupScore:(int)score
{
    if (score < 0)
        return;
    
    [self.score setString:[NSString stringWithFormat:NSLocalizedString(@"Your Score: %d", nil), score]];
}

- (void)setPopupBestScore:(int)bestScore
{
    if (bestScore < 0)
        return;
    
    //[self.bestScore setString:[NSString stringWithFormat:NSLocalizedString(@"Best Score: %d", nil) , bestScore]];
}


@end
