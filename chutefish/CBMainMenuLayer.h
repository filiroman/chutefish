//
//  CBMainMenuLayer.h
//  chute balls
//
//  Created by Roman Filippov on 26.02.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CCLayer.h"
#import "Box2D.h"

@class CCScene;

@interface CBMainMenuLayer : CCLayer {
    b2World* world;					// strong ref
}

+(CCScene *) scene;

@end
