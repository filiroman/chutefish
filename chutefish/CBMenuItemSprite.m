//
//  CBMenuItemSprite.m
//  chute balls
//
//  Created by Roman Filippov on 26.02.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CBMenuItemSprite.h"
#import "CCLabelTTF.h"
#import "cocos2d.h"
#import "CCSprite+Stretchable.h"
#import "CCSpriteScale9.h"

@implementation CBMenuItemSprite


+(id) itemWithString: (NSString*) value image: (NSString*) image leftCapWidth:(CGFloat) width block:(void(^)(id sender))block;
{
    NSString *founded = [[CCFileUtils sharedFileUtils] fullPathForFilename:image];
    NSString *filename = [founded substringFromIndex:[founded rangeOfString:@"/" options:NSBackwardsSearch].location + 1];
    
    int fontSize = 32;
    int leftCapMulti = width;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        fontSize *= 2;
        
        leftCapMulti *= 2;
    }
    
    CCLabelTTF* iconLabel = [CCLabelTTF labelWithString:value fontName:@"Marker Felt" fontSize:fontSize];
    
    CCSpriteScale9 *spr = [CCSpriteScale9 spriteWithFile:filename andLeftCapWidth:leftCapMulti andTopCapHeight:0];
    [spr adaptiveScale9:CGSizeMake(iconLabel.contentSize.width * 1.5, iconLabel.contentSize.height * 1.725)];
    CBMenuItemSprite *menu = [CBMenuItemSprite itemWithNormalSprite:spr selectedSprite:nil block:block];
    //[CCMenuItemImage itemWithNormalImage:image selectedImage:image block:block];
    //[CCLabelTTF labelWithString:value fontName:@"Marker Felt" fontSize:32 dimensions:menu.boundingBox.size hAlignment:kCCTextAlignmentCenter vAlignment:kCCVerticalTextAlignmentTop];
    
    menu.anchorPoint = ccp(0.5f, 0.5f);
    //[CCLabel labelWithString:lbl dimensions:CGSizeMake(120,40) alignment:UITextAlignmentCenter fontName:@"Existence-Light" fontSize:32];
    iconLabel.color = ccc3(255,255,255);
    iconLabel.anchorPoint = ccp(0.5f, 0.5f);
    iconLabel.position = ccp(menu.contentSize.width/2, menu.contentSize.height/2);
    iconLabel.tag = 1;
    [menu addChild:iconLabel];
    
    return menu;
}

@end
