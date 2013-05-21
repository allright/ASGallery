//
//  TGCache.m
//
//  Created by Andrey Syvrachev on 12.11.12. andreyalright@gmail.com
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

#import "ASCache.h"


@interface CacheProxy : NSObject

@property (nonatomic,strong) id obj;
@property (nonatomic,strong) id key;


@end
@implementation CacheProxy
@end


@interface ASCache (){
}

@property (nonatomic,strong) NSMutableOrderedSet* orderedSet;
@property (nonatomic,strong) NSMutableDictionary* dic;

@end

@implementation ASCache

-(NSMutableOrderedSet*)orderedSet
{
    if (_orderedSet == nil)
        _orderedSet = [NSMutableOrderedSet orderedSet];
    return _orderedSet;
}

-(NSMutableDictionary*)dic
{
    if (_dic == nil)
        _dic = [NSMutableDictionary dictionary];
    return _dic;
}

-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    @synchronized(self){
    
        CacheProxy* cp  = [[CacheProxy alloc] init];
        cp.key          = aKey;
        cp.obj          = anObject;
        [self.orderedSet insertObject:cp atIndex:0];
        [self.dic setObject:cp forKey:aKey];
        
        assert(self.maxCachedObjectsCount > 0);
        
        while ([self.orderedSet count] > self.maxCachedObjectsCount) {
            CacheProxy* cp = [self.orderedSet lastObject];
            assert(cp);
            [self.dic removeObjectForKey:cp.key];
            [self.orderedSet removeObjectAtIndex:[self.orderedSet count]-1];
        }
    }
    
}

-(id)objectForKey:(id)aKey
{
    @synchronized(self){
        CacheProxy* cp = [self.dic objectForKey:aKey];
        return cp.obj;
    }
}

-(void)removeAllObjects
{
    @synchronized(self){
        _dic = nil;
        _orderedSet = nil;
    }
}

@end
