//
//  CBSpriteLabel.h
//  chute balls
//
//  Created by Roman Filippov on 09.10.14.
//  Copyright 2014 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CBSpriteLabel : CCSprite {
    
}

@property (retain, nonatomic) CCLabelTTF *spriteLabel;

+ (id) spriteWithFile:(NSString *)filename labelText:(NSString*)labelText fontName:(NSString*) fontName fontSize:(CGFloat)fontSize;
+ (id) spriteWithFile:(NSString *)filename labelText:(NSString*)labelText;

- (id) initWithFile:(NSString *)filename labelText:(NSString*)labelText fontName:(NSString*) fontName fontSize:(CGFloat)fontSize;
- (id) initWithFile:(NSString *)filename labelText:(NSString*)labelText;

@end
