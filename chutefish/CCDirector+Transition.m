//
//  CCDirector+PopTransition.m
//  chute balls
//
//  Created by Roman Filippov on 15.10.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CCDirector+Transition.h"

@implementation CCDirector (Transition)

- (void) popSceneWithTransition:(Class)transitionClass duration:(ccTime)t {
    [_scenesStack removeLastObject];
    
    NSUInteger count = [_scenesStack count];
    NSAssert(count > 0, @"Don't popScene when there aren't any!");
    
    CCScene* scene = [transitionClass transitionWithDuration:t scene:[_scenesStack lastObject]];
    [self replaceScene:scene];
}

@end
