//
//  CBPauseMenuPopup.m
//  chute balls
//
//  Created by Roman Filippov on 03.05.14.
//  Copyright 2014 Roman Filippov. All rights reserved.
//

#import "CBPauseMenuPopup.h"
#import "CCSpriteScale9.h"
#import "cocos2d.h"
#import "CBAudioEngine.h"

@interface CBPauseMenuPopup ()

@property (retain, nonatomic) CCMenuItemToggle *toggleItem;
@property (retain, nonatomic) CCMenu *resetMenu;

@end

@implementation CBPauseMenuPopup

- (id) init
{
    if (self = [super initWithFile:@"menu_box.png"])
    {
        _isHelpScene = NO;
        
        CGFloat fontSize = 26.0f;
        CGFloat generalFontSize = 22.0f;
        CGFloat leftCapWidth = 11.0f;
        CGFloat resetButtonOffset = 60.0f;
        
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        {
            fontSize *= 2;
            leftCapWidth *= 2;
            generalFontSize *= 2;
            resetButtonOffset *= 2;
        }
        
        CCMenuItemImage *playButton = [CCMenuItemImage itemWithNormalImage:@"play_button.png" selectedImage:@"play_button.png" target:self selector:@selector(playButtonPressed:)];
        CCMenu *playMenu = [CCMenu menuWithItems:playButton, nil];
        
        CCMenuItemImage* resetBtn = [CCMenuItemImage itemWithNormalImage:@"reset_button.png" selectedImage:@"reset_button.png" target:self selector:@selector(resetButtonPressed:)];
        self.resetMenu = [CCMenu menuWithItems:resetBtn, nil];
        
        CCMenuItemImage* menuBtn = [CCMenuItemImage itemWithNormalImage:@"back_to_menu_button.png" selectedImage:@"back_to_menu_button.png" target:self selector:@selector(menuButtonPressed:)];
        CCMenu* menuMenu = [CCMenu menuWithItems:menuBtn, nil];
        
        // define the button
        CCMenuItem *on;
        CCMenuItem *off;
        
        on = [CCMenuItemImage itemWithNormalImage:@"menu_sound_on.png"
                                    selectedImage:@"menu_sound_on.png" target:nil selector:nil];
        on.tag = 1;
        
        
        off = [CCMenuItemImage itemWithNormalImage:@"menu_sound_off.png"
                                     selectedImage:@"menu_sound_off.png" target:nil selector:nil];
        off.tag = 0;
        
        self.toggleItem = [CCMenuItemToggle itemWithTarget:self
                                                 selector:@selector(soundButtonPressed:) items:on, off, nil];
        CCMenu *toggleMenu = [CCMenu menuWithItems:_toggleItem, nil];
        
        /*CGFloat xOffset = 25;
         CGFloat yOffset = 80;
         
         if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
         {
         xOffset *= 2;
         yOffset *= 2;
         }
         
         toggleMenu.position = ccp(s.width, s.height - yOffset);*/
        //[spr addChild:toggleMenu z:5];
        
        
        
        
        /*CCSpriteScale9 *gameOverSpr = [CCSpriteScale9 spriteWithFile:@"menu_box.png" andLeftCapWidth:leftCapWidth andTopCapHeight:0];
        [gameOverSpr adaptiveScale9:CGSizeMake((playButton.boundingBox.size.width + resetBtn.boundingBox.size.width + off.boundingBox.size.width)*1.6f , off.boundingBox.size.height * 1.875f)];
        
        CCSprite *topPart = [CCSprite spriteWithFile:@"menu_box_top.png"];
        
        spr.contentSize = gameOverSpr.contentSize;
        gameOverSpr.position = CGPointMake(spr.contentSize.width * 0.5f + topPart.contentSize.width*0.5f,
                                           spr.contentSize.height * 0.5f);*/
        
        //gameOverposition = gameOverLabel.position;
        
        //topPart.position = ccp(gameOverposition.x - gameOvercontentSize.width/2 - 1, gameOverposition.y);
        //topPart.contentSize = CGSizeMake(topPart.contentSize.width, gameOvercontentSize.height+20);
        //    topPart.scaleY = 1.8f;
        //    topPart.scaleX = 0.9f;
        
        
        [self addChild:_resetMenu];
        [self addChild:playMenu];
        [self addChild:menuMenu];
        [self addChild:toggleMenu];
        
        CGSize s = self.contentSize;
        
        _resetMenu.position = ccp(s.width*0.3f, s.height*0.3f);
        playMenu.position = ccp(s.width*0.7f, s.height*0.7f);
        menuMenu.position = ccp(s.width*0.7f, s.height*0.3f);
        toggleMenu.position = ccp(s.width*0.3f, s.height*0.7f);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *play = [userDefaults objectForKey:BG_MUSIC_KEY];
        if (play != nil)
        {
            if ([play isEqualToString:@"YES"]) {
                [self.toggleItem setSelectedIndex:0];
            }
            else
            {
                [self.toggleItem setSelectedIndex:1];
            }
            
        }

    }
    
    return self;
}

- (void)dealloc
{
    self.resetMenu = nil;
    self.toggleItem = nil;
    
    [super dealloc];
}

- (void)setIsHelpScene:(BOOL)isHelpScene
{
    if (_isHelpScene == isHelpScene)
        return;
    
    self.resetMenu.visible = !isHelpScene;
    
    _isHelpScene = isHelpScene;
}

+ (CBPauseMenuPopup*) popup {
    
    return [[[CBPauseMenuPopup alloc] init] autorelease];
}

- (void)menuButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(backToMenuButtonPressed:)])
    {
        [self.delegate backToMenuButtonPressed:self];
    }
}

- (void)playButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(resumeButtonPressed:)])
    {
        [self.delegate resumeButtonPressed:self];
    }
}

- (void)soundButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(soundButtonPressedWithState:fromPopup:)])
    {
        CBSoundButtonState bstate;
        if ([sender selectedItem].tag == 0)
            bstate = CBSoundButtonStateOff;
        else
            bstate = CBSoundButtonStateOn;
        [self.delegate soundButtonPressedWithState:bstate fromPopup:self];
    }
}

- (void)resetButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(restartButtonPressed:)])
        [self.delegate restartButtonPressed:self];
}


@end
