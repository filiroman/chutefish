//
//  CBStorageManager.m
//  chute balls
//
//  Created by Roman Filippov on 02.03.14.
//  Copyright (c) 2014 Roman Filippov. All rights reserved.
//

#import "CBStorageManager.h"

static CBStorageManager *storageManager = nil;

@implementation CBStorageManager

+ (CBStorageManager*) sharedManager
{
    if (storageManager == nil)
        storageManager = [[CBStorageManager alloc] init];
    
    return storageManager;
}

@end
