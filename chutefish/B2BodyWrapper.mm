//
//  B2BodyWrapper.m
//  chute balls
//
//  Created by Roman Filippov on 16.02.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "B2BodyWrapper.h"

@implementation B2BodyWrapper

+ (B2BodyWrapper*)b2BodyWithObject:(b2Body*) body
{
    B2BodyWrapper *wrapper = [[B2BodyWrapper alloc] init];
    wrapper.body = body;
    return [wrapper autorelease];
}

@end
