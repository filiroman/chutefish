//
//  CBAboutPopup.h
//  chute balls
//
//  Created by Roman Filippov on 27.03.14.
//  Copyright 2014 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@protocol CBAboutPopupDelegate;

@interface CBAboutPopup : CCSprite {
    
}

@property (assign) id<CBAboutPopupDelegate> delegate;

+ (CBAboutPopup*) popup;

@end


@protocol CBAboutPopupDelegate <NSObject>

- (void)backButtonPressed;

@end
