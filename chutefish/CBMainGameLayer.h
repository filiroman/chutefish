//
//  HelloWorldLayer.h
//  chute balls
//
//  Created by Roman Filippov on 14.02.14.
//  Copyright Roman Filippov 2014. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

#import "GADBannerViewDelegate.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32


// defines number of points for each static body drawn in touch
#define POINT_COUNT 15

// HelloWorldLayer
@interface CBMainGameLayer : CCLayer <GADBannerViewDelegate>

@property (nonatomic, assign) BOOL isHelpScene;


// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
