//
//  ASImageScrollView.h
//  TimeGallery
//
//  Created by Andrey Syvrachev on 07.11.12.
//  Copyright (c) 2012 Andrey Syvrachev. All rights reserved.
//

#import <UIKit/UIKit.h>

// ведает загрузкой ассета до FullScreen
@protocol ASImageScrollViewDelegate <NSObject>

-(void)imageViewDidEndZoomingAtScale:(CGFloat)scale;


@end

@interface ASImageScrollView : UIScrollView

@property(nonatomic,weak) id<ASImageScrollViewDelegate> zoomDelegate;
@property (nonatomic,strong) UIImage* image;
@property (nonatomic,assign) BOOL isVideo;
@property (nonatomic,strong,readonly) UIImageView   *imageView;


-(void)prepareForReuse;
-(void)setMaxMinZoomScalesForCurrentBounds;
-(void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale;
-(CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;
-(CGFloat)scaleToRestoreAfterRotation;
-(CGPoint)pointToCenterAfterRotation;
-(void)resetToDefaults;

-(void)restoreDefaultZoomScaleWithCompletionBlock:(dispatch_block_t)block;

@end
