//
//  TGLoadImageOperation.h
//  TimeGallery
//
//  Created by Andrey Syvrachev on 29.10.12.
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//

#import <Foundation/Foundation.h>


//typedef enum {
//    TGImageTypeThumbnail,
//    TGImageTypeAspectRatioThumbnail,
//    TGImageTypeFullScreen,
//    TGImageTypeFullResolution
//}TGImageType;

typedef void (^TGImageSetBlock)(UIImage* image);
typedef UIImage* (^TGImageFetchBlock)();


@interface ASLoadImageBackgroundOperation : NSOperation

@property (nonatomic,copy) TGImageFetchBlock imageFetchBlock;
@property (nonatomic,copy) TGImageSetBlock imageSetBlock;


@end
