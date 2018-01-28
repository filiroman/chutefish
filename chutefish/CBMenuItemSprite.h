//
//  CBMenuItemSprite.h
//  chute balls
//
//  Created by Roman Filippov on 26.02.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CCMenuItem.h"

@interface CBMenuItemSprite : CCMenuItemImage

@property (nonatomic, retain) CCSprite *top;

+(id) itemWithString: (NSString*) value image: (NSString*) image leftCapWidth:(CGFloat) width block:(void(^)(id sender))block;

@end
