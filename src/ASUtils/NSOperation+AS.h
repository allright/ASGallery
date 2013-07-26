//
//  NSOperation+ext.h
//
//  Created by Andrey Syvrachev on 22.10.12. andreyalright@gmail.com
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

typedef void (^NSOperationCompletionBlock)(NSOperation* operation);

/**@class NSOperationCompletion perform operation in Background thread, and call completion block on Caller thread. */
@interface NSOperationCompletion : NSObject

@property(nonatomic,strong)  NSThread* thread;
@property(nonatomic,copy)   NSOperationCompletionBlock block;
@property(nonatomic,assign) SEL selector;
@property(nonatomic,unsafe_unretained)   id target;

+(NSOperationCompletion*)completionWithBlock:(NSOperationCompletionBlock)block onThread:(NSThread*)thread;
+(NSOperationCompletion*)completionWithTarget:(id)target selector:(SEL)selector onThread:(NSThread*)thread;

@end


@interface NSOperation (AS)

-(void)addCompletion:(NSOperationCompletion*)block;
-(void)callCompletionBlock:(NSOperationCompletion*)cb;

@end
