//
//  ASGalleryAsset.h
//  Photos
//
//  Created by Andrey Syvrachev on 25.07.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASGalleryViewController.h"


@interface ASGalleryAssetBase : NSObject<ASGalleryAsset>

-(UIImage*)imageForType:(ASGalleryImageType)imageType;
-(CGFloat)duration;

@end
