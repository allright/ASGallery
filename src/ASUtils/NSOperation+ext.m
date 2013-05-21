//
//  NSOperation+ext.m
//  TimeGallery
//
//  Created by Andrey Syvrachev on 22.10.12.
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//

#import "NSOperation+ext.h"
#import <objc/runtime.h>



@implementation NSOperationCompletion

+(NSOperationCompletion*)completionWithBlock:(NSOperationCompletionBlock)block onThread:(NSThread*)thread
{
    NSOperationCompletion* cb = [[NSOperationCompletion alloc] init];
    cb.block = block;
    cb.thread = thread;
    return cb;
}

+(NSOperationCompletion*)completionWithTarget:(id)target selector:(SEL)selector onThread:(NSThread*)thread
{
    NSOperationCompletion* cb = [[NSOperationCompletion alloc] init];
    cb.target = target;
    cb.selector = selector;
    cb.thread = thread;
    return cb;
}


@end

static char completionBlocksArrayKey;

@implementation NSOperation (ext)

-(void)callCompletionBlock:(NSOperationCompletion*)cb
{
    if (cb)
        cb.block(self);
}

-(void)addCompletion:(NSOperationCompletion*)block
{
    NSMutableArray* completionBlocks = objc_getAssociatedObject(self,&completionBlocksArrayKey);
    if (completionBlocks == nil)
    {
        completionBlocks = [NSMutableArray array];
        objc_setAssociatedObject(self, &completionBlocksArrayKey, completionBlocks, OBJC_ASSOCIATION_RETAIN);
    }
    [completionBlocks addObject:block];
    
    if (!self.completionBlock)
    {
        // set real completion block to self
        __weak NSOperation* SELF = self;
        
        self.completionBlock = ^{
            
            @synchronized(SELF){
                for (NSOperationCompletion* cb in completionBlocks) {
                    
                    if (cb.target)
                        [cb.target performSelector:cb.selector onThread:cb.thread withObject:SELF waitUntilDone:NO];
                    
                    if (cb.block)
                        [SELF performSelector:@selector(callCompletionBlock:) onThread:cb.thread withObject:cb waitUntilDone:NO];
                }
            }
            
        };
    }
}

@end
