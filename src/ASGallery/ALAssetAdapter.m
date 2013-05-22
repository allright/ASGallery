//
//  ALAssetAdapter.m
//
//  Created by Andrey Syvrachev on 21.05.13. andreyalright@gmail.com
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
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

#import "ALAssetAdapter.h"
#import "ASLoadImageBackgroundOperation.h"
#import "ASLoadImageQueue.h"
#import "ASCache.h"

@interface ALAssetAdapter (){
    NSString* type;
    NSURL* _url;
}


@end

@implementation ALAssetAdapter

+(ASCache*)fullScreenImageCache
{
    static ASCache* cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[ASCache alloc] init];
        cache.maxCachedObjectsCount = 5;
    });
    return cache;
}

+(ASCache*)previewImageCache
{
    static ASCache* cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[ASCache alloc] init];
        cache.maxCachedObjectsCount = 512;
    });
    return cache;
}

-(BOOL)isVideo
{
    if (type == nil)
        type = [self.asset valueForProperty:ALAssetPropertyType];
    return type == ALAssetTypeVideo;
}

-(NSURL*)url
{
    if (_url == nil)
        _url = [[_asset defaultRepresentation] url];
    return _url;
}

-(UIImage*)imageForType:(ASGalleryImageType)imageType
{
    switch (imageType) {
        case ASGalleryImagePreview:
            return [UIImage imageWithCGImage:[self.asset aspectRatioThumbnail]];
            
        case ASGalleryImageFullScreen:
            return [UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]];
            

        case ASGalleryImageFullResolution:
        {
            ALAssetRepresentation* defaultRepresentation = [self.asset defaultRepresentation];
            return [UIImage imageWithCGImage:[defaultRepresentation fullResolutionImage]
                                       scale:defaultRepresentation.scale
                                 orientation:(UIImageOrientation)defaultRepresentation.orientation];
        }
        default:
            return nil;
    }
}

-(NSString*)generateCacheKey:(ASGalleryImageType)imageType
{
    // warning never use here self.url -> too long suspend main thread!!!
    return  [NSString stringWithFormat:@"%u:%u",[self hash],imageType];
}

-(void)setImageCache:(UIImage*)image forType:(ASGalleryImageType)imageType
{
    // warning never use here self.url -> too long suspend main thread!!!
    NSString* key = [self generateCacheKey:imageType];

    switch (imageType) {
        case ASGalleryImagePreview:
            [[[self class] previewImageCache] setObject:image forKey:key];
            break;
            
        case ASGalleryImageFullScreen:
            [[[self class] fullScreenImageCache] setObject:image forKey:key];
            break;
            
        default:
            break;
    }
}

-(UIImage*)cachedImageForType:(ASGalleryImageType)imageType
{
    NSString* key = [self generateCacheKey:imageType];
    
    switch (imageType) {

        case ASGalleryImagePreview:
            return [[[self class] previewImageCache] objectForKey:key];
            
        case ASGalleryImageFullScreen:
            return  [[[self class] fullScreenImageCache] objectForKey:key];
            
        default:
            break;
    }
    return nil;
}

-(NSOperation*)loadImage:(id<ASGalleryImageView>)galleryImageView withImageType:(ASGalleryImageType)imageType
{
    UIImage* image = [self cachedImageForType:imageType];
    if (image){
        [galleryImageView setImage:image];
        return nil;
    }
    
    ASLoadImageBackgroundOperation* loadImageOperation = [[ASLoadImageBackgroundOperation alloc] init];
    loadImageOperation.queuePriority = NSOperationQueuePriorityVeryLow;
    __weak ALAssetAdapter* SELF = self;
    loadImageOperation.imageFetchBlock = ^UIImage*(void){
        
        UIImage* image = [SELF imageForType:imageType];
        if (image) {
            [SELF setImageCache:image forType:imageType];
        }
        return image;
    };
    
    loadImageOperation.imageSetBlock = ^(UIImage* image){
        [galleryImageView setImage:image];
    };
    
    [[ASLoadImageQueue sharedInstance] addOperation:loadImageOperation];
    return loadImageOperation;
}

@end
