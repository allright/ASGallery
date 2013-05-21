//
//  GalleryAsset.h
//  Photos
//
//  Created by Andrey Syvrachev on 21.05.13.
//  Copyright (c) 2013 Andrey Syvrachev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASGalleryViewController.h"

@interface GalleryAsset : NSObject<ASGalleryAsset>

@property(nonatomic,strong) ALAsset* asset;

@end
