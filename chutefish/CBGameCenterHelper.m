//
//  CBGameCenterHelper.m
//  chute balls
//
//  Created by Roman Filippov on 31.03.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CBGameCenterHelper.h"
#import "AppDelegate.h"

@implementation CBGameCenterHelper

@synthesize gameCenterAvailable;

- (id)init {
    if ((self = [super init])) {
        gameCenterAvailable = [self isGameCenterAvailable];
        if (gameCenterAvailable) {
            NSNotificationCenter *nc =
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
        }
    }
    return self;
}

- (void) authenticateLocalUser
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil)
        {
            AppController *delegate = [UIApplication sharedApplication].delegate;
            [delegate presentViewControllerFromVisibleViewController:viewController];
            
        }
        else if (localPlayer.isAuthenticated)
        {
            //authenticatedPlayer: is an example method name. Create your own method that is called after the loacal player is authenticated.
            [self authenticatedPlayer: localPlayer];
        }
        else
        {
            [self disableGameCenter];
        }
    };
}

-(void)authenticatedPlayer:(GKLocalPlayer*)localPlayer
{
    [[NSNotificationCenter defaultCenter]postNotificationName:@"cbPlayerDidAuthenticated" object:nil];
    [[GKLocalPlayer localPlayer]registerListener:(id)self];
    NSLog(@"Local player:%@ authenticated into game center",localPlayer.playerID);
}

-(void)disableGameCenter
{
    //A notification so that every observer responds appropriately to disable game center features
    [[NSNotificationCenter defaultCenter]postNotificationName:@"cbPlayerDidUnauthenticated" object:nil];
    NSLog(@"Disabled game center");
}

/*- (void)authenticateLocalUser {
    
    if (!gameCenterAvailable) return;
    
    NSLog(@"Authenticating local user...");
    if ([GKLocalPlayer localPlayer].authenticated == NO) {
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error) {
            if (error != nil)
            {
                NSLog(@"%@",[error description]);
            }
        }];
    } else {
        NSLog(@"Already authenticated!");
    }
}*/

- (void)authenticationChanged {
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && !userAuthenticated) {
        NSLog(@"Authentication changed: player authenticated.");
        userAuthenticated = YES;
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && userAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        userAuthenticated = NO;
    }
    
}

static CBGameCenterHelper *sharedHelper = nil;
+ (CBGameCenterHelper *) sharedInstance {
    if (!sharedHelper) {
        sharedHelper = [[CBGameCenterHelper alloc] init];
    }
    return sharedHelper;
}

- (BOOL)isGameCenterAvailable {
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}


@end
