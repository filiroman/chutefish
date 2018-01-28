//
//  CBGameCenterHelper.h
//  chute balls
//
//  Created by Roman Filippov on 31.03.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface CBGameCenterHelper : NSObject {
    BOOL gameCenterAvailable;
    BOOL userAuthenticated;
}

@property (assign, readonly) BOOL gameCenterAvailable;

+ (CBGameCenterHelper *)sharedInstance;
- (void)authenticateLocalUser;

@end
