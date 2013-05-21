//
//  GalleryAsset.m
//  Photos
//
//  Created by Andrey Syvrachev on 21.05.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import "GalleryAsset.h"

@interface GalleryAsset (){
    NSString* type;
    NSURL* _url;
}


@end

@implementation GalleryAsset


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

-(NSOperation*)loadImage:(id<ASGalleryImageView>)galleryImageView withImageType:(ASGalleryImageType)imageType
{
    switch (imageType) {
        case ASGalleryImagePreview:
            [galleryImageView setImage:[UIImage imageWithCGImage:[self.asset aspectRatioThumbnail]]];
            break;
            
        case ASGalleryImageFullScreen:
            [galleryImageView setImage:[UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]]];
            break;
            
        case ASGalleryImageFullResolution:
            [galleryImageView setImage:[UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullResolutionImage]]];
            break;
            
        default:
            break;
    }
    
    
    
    
    
    return nil;
}


@end
