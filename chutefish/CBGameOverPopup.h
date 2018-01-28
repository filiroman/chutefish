//
//  CBGameOverPopup.h
//  chute balls
//
//  Created by Roman Filippov on 01.03.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CCSprite.h"

@protocol CBGameOverPopupDelegate;

@interface CBGameOverPopup : CCSprite

@property (assign) id<CBGameOverPopupDelegate> delegate;

+ (CBGameOverPopup*) popup;

- (void)setPopupScore:(int)score;
- (void)setPopupBestScore:(int)bestScore;

@end

@protocol CBGameOverPopupDelegate <NSObject>

- (void)restartButtonPressedOnGameOver:(CBGameOverPopup*)popup;
- (void)backToMenuButtonPressedOnGameOver:(CBGameOverPopup*)popup;

@end
