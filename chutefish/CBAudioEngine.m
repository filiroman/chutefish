//
//  CBAudioEngine.m
//  chute balls
//
//  Created by Roman Filippov on 27.03.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CBAudioEngine.h"
static CBAudioEngine *sharedEngine = nil;

@interface CBAudioEngine ()
{
    CGFloat fadeTimeTaken;
    CGFloat fadeDuration;
    CGFloat fadeStartVolume;
    CGFloat fadeEndVolume;
}
@end

@implementation CBAudioEngine

+ (CBAudioEngine*) sharedEngine
{
    @synchronized(self)     {
		if (!sharedEngine)
			sharedEngine = [[CBAudioEngine alloc] init];
	}
	return sharedEngine;
}

- (void)fadeBackgroundMusicFrom:(Float32)startVolume to:(Float32)endVolume duration:(ccTime)duration {
    fadeTimeTaken = 0;
    fadeDuration = duration;
    fadeStartVolume = startVolume;
    fadeEndVolume = endVolume;
    
    [[CCScheduler sharedScheduler] scheduleUpdateForTarget:self priority:1 paused:NO];
}

- (void)update:(ccTime)delta {
    
    fadeTimeTaken += delta;
    
    CGFloat timeProportion = fadeTimeTaken / fadeDuration;
    if (timeProportion < 1.0) {
        CGFloat newMusicVolume = fadeStartVolume + (timeProportion * (fadeEndVolume - fadeStartVolume));
        [self setBackgroundMusicVolume:newMusicVolume];
    } else {
        [[CCScheduler sharedScheduler] unscheduleUpdateForTarget:self];
    }
}

@end
