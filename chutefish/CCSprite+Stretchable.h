//
//  CCSprite+Stretchable.h
//  chute balls
//
//  Created by Roman Filippov on 26.02.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CCSprite.h"

@interface CCSprite (Stretchable)

+ (CCSprite *)spriteFromStretchableFile:(NSString *)fileName leftCap:(NSInteger)leftCap width:(float)width;
- (id)initWithStretchableFile:(NSString *)fileName leftCap:(NSInteger)leftCap width:(float)width;

@end
