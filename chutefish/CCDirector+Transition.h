//
//  CCDirector+PopTransition.h
//  chute balls
//
//  Created by Roman Filippov on 15.10.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CCDirector.h"

@interface CCDirector (Transition)

- (void) popSceneWithTransition:(Class)transitionClass duration:(ccTime)t;

@end
