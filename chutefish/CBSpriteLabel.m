//
//  CBSpriteLabel.m
//  chute balls
//
//  Created by Roman Filippov on 09.10.14.
//  Copyright 2014 Roman Filippov. All rights reserved.
//

#import "CBSpriteLabel.h"


@implementation CBSpriteLabel

- (id) initWithFile:(NSString *)filename labelText:(NSString*)labelText fontName:(NSString*) fontName fontSize:(CGFloat)fontSize
{
    if (self = [super initWithFile:filename])
    {
        self.spriteLabel = [CCLabelTTF labelWithString:labelText fontName:fontName fontSize:fontSize];
        self.spriteLabel.position = ccp(self.boundingBox.size.width/2, self.boundingBox.size.height/2+2);
        [self addChild:_spriteLabel];
    }
    return self;
}

- (id) initWithFile:(NSString *)filename labelText:(NSString*)labelText
{
    if (self = [super initWithFile:filename])
    {
        self.spriteLabel = [CCLabelTTF labelWithString:labelText fontName:@"Marker Felt" fontSize:22.0f];
        self.spriteLabel.position = ccp(self.boundingBox.size.width/2, self.boundingBox.size.height/2);
        [self addChild:_spriteLabel];
    }
    return self;
}

+ (id) spriteWithFile:(NSString *)filename labelText:(NSString*)labelText fontName:(NSString*) fontName fontSize:(CGFloat)fontSize
{
    return [[[self alloc] initWithFile:filename labelText:labelText fontName:fontName fontSize:fontSize] autorelease];
}

+ (id) spriteWithFile:(NSString *)filename labelText:(NSString*)labelText
{
    return [[[self alloc] initWithFile:filename labelText:labelText] autorelease];
}

- (void) dealloc
{
    self.spriteLabel = nil;
    
    [super dealloc];
}

@end
