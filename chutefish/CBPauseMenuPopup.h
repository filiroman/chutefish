//
//  CBPauseMenuPopup.h
//  chute balls
//
//  Created by Roman Filippov on 03.05.14.
//  Copyright 2014 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum {
    CBSoundButtonStateOn,
    CBSoundButtonStateOff
} CBSoundButtonState;

@protocol CBPauseMenuPopupDelegate;

@interface CBPauseMenuPopup : CCSprite 

@property (assign) id<CBPauseMenuPopupDelegate> delegate;
@property (nonatomic, assign) BOOL isHelpScene;

+ (CBPauseMenuPopup*) popup;


@end

@protocol CBPauseMenuPopupDelegate <NSObject>

- (void)resumeButtonPressed:(CBPauseMenuPopup*)popup;
- (void)backToMenuButtonPressed:(CBPauseMenuPopup*)popup;
- (void)restartButtonPressed:(CBPauseMenuPopup*)popup;
- (void)soundButtonPressedWithState:(CBSoundButtonState)btnState fromPopup:(CBPauseMenuPopup*)popup;

@end


