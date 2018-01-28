//
//  CBAudioEngine.h
//  chute balls
//
//  Created by Roman Filippov on 27.03.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "SimpleAudioEngine.h"
#import "cocos2d.h"

#define BG_MUSIC_KEY @"bg-playing"

@interface CBAudioEngine : SimpleAudioEngine

- (void)fadeBackgroundMusicFrom:(Float32)startVolume to:(Float32)endVolume duration:(ccTime)duration;

+ (CBAudioEngine*) sharedEngine;

@end
