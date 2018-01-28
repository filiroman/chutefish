//
//  CCSprite+Stretchable.m
//  chute balls
//
//  Created by Roman Filippov on 26.02.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CCSprite+Stretchable.h"
#import "CCTextureCache.h"

@implementation CCSprite (Stretchable)

+ (CCSprite *)spriteFromStretchableFile:(NSString *)fileName leftCap:(NSInteger)leftCap width:(float)width {
    return [[[self alloc] initWithStretchableFile:fileName leftCap:(NSInteger)leftCap width:width] autorelease];
}

-(id)initWithStretchableFile:(NSString *)fileName leftCap:(NSInteger)leftCap width:(float)width {
    NSAssert(fileName!=nil, @"Invalid filename for sprite");
    
    UIImage *image = [[UIImage imageNamed:fileName] stretchableImageWithLeftCapWidth:leftCap topCapHeight:0];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, image.size.height),NO,0.0);
    [image drawInRect:CGRectMake(0, 0, width, image.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addCGImage:newImage.CGImage forKey:[NSString stringWithFormat:@"%@%f",fileName,width]];
    if( texture ) {
      CGRect rect = CGRectZero;
      rect.size = texture.contentSize;
      return [self initWithTexture:texture rect:rect];
    }

    [self release];
    return nil;
    }

@end