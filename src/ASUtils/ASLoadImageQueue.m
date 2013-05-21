//
//  TGLoadImageQueue.m
//  TimeGallery
//
//  Created by Andrey Syvrachev on 29.10.12.
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//

#import "ASLoadImageQueue.h"
#include <sys/sysctl.h>

@implementation ASLoadImageQueue

unsigned int countCores()
{
    size_t len;
    unsigned int ncpu;
    
    len = sizeof(ncpu);
    sysctlbyname ("hw.ncpu",&ncpu,&len,NULL,0);
    
    return ncpu;
}

+(ASLoadImageQueue*)instance
{
    static ASLoadImageQueue* queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[ASLoadImageQueue alloc] init];
        queue.maxConcurrentOperationCount = countCores();
    });
    return queue;
}

@end
