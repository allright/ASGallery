//
//  TGLoadImageOperation.m
//  TimeGallery
//
//  Created by Andrey Syvrachev on 29.10.12.
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//

#import "ASLoadImageBackgroundOperation.h"
#import "NSOperation+ext.h"

@interface ASLoadImageBackgroundOperation (){
    UIImage* image;
}

@end

@implementation ASLoadImageBackgroundOperation


-(id)init
{
    self = [super init];
    if (self)
    {
        [self addCompletion:[NSOperationCompletion completionWithTarget:self selector:@selector(completeLoadImage) onThread:[NSThread currentThread]]];
    }
    return self;
}

-(void)main
{
    if ([self isCancelled])
        return;
    
    @synchronized(self){
        if (self.imageFetchBlock)
            image = self.imageFetchBlock();
    }
}

-(void)completeLoadImage
{
    if ([self isCancelled])
        return;
    
    @synchronized(self){
        if (self.imageSetBlock)
            self.imageSetBlock(image);
    }
}

-(void)cancel
{
    @synchronized(self){
        self.imageSetBlock = nil;
        self.imageFetchBlock = nil;
    }
    [super cancel];
}

@end
