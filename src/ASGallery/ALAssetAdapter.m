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


@interface ALAssetAdapter (){
    NSString* type;
    NSURL* _url;
    NSNumber* _duration;
}

@end


@implementation ALAssetAdapter

-(CGFloat)duration
{
    if (_duration == nil){
        _duration = [self.asset valueForProperty:ALAssetPropertyDuration];
    }
    return [_duration floatValue];
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

-(BOOL)isImageForTypeAvailable:(ASGalleryImageType)imageType
{
    if ([self.asset respondsToSelector:@selector(aspectRatioThumbnail)])
        return YES;
    return imageType != ASGalleryImagePreview;
}

-(UIImage*)imageForType:(ASGalleryImageType)imageType
{
    switch (imageType) {
        case ASGalleryImageThumbnail:
            return [UIImage imageWithCGImage:[self.asset thumbnail]];
            
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

@end
