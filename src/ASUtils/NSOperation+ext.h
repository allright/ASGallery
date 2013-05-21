//
//  NSOperation+ext.h
//  TimeGallery
//
//  Created by Andrey Syvrachev on 22.10.12.
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^NSOperationCompletionBlock)(NSOperation* operation);


@interface NSOperationCompletion : NSObject

@property(nonatomic,strong)  NSThread* thread;
@property(nonatomic,copy)   NSOperationCompletionBlock block;
@property(nonatomic,assign) SEL selector;
@property(nonatomic,weak)   id target;

+(NSOperationCompletion*)completionWithBlock:(NSOperationCompletionBlock)block onThread:(NSThread*)thread;
+(NSOperationCompletion*)completionWithTarget:(id)target selector:(SEL)selector onThread:(NSThread*)thread;

@end


@interface NSOperation (ext)

-(void)addCompletion:(NSOperationCompletion*)block;
-(void)callCompletionBlock:(NSOperationCompletion*)cb;

@end
