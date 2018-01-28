//
//  B2BodyWrapper.h
//  chute balls
//
//  Created by Roman Filippov on 16.02.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

@interface B2BodyWrapper : NSObject

@property (nonatomic, assign) b2Body *body;

+ (B2BodyWrapper*)b2BodyWithObject:(b2Body*) body;

@end
