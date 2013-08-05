//
//  ASGalleryAsset.m
//  Photos
//
//  Created by Andrey Syvrachev on 25.07.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import "ASGalleryAssetBase.h"
#import "ASLoadImageBackgroundOperation.h"
#import "ASLoadImageQueue.h"
#import "ASCache.h"

@implementation ASGalleryAssetBase

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
        cache.maxCachedObjectsCount = 128;
    });
    return cache;
}

-(NSString*)generateCacheKey:(ASGalleryImageType)imageType
{
    // warning never use here self.url -> too long suspend main thread!!!
    return  [NSString stringWithFormat:@"%u:%u",[self hash],imageType];
}

-(ASCache*)cacheForType:(ASGalleryImageType)imageType
{
    switch (imageType) {
        default:
        case ASGalleryImagePreview:
            return [[self class] previewImageCache];
            
        case ASGalleryImageFullScreen:
            return [[self class] fullScreenImageCache];
    }
}

-(void)setImageCache:(UIImage*)image forType:(ASGalleryImageType)imageType
{
    NSString* key = [self generateCacheKey:imageType];
    [[self cacheForType:imageType] setObject:image forKey:key];
}

-(UIImage*)cachedImageForType:(ASGalleryImageType)imageType
{
    NSString* key = [self generateCacheKey:imageType];
    return [[self cacheForType:imageType] objectForKey:key];
}

-(CGFloat)duration
{
    assert(!"override me");
    return 0;
}

-(UIImage*)imageForType:(ASGalleryImageType)imageType
{
    assert(!"override me");
    return nil;
}

-(NSURL*)url
{
    assert(!"override me");
    return nil;
}

-(BOOL)isVideo
{
    assert(!"override me");
    return NO;
}

-(BOOL)isImageForTypeAvailable:(ASGalleryImageType)imageType
{
    return YES;
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
    __unsafe_unretained ASGalleryAssetBase* SELF = self;
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
